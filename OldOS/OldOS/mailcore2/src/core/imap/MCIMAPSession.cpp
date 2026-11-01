#include "MCWin32.h" // Should be included first.

#include "MCIMAPSession.h"

#include <libetpan/libetpan.h>
#include <string.h>
#include <stdlib.h>

#include "MCDefines.h"
#include "MCIMAPSearchExpression.h"
#include "MCIMAPFolder.h"
#include "MCIMAPMessage.h"
#include "MCIMAPPart.h"
#include "MCMessageHeader.h"
#include "MCAbstractPart.h"
#include "MCIMAPProgressCallback.h"
#include "MCIMAPNamespace.h"
#include "MCIMAPSyncResult.h"
#include "MCIMAPFolderStatus.h"
#include "MCConnectionLogger.h"
#include "MCConnectionLoggerUtils.h"
#include "MCHTMLRenderer.h"
#include "MCString.h"
#include "MCUtils.h"
#include "MCHTMLRendererIMAPDataCallback.h"
#include "MCHTMLBodyRendererTemplateCallback.h"
#include "MCCertificateUtils.h"
#include "MCIMAPIdentity.h"
#include "MCLibetpan.h"
#include "MCDataStreamDecoder.h"

using namespace mailcore;

class LoadByChunkProgress : public Object, public IMAPProgressCallback {
public:
    LoadByChunkProgress();
    virtual ~LoadByChunkProgress();

    virtual void setOffset(uint32_t offset);
    virtual void setEstimatedSize(uint32_t estimatedSize);
    virtual void setProgressCallback(IMAPProgressCallback * progressCallback);

    virtual void bodyProgress(IMAPSession * session, unsigned int current, unsigned int maximum);

private:
    uint32_t mOffset;
    uint32_t mEstimatedSize;
    IMAPProgressCallback * mProgressCallback; // non retained
};

LoadByChunkProgress::LoadByChunkProgress()
{
    mOffset = 0;
    mEstimatedSize = 0;
    mProgressCallback = NULL;
}

LoadByChunkProgress::~LoadByChunkProgress()
{
}

void LoadByChunkProgress::setOffset(uint32_t offset)
{
    mOffset = offset;
}

void LoadByChunkProgress::setEstimatedSize(uint32_t estimatedSize)
{
    mEstimatedSize = estimatedSize;
}

void LoadByChunkProgress::setProgressCallback(IMAPProgressCallback * progressCallback)
{
    mProgressCallback = progressCallback;
}

void LoadByChunkProgress::bodyProgress(IMAPSession * session, unsigned int current, unsigned int maximum)
{
    // In case of loading attachment by chunks we need report overall progress
    if (mEstimatedSize > 0 && mEstimatedSize > maximum) {
        maximum = mEstimatedSize;
        current += mOffset;
    }
    mProgressCallback->bodyProgress(session, current, maximum);
}

enum {
    STATE_DISCONNECTED,
    STATE_CONNECTED,
    STATE_LOGGEDIN,
    STATE_SELECTED,
};

String * mailcore::IMAPNamespacePersonal = NULL;
String * mailcore::IMAPNamespaceOther = NULL;
String * mailcore::IMAPNamespaceShared = NULL;

static Array * resultsWithError(int r, clist * list, ErrorCode * pError);

INITIALIZE(IMAPSEssion)
{
    AutoreleasePool * pool = new AutoreleasePool();
    IMAPNamespacePersonal = (String *) MCSTR("IMAPNamespacePersonal")->retain();
    IMAPNamespaceOther = (String *) MCSTR("IMAPNamespaceOther")->retain();
    IMAPNamespaceShared = (String *) MCSTR("IMAPNamespaceShared")->retain();
    
    pool->release();
}

#define MAX_IDLE_DELAY (28 * 60)

#define LOCK() pthread_mutex_lock(&mIdleLock)
#define UNLOCK() pthread_mutex_unlock(&mIdleLock)

static struct mailimap_flag_list * flags_to_lep(MessageFlag value)
{
    struct mailimap_flag_list * flag_list;
    
    flag_list = mailimap_flag_list_new_empty();
    
    if ((value & MessageFlagSeen) != 0) {
        mailimap_flag_list_add(flag_list, mailimap_flag_new_seen());
    }
    
    if ((value & MessageFlagFlagged) != 0) {
        mailimap_flag_list_add(flag_list, mailimap_flag_new_flagged());
    }
    
    if ((value & MessageFlagDeleted) != 0) {
        mailimap_flag_list_add(flag_list, mailimap_flag_new_deleted());
    }
    
    if ((value & MessageFlagAnswered) != 0) {
        mailimap_flag_list_add(flag_list, mailimap_flag_new_answered());
    }
    
    if ((value & MessageFlagDraft) != 0) {
        mailimap_flag_list_add(flag_list, mailimap_flag_new_draft());
    }
    
    if ((value & MessageFlagForwarded) != 0) {
        mailimap_flag_list_add(flag_list, mailimap_flag_new_flag_keyword(strdup("$Forwarded")));
    }
    
    if ((value & MessageFlagMDNSent) != 0) {
        mailimap_flag_list_add(flag_list, mailimap_flag_new_flag_keyword(strdup("$MDNSent")));
    }
    
    if ((value & MessageFlagSubmitPending) != 0) {
        mailimap_flag_list_add(flag_list, mailimap_flag_new_flag_keyword(strdup("$SubmitPending")));
    }
    
    if ((value & MessageFlagSubmitted) != 0) {
        mailimap_flag_list_add(flag_list, mailimap_flag_new_flag_keyword(strdup("$Submitted")));
    }
    
    return flag_list;
}

static MessageFlag flag_from_lep(struct mailimap_flag * flag)
{
    switch (flag->fl_type) {
        case MAILIMAP_FLAG_ANSWERED:
            return MessageFlagAnswered;
        case MAILIMAP_FLAG_FLAGGED:
            return MessageFlagFlagged;
        case MAILIMAP_FLAG_DELETED:
            return MessageFlagDeleted;
        case MAILIMAP_FLAG_SEEN:
            return MessageFlagSeen;
        case MAILIMAP_FLAG_DRAFT:
            return MessageFlagDraft;
        case MAILIMAP_FLAG_KEYWORD:
            if (strcasecmp(flag->fl_data.fl_keyword, "$Forwarded") == 0) {
                return MessageFlagForwarded;
            }
            else if (strcasecmp(flag->fl_data.fl_keyword, "$MDNSent") == 0) {
                return MessageFlagMDNSent;
            }
            else if (strcasecmp(flag->fl_data.fl_keyword, "$SubmitPending") == 0) {
                return MessageFlagSubmitPending;
            }
            else if (strcasecmp(flag->fl_data.fl_keyword, "$Submitted") == 0) {
                return MessageFlagSubmitted;
            }
    }
    
    return MessageFlagNone;
}

static MessageFlag flags_from_lep_att_dynamic(struct mailimap_msg_att_dynamic * att_dynamic)
{
    if (att_dynamic->att_list == NULL)
        return MessageFlagNone;
    
    MessageFlag flags;
    clistiter * iter;
    
    flags = MessageFlagNone;
    for(iter = clist_begin(att_dynamic->att_list) ;iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_flag_fetch * flag_fetch;
        struct mailimap_flag * flag;
        
        flag_fetch = (struct mailimap_flag_fetch *) clist_content(iter);
        if (flag_fetch->fl_type != MAILIMAP_FLAG_FETCH_OTHER) {
            continue;
        }
        
        flag = flag_fetch->fl_flag;
        flags = (MessageFlag) (flags | flag_from_lep(flag));
    }
    
    return flags;
}

static bool isKnownCustomFlag(const char * keyword)
{
    return !(strcmp(keyword, "$MDNSent") != 0 && strcmp(keyword, "$Forwarded") != 0 && strcmp(keyword, "$SubmitPending") != 0 && strcmp(keyword, "$Submitted") != 0);
}

static Array * custom_flags_from_lep_att_dynamic(struct mailimap_msg_att_dynamic * att_dynamic)
{
    if (att_dynamic->att_list == NULL)
        return NULL;
    
    clistiter * iter;
    bool hasCustomFlags = false;
    
    for (iter = clist_begin(att_dynamic->att_list); iter != NULL; iter = clist_next(iter)) {
        struct mailimap_flag_fetch * flag_fetch;
        struct mailimap_flag * flag;
        
        flag_fetch = (struct mailimap_flag_fetch *) clist_content(iter);
        if (flag_fetch->fl_type != MAILIMAP_FLAG_FETCH_OTHER) {
            continue;
        }
        
        flag = flag_fetch->fl_flag;
        if (flag->fl_type == MAILIMAP_FLAG_KEYWORD) {
            if (!isKnownCustomFlag(flag->fl_data.fl_keyword)) {
                hasCustomFlags = true;
            }
        }
    }
    
    if (!hasCustomFlags)
        return NULL;
    
    Array * result = Array::array();
    for (iter = clist_begin(att_dynamic->att_list); iter != NULL; iter = clist_next(iter)) {
        struct mailimap_flag_fetch * flag_fetch;
        struct mailimap_flag * flag;
        
        flag_fetch = (struct mailimap_flag_fetch *) clist_content(iter);
        if (flag_fetch->fl_type != MAILIMAP_FLAG_FETCH_OTHER) {
            continue;
        }
        
        flag = flag_fetch->fl_flag;
        if (flag->fl_type == MAILIMAP_FLAG_KEYWORD) {
            if (!isKnownCustomFlag(flag->fl_data.fl_keyword)) {
                String * customFlag;
                customFlag = String::stringWithUTF8Characters(flag->fl_data.fl_keyword);
                result->addObject(customFlag);
            }
        }
    }
    
    return result;
}

#pragma mark set conversion

static Array * arrayFromSet(struct mailimap_set * imap_set)
{
    Array * result;
    clistiter * iter;
    
    result = Array::array();
    for(iter = clist_begin(imap_set->set_list) ; iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_set_item * item;
        unsigned long i;
        
        item = (struct mailimap_set_item *) clist_content(iter);
        for(i = item->set_first ; i <= item->set_last ; i ++) {
            Value * nb;
            
            nb = Value::valueWithUnsignedLongValue(i);
            result->addObject(nb);
        }
    }
    
    return result;
}

static clist * splitSet(struct mailimap_set * set, unsigned int splitCount)
{
    struct mailimap_set * current_set;
    clist * result;
    unsigned int count;
    
    result = clist_new();
    
    current_set = NULL;
    count = 0;
    for(clistiter * iter = clist_begin(set->set_list) ; iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_set_item * item;
        
        if (current_set == NULL) {
            current_set = mailimap_set_new_empty();
        }
        
        item = (struct mailimap_set_item *) clist_content(iter);
        mailimap_set_add_interval(current_set, item->set_first, item->set_last);
        count ++;
        
        if (count >= splitCount) {
            clist_append(result, current_set);
            current_set = NULL;
            count = 0;
        }
    }
    if (current_set != NULL) {
        clist_append(result, current_set);
    }
    
    return result;
}

static struct mailimap_set * setFromIndexSet(IndexSet * indexSet)
{
    struct mailimap_set * imap_set;
    
    imap_set = mailimap_set_new_empty();
    for(unsigned int i = 0 ; i < indexSet->rangesCount() ; i ++) {
        uint64_t left = RangeLeftBound(indexSet->allRanges()[i]);
        uint64_t right = RangeRightBound(indexSet->allRanges()[i]);
        if (right == UINT64_MAX) {
            right = 0;
        }
        mailimap_set_add_interval(imap_set, (uint32_t) left, (uint32_t) right);
    }
    
    return imap_set;
}

static IndexSet * indexSetFromSet(struct mailimap_set * imap_set)
{
    IndexSet * indexSet = IndexSet::indexSet();
    for(clistiter * cur = clist_begin(imap_set->set_list) ; cur != NULL ; cur = clist_next(cur)) {
        struct mailimap_set_item * item = (struct mailimap_set_item *) clist_content(cur);
        if (item->set_last == 0) {
            indexSet->addRange(RangeMake(item->set_first, UINT64_MAX));
        }
        else {
            indexSet->addRange(RangeMake(item->set_first, item->set_last - item->set_first));
        }
    }
    return indexSet;
}

void IMAPSession::init()
{
    mHostname = NULL;
    mPort = 0;
    mUsername = NULL;
    mPassword = NULL;
    mOAuth2Token = NULL;
    mAuthType = AuthTypeSASLNone;
    mConnectionType = ConnectionTypeClear;
    mCheckCertificateEnabled = true;
    mVoIPEnabled = true;
    mDelimiter = 0;
    
    mBodyProgressEnabled = true;
    mIdleEnabled = false;
    mXListEnabled = false;
    mQResyncEnabled = false;
    mCondstoreEnabled = false;
    mXYMHighestModseqEnabled = false;
    mIdentityEnabled = false;
    mNamespaceEnabled = false;
    mCompressionEnabled = false;
    mIsGmail = false;
    mAllowsNewPermanentFlags = false;
    mWelcomeString = NULL;
    mNeedsMboxMailWorkaround = false;
    mDefaultNamespace = NULL;
    mServerIdentity = new IMAPIdentity();
    mClientIdentity = new IMAPIdentity();
    mTimeout = 30;
    mUIDValidity = 0;
    mUIDNext = 0;
    mModSequenceValue = 0;
    mFolderMsgCount = 0;
    mFirstUnseenUid = 0;
    mYahooServer = false;
    mRamblerRuServer = false;
    mHermesServer = false;
    mQipServer = false;
    mLastFetchedSequenceNumber = 0;
    mCurrentFolder = NULL;
    pthread_mutex_init(&mIdleLock, NULL);
    mState = STATE_DISCONNECTED;
    mImap = NULL;
    mProgressCallback = NULL;
    mProgressItemsCount = 0;
    mConnectionLogger = NULL;
    pthread_mutex_init(&mConnectionLoggerLock, NULL);
    mAutomaticConfigurationEnabled = true;
    mAutomaticConfigurationDone = false;
    mShouldDisconnect = false;
    mLoginResponse = NULL;
    mGmailUserDisplayName = NULL;
    mUnparsedResponseData = NULL;
}

IMAPSession::IMAPSession()
{
    init();
}

IMAPSession::~IMAPSession()
{
    MC_SAFE_RELEASE(mUnparsedResponseData);
    MC_SAFE_RELEASE(mGmailUserDisplayName);
    MC_SAFE_RELEASE(mLoginResponse);
    MC_SAFE_RELEASE(mClientIdentity);
    MC_SAFE_RELEASE(mServerIdentity);
    MC_SAFE_RELEASE(mHostname);
    MC_SAFE_RELEASE(mUsername);
    MC_SAFE_RELEASE(mPassword);
    MC_SAFE_RELEASE(mOAuth2Token);
    MC_SAFE_RELEASE(mWelcomeString);
    MC_SAFE_RELEASE(mDefaultNamespace);
    MC_SAFE_RELEASE(mCurrentFolder);
    pthread_mutex_destroy(&mIdleLock);
    pthread_mutex_destroy(&mConnectionLoggerLock);
}

void IMAPSession::setHostname(String * hostname)
{
    MC_SAFE_REPLACE_COPY(String, mHostname, hostname);
}

String * IMAPSession::hostname()
{
    return mHostname;
}

void IMAPSession::setPort(unsigned int port)
{
    mPort = port;
}

unsigned int IMAPSession::port()
{
    return mPort;
}

void IMAPSession::setUsername(String * username)
{
    MC_SAFE_REPLACE_COPY(String, mUsername, username);
}

String * IMAPSession::username()
{
    return mUsername;
}

void IMAPSession::setPassword(String * password)
{
    MC_SAFE_REPLACE_COPY(String, mPassword, password);
}

String * IMAPSession::password()
{
    return mPassword;
}

void IMAPSession::setOAuth2Token(String * token)
{
    MC_SAFE_REPLACE_COPY(String, mOAuth2Token, token);
}

String * IMAPSession::OAuth2Token()
{
    return mOAuth2Token;
}

void IMAPSession::setAuthType(AuthType authType)
{
    mAuthType = authType;
}

AuthType IMAPSession::authType()
{
    return mAuthType;
}

void IMAPSession::setConnectionType(ConnectionType connectionType)
{
    mConnectionType = connectionType;
}

ConnectionType IMAPSession::connectionType()
{
    return mConnectionType;
}

void IMAPSession::setTimeout(time_t timeout)
{
    mTimeout = timeout;
}

time_t IMAPSession::timeout()
{
    return mTimeout;
}

void IMAPSession::setCheckCertificateEnabled(bool enabled)
{
    mCheckCertificateEnabled = enabled;
}

bool IMAPSession::isCheckCertificateEnabled()
{
    return mCheckCertificateEnabled;
}

void IMAPSession::setVoIPEnabled(bool enabled)
{
    mVoIPEnabled = enabled;
}

bool IMAPSession::isVoIPEnabled()
{
    return mVoIPEnabled;
}

String * IMAPSession::loginResponse()
{
    return mLoginResponse;
}

Data * IMAPSession::unparsedResponseData()
{
    return mUnparsedResponseData;
}

static bool hasError(int errorCode)
{
    return ((errorCode != MAILIMAP_NO_ERROR) && (errorCode != MAILIMAP_NO_ERROR_AUTHENTICATED) &&
            (errorCode != MAILIMAP_NO_ERROR_NON_AUTHENTICATED));
}

bool IMAPSession::checkCertificate()
{
    if (!isCheckCertificateEnabled())
        return true;
    return mailcore::checkCertificate(mImap->imap_stream, hostname());
}

void IMAPSession::body_progress(size_t current, size_t maximum, void * context)
{
    IMAPSession * session;
    
    session = (IMAPSession *) context;
    session->bodyProgress((unsigned int) current, (unsigned int) maximum);
}

void IMAPSession::items_progress(size_t current, size_t maximum, void * context)
{
    IMAPSession * session;
    
    session = (IMAPSession *) context;
    session->itemsProgress((unsigned int) current, (unsigned int) maximum);
}

static void logger(mailimap * imap, int log_type, const char * buffer, size_t size, void * context)
{
    IMAPSession * session = (IMAPSession *) context;
    session->lockConnectionLogger();

    if (session->connectionLoggerNoLock() == NULL) {
        session->unlockConnectionLogger();
        return;
    }
    
    ConnectionLogType type = getConnectionType(log_type);
    if ((int) type == -1) {
        session->unlockConnectionLogger();
        return;
    }
    
    bool isBuffer = isBufferFromLogType(log_type);

    if (isBuffer) {
        AutoreleasePool * pool = new AutoreleasePool();
        Data * data = Data::dataWithBytes(buffer, (unsigned int) size);
        session->connectionLoggerNoLock()->log(session, type, data);
        pool->release();
    }
    else {
        session->connectionLoggerNoLock()->log(session, type, NULL);
    }
    session->unlockConnectionLogger();
}

void IMAPSession::setup()
{
    MCAssert(mImap == NULL);
    
    mImap = mailimap_new(0, NULL);
    mailimap_set_timeout(mImap, timeout());
    mailimap_set_progress_callback(mImap, body_progress, IMAPSession::items_progress, this);
    mailimap_set_logger(mImap, logger, this);
}

void IMAPSession::unsetup()
{
    mailimap * imap;
    
    LOCK();
    imap = mImap;
    mImap = NULL;
    mIdleEnabled = false;
    UNLOCK();
    
    if (imap != NULL) {
        if (imap->imap_stream != NULL) {
            mailstream_close(imap->imap_stream);
            imap->imap_stream = NULL;
        }
        mailimap_free(imap);
        imap = NULL;
    }
    
    mState = STATE_DISCONNECTED;
}

void IMAPSession::connect(ErrorCode * pError)
{
    int r;
    
    setup();

    MCLog("connect %s", MCUTF8DESC(this));

    MCAssert(mState == STATE_DISCONNECTED);

    if (mHostname == NULL) {
        * pError = ErrorConnection;
        goto close;
    }

    switch (mConnectionType) {
        case ConnectionTypeStartTLS:
        MCLog("STARTTLS connect");
        r = mailimap_socket_connect_voip(mImap, MCUTF8(mHostname), mPort, isVoIPEnabled());
        if (hasError(r)) {
            * pError = ErrorConnection;
            goto close;
        }

        r = mailimap_socket_starttls(mImap);
        if (hasError(r)) {
            MCLog("no TLS %i", r);
            * pError = ErrorTLSNotAvailable;
            goto close;
        }
        if (!checkCertificate()) {
            MCLog("StartTLS ssl connect certificate ERROR %d", r);
            * pError = ErrorCertificate;
            goto close;
        }

        break;

        case ConnectionTypeTLS:
        r = mailimap_ssl_connect_voip(mImap, MCUTF8(mHostname), mPort, isVoIPEnabled());
        MCLog("TLS ssl connect %s %u %u", MCUTF8(mHostname), mPort, r);
        if (hasError(r)) {
            MCLog("connect error %i", r);
            * pError = ErrorConnection;
            goto close;
        }
        if (!checkCertificate()) {
            MCLog("TLS ssl connect certificate ERROR %d", r);
            * pError = ErrorCertificate;
            goto close;
        }

        break;

        default:
        MCLog("socket connect %s %u", MCUTF8(mHostname), mPort);
        r = mailimap_socket_connect_voip(mImap, MCUTF8(mHostname), mPort, isVoIPEnabled());
        MCLog("socket connect %i", r);
        if (hasError(r)) {
            MCLog("connect error %i", r);
            * pError = ErrorConnection;
            goto close;
        }
        break;
    }
    
    mailstream_low * low;
    String * identifierString;
    char * identifier;
    
    low = mailstream_get_low(mImap->imap_stream);
    identifierString = String::stringWithUTF8Format("%s@%s:%u", MCUTF8(mUsername), MCUTF8(mHostname), mPort);
    identifier = strdup(identifierString->UTF8Characters());
    mailstream_low_set_identifier(low, identifier);
    
    if (mImap->imap_response != NULL) {
        MC_SAFE_REPLACE_RETAIN(String, mWelcomeString, String::stringWithUTF8Characters(mImap->imap_response));
        mYahooServer = (mWelcomeString->locationOfString(MCSTR("yahoo.com")) != -1);
#ifdef LIBETPAN_HAS_MAILIMAP_163_WORKAROUND
        if (mWelcomeString->locationOfString(MCSTR("Coremail System IMap Server Ready")) != -1)
            mailimap_set_163_workaround_enabled(mImap, 1);
#endif
        if (mWelcomeString->locationOfString(MCSTR("Courier-IMAP")) != -1) {
            LOCK();
            mIdleEnabled = true;
            UNLOCK();
            mNamespaceEnabled = true;
        }
        mRamblerRuServer = (mHostname->locationOfString(MCSTR(".rambler.ru")) != -1);
        mHermesServer = (mWelcomeString->locationOfString(MCSTR("Hermes")) != -1);
        mQipServer = (mWelcomeString->locationOfString(MCSTR("QIP IMAP server")) != -1);
    }
    
    mState = STATE_CONNECTED;
    
    if (isAutomaticConfigurationEnabled()) {
        if ((mImap->imap_connection_info != NULL) && (mImap->imap_connection_info->imap_capability != NULL)) {
            // Don't keep result. It will be kept in session state.
            capabilitySetWithSessionState(IndexSet::indexSet());
        }
        else {
            capability(pError);
            if (* pError != ErrorNone) {
                MCLog("capabilities failed");
                goto close;
            }
        }
    }
    
    * pError = ErrorNone;
    MCLog("connect ok");
    return;
    
close:
    unsetup();
}

void IMAPSession::connectIfNeeded(ErrorCode * pError)
{
    if (mShouldDisconnect) {
        disconnect();
        mShouldDisconnect = false;
    }
    
    if (mState == STATE_DISCONNECTED) {
        connect(pError);
    }
    else {
        * pError = ErrorNone;
    }
}

void IMAPSession::loginIfNeeded(ErrorCode * pError)
{
    connectIfNeeded(pError);
    if (* pError != ErrorNone)
        return;
    
    if (mState == STATE_CONNECTED) {
        login(pError);
    }
    else {
        * pError = ErrorNone;
    }
}

void IMAPSession::login(ErrorCode * pError)
{
    int r;
    
    MCLog("login");
    
    MCAssert(mState == STATE_CONNECTED);

    MC_SAFE_RELEASE(mLoginResponse);
    MC_SAFE_RELEASE(mUnparsedResponseData);

    if (mImap->imap_connection_info != NULL) {
        if (mImap->imap_connection_info->imap_capability != NULL) {
            mailimap_capability_data_free(mImap->imap_connection_info->imap_capability);
            mImap->imap_connection_info->imap_capability = NULL;
        }
    }
    
    const char * utf8username;
    const char * utf8password;
    utf8username = MCUTF8(mUsername);
    utf8password = MCUTF8(mPassword);
    if (utf8username == NULL) {
        utf8username = "";
    }
    if (utf8password == NULL) {
        utf8password = "";
    }
    
    switch (mAuthType) {
        case 0:
        default:
            r = mailimap_login(mImap, utf8username, utf8password);
            break;
            
        case AuthTypeSASLCRAMMD5:
            r = mailimap_authenticate(mImap, "CRAM-MD5",
                                      MCUTF8(mHostname),
                                      NULL,
                                      NULL,
                                      utf8username, utf8username,
                                      utf8password, NULL);
            break;
            
        case AuthTypeSASLPlain:
            r = mailimap_authenticate(mImap, "PLAIN",
                                      MCUTF8(mHostname),
                                      NULL,
                                      NULL,
                                      utf8username, utf8username,
                                      utf8password, NULL);
            break;
            
        case AuthTypeSASLGSSAPI:
            // needs to be tested
            r = mailimap_authenticate(mImap, "GSSAPI",
                                      MCUTF8(mHostname),
                                      NULL,
                                      NULL,
                                      utf8username, utf8username,
                                      utf8password, NULL /* realm */);
            break;
            
        case AuthTypeSASLDIGESTMD5:
            r = mailimap_authenticate(mImap, "DIGEST-MD5",
                                      MCUTF8(mHostname),
                                      NULL,
                                      NULL,
                                      utf8username, utf8username,
                                      utf8password, NULL);
            break;
            
        case AuthTypeSASLLogin:
            r = mailimap_authenticate(mImap, "LOGIN",
                                      MCUTF8(mHostname),
                                      NULL,
                                      NULL,
                                      utf8username, utf8username,
                                      utf8password, NULL);
            break;
            
        case AuthTypeSASLSRP:
            r = mailimap_authenticate(mImap, "SRP",
                                      MCUTF8(mHostname),
                                      NULL,
                                      NULL,
                                      utf8username, utf8username,
                                      utf8password, NULL);
            break;
            
        case AuthTypeSASLNTLM:
            r = mailimap_authenticate(mImap, "NTLM",
                                      MCUTF8(mHostname),
                                      NULL,
                                      NULL,
                                      utf8username, utf8username,
                                      utf8password, NULL/* realm */);
            break;
            
        case AuthTypeSASLKerberosV4:
            r = mailimap_authenticate(mImap, "KERBEROS_V4",
                                      MCUTF8(mHostname),
                                      NULL,
                                      NULL,
                                      utf8username, utf8username,
                                      utf8password, NULL/* realm */);
            break;
            
        case AuthTypeXOAuth2:
        case AuthTypeXOAuth2Outlook:
            if (mOAuth2Token == NULL) {
                r = MAILIMAP_ERROR_STREAM;
            }
            else {
                r = mailimap_oauth2_authenticate(mImap, utf8username, MCUTF8(mOAuth2Token));
            }
            break;
    }
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;

        Data * unparsed_response = Data::data();
        if (mImap->imap_stream_buffer != NULL) {
            unparsed_response = Data::dataWithBytes(mImap->imap_stream_buffer->str, (unsigned int) mImap->imap_stream_buffer->len);
        }
        MC_SAFE_REPLACE_RETAIN(Data, mUnparsedResponseData, unparsed_response);

        return;
    }
    else if (hasError(r)) {
        String * response;
        
        response = MCSTR("");
        if (mImap->imap_response != NULL) {
            response = String::stringWithUTF8Characters(mImap->imap_response);
        }
        MC_SAFE_REPLACE_COPY(String, mLoginResponse, response);
        if (response->locationOfString(MCSTR("not enabled for IMAP use")) != -1) {
            * pError = ErrorGmailIMAPNotEnabled;
        }
        else if (response->locationOfString(MCSTR("IMAP access is disabled")) != -1) {
            * pError = ErrorGmailIMAPNotEnabled;
        }
        else if (response->locationOfString(MCSTR("bandwidth limits")) != -1) {
            * pError = ErrorGmailExceededBandwidthLimit;
        }
        else if (response->locationOfString(MCSTR("Too many simultaneous connections")) != -1) {
            * pError = ErrorGmailTooManySimultaneousConnections;
        }
        else if (response->locationOfString(MCSTR("Maximum number of connections")) != -1) {
            * pError = ErrorGmailTooManySimultaneousConnections;
        }
        else if (response->locationOfString(MCSTR("Application-specific password required")) != -1) {
            * pError = ErrorGmailApplicationSpecificPasswordRequired;
        }
        else if (response->locationOfString(MCSTR("http://me.com/move")) != -1) {
            * pError = ErrorMobileMeMoved;
        }
        else if (response->locationOfString(MCSTR("OCF12")) != -1) {
            * pError = ErrorYahooUnavailable;
        }
        else if (response->locationOfString(MCSTR("Login to your account via a web browser")) != -1) {
            * pError = ErrorOutlookLoginViaWebBrowser;
        }
        else if (response->locationOfString(MCSTR("Service temporarily unavailable")) != -1) {
            mShouldDisconnect = true;
            * pError = ErrorConnection;
        }
        else {
            * pError = ErrorAuthentication;
        }
        return;
    }
    
    String * loginResponse = MCSTR("");
    if (mIsGmail) {
        if (mImap->imap_response != NULL) {
            loginResponse = String::stringWithUTF8Characters(mImap->imap_response);
            
            int location = loginResponse->locationOfString(MCSTR(" authenticated (Success)"));
            if (location != -1) {
                String * emailAndName = loginResponse->substringToIndex(location);
                location = emailAndName->locationOfString(MCSTR(" "));
                MC_SAFE_RELEASE(mGmailUserDisplayName);
                mGmailUserDisplayName = emailAndName->substringFromIndex(location + 1);
                mGmailUserDisplayName->retain();
            }
        }
    }
    MC_SAFE_REPLACE_COPY(String, mLoginResponse, loginResponse);
    
    mState = STATE_LOGGEDIN;
    
    if (isAutomaticConfigurationEnabled()) {
        if ((mImap->imap_connection_info != NULL) && (mImap->imap_connection_info->imap_capability != NULL)) {
            // Don't keep result. It will be kept in session state.
            capabilitySetWithSessionState(IndexSet::indexSet());
        }
        else {
            capability(pError);
            if (* pError != ErrorNone) {
                MCLog("capabilities failed");
                return;
            }
        }
    }
    else {
        // TODO: capabilities should be shared with other sessions for non automatic capabilities sessions.
    }
    enableFeatures();

    if (isAutomaticConfigurationEnabled()) {
        bool hasDefaultNamespace = false;
        if (isNamespaceEnabled()) {
            HashMap * result = fetchNamespace(pError);
            if (* pError != ErrorNone) {
                MCLog("fetch namespace failed");
                return;
            }
            IMAPNamespace * personalNamespace = (IMAPNamespace *) result->objectForKey(IMAPNamespacePersonal);
            if (personalNamespace != NULL) {
                setDefaultNamespace(personalNamespace);
                mDelimiter = defaultNamespace()->mainDelimiter();
                hasDefaultNamespace = true;
            }
        }
        
        if (!hasDefaultNamespace) {
            clist * imap_folders;
            IMAPFolder * folder;
            Array * folders;
            
            r = mailimap_list(mImap, "", "", &imap_folders);
            folders = resultsWithError(r, imap_folders, pError);
            if (* pError != ErrorNone)
                return;
            
            if (folders->count() > 0) {
                folder = (IMAPFolder *) folders->objectAtIndex(0);
            }
            else {
                folder = NULL;
            }
            if (folder == NULL) {
                * pError = ErrorNonExistantFolder;
                return;
            }
            
            mDelimiter = folder->delimiter();
            IMAPNamespace * defaultNamespace = IMAPNamespace::namespaceWithPrefix(MCSTR(""), folder->delimiter());
            setDefaultNamespace(defaultNamespace);
        }
        
        if (isIdentityEnabled()) {
            IMAPIdentity * serverIdentity = identity(clientIdentity(), pError);
            if (* pError != ErrorNone) {
                // Ignore identity errors
                MCLog("fetch identity failed");
            }
            else {
                MC_SAFE_REPLACE_RETAIN(IMAPIdentity, mServerIdentity, serverIdentity);
            }
        }
    }
    else {
        // TODO: namespace should be shared with other sessions for non automatic namespace.
    }
    
    mAutomaticConfigurationDone = true;
    
    * pError = ErrorNone;
    MCLog("login ok");
}

void IMAPSession::selectIfNeeded(String * folder, ErrorCode * pError)
{
    loginIfNeeded(pError);
    if (* pError != ErrorNone)
        return;
    
    if (mState == STATE_SELECTED) {
        MCAssert(mCurrentFolder != NULL);
        if (mCurrentFolder->caseInsensitiveCompare(folder) != 0) {
            select(folder, pError);
        }
    }
    else if (mState == STATE_LOGGEDIN) {
        select(folder, pError);
    }
    else {
        * pError = ErrorNone;
    }
}

static uint64_t get_mod_sequence_value(mailimap * session)
{
    uint64_t mod_sequence_value;
    clistiter * cur;
    
    mod_sequence_value = 0;
    for(cur = clist_begin(session->imap_response_info->rsp_extension_list) ; cur != NULL ; cur = clist_next(cur)) {
        struct mailimap_extension_data * ext_data;
        struct mailimap_condstore_resptextcode * resptextcode;
        
        ext_data = (struct mailimap_extension_data *) clist_content(cur);
        if (ext_data->ext_extension->ext_id != MAILIMAP_EXTENSION_CONDSTORE) {
            continue;
        }
        if (ext_data->ext_type != MAILIMAP_CONDSTORE_TYPE_RESP_TEXT_CODE) {
            continue;
        }
        
        resptextcode = (struct mailimap_condstore_resptextcode *) ext_data->ext_data;
        switch (resptextcode->cs_type) {
            case MAILIMAP_CONDSTORE_RESPTEXTCODE_HIGHESTMODSEQ:
                mod_sequence_value = resptextcode->cs_data.cs_modseq_value;
                break;
            case MAILIMAP_CONDSTORE_RESPTEXTCODE_NOMODSEQ:
                mod_sequence_value = 0;
                break;
        }
    }
    
    return mod_sequence_value;
}

String * IMAPSession::customCommand(String * command, ErrorCode * pError)
{
    int r;
    
    loginIfNeeded(pError);
    if (* pError != ErrorNone)
        return NULL;

    r = mailimap_custom_command(mImap, MCUTF8(command));
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return NULL;
    }
    else if (hasError(r)) {
        * pError = ErrorCustomCommand;
        return NULL;
    }
    
    String *response = String::stringWithUTF8Characters(mImap->imap_response);
    return response;
}

void IMAPSession::select(String * folder, ErrorCode * pError)
{
    int r;

    MCLog("select");
    MCAssert(mState == STATE_LOGGEDIN || mState == STATE_SELECTED);

    r = mailimap_select(mImap, MCUTF8(folder));
    MCLog("select error : %i", r);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        MCLog("select error : %s %i", MCUTF8DESC(this), * pError);
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorNonExistantFolder;
        mState = STATE_LOGGEDIN;
        MC_SAFE_RELEASE(mCurrentFolder);
        return;
    }

    MC_SAFE_REPLACE_COPY(String, mCurrentFolder, folder);

    if (mImap->imap_selection_info != NULL) {
        mUIDValidity = mImap->imap_selection_info->sel_uidvalidity;
        mUIDNext = mImap->imap_selection_info->sel_uidnext;        
        if (mImap->imap_selection_info->sel_has_exists) {
            mFolderMsgCount = (unsigned int) (mImap->imap_selection_info->sel_exists);
        } else {
            mFolderMsgCount = -1;
        }
        
        if (mImap->imap_selection_info->sel_first_unseen) {
            mFirstUnseenUid = mImap->imap_selection_info->sel_first_unseen;
        } else {
            mFirstUnseenUid = 0;
        }
        
        if (mImap->imap_selection_info->sel_perm_flags) {
          clistiter * cur;

          struct mailimap_flag_perm * perm_flag;
          for(cur = clist_end(mImap->imap_selection_info->sel_perm_flags) ; cur != NULL ;
              cur = clist_previous(cur)) {
            perm_flag = (struct mailimap_flag_perm *)clist_content(cur);
            mAllowsNewPermanentFlags = perm_flag->fl_type == MAILIMAP_FLAG_PERM_ALL;
            if (mAllowsNewPermanentFlags) {
              break;
            }
          }
        }
      
        mModSequenceValue = get_mod_sequence_value(mImap);
    }

    mState = STATE_SELECTED;
    * pError = ErrorNone;
    MCLog("select ok");
}





IMAPFolderStatus * IMAPSession::folderStatus(String * folder, ErrorCode * pError)
{
    int r;
    
    MCLog("status");
    MCAssert(mState == STATE_LOGGEDIN || mState == STATE_SELECTED);

    struct mailimap_mailbox_data_status * status;

    struct mailimap_status_att_list * status_att_list;
        
    status_att_list = mailimap_status_att_list_new_empty();
    mailimap_status_att_list_add(status_att_list, MAILIMAP_STATUS_ATT_UNSEEN);
    mailimap_status_att_list_add(status_att_list, MAILIMAP_STATUS_ATT_MESSAGES);
    mailimap_status_att_list_add(status_att_list, MAILIMAP_STATUS_ATT_RECENT);
    mailimap_status_att_list_add(status_att_list, MAILIMAP_STATUS_ATT_UIDNEXT);
    mailimap_status_att_list_add(status_att_list, MAILIMAP_STATUS_ATT_UIDVALIDITY);
    if (mCondstoreEnabled || mXYMHighestModseqEnabled) {
        mailimap_status_att_list_add(status_att_list, MAILIMAP_STATUS_ATT_HIGHESTMODSEQ);
    }
    
    r = mailimap_status(mImap, MCUTF8(folder), status_att_list, &status);
    
    IMAPFolderStatus * fs;
    fs = new IMAPFolderStatus();
    fs->autorelease();
    
    MCLog("status error : %i", r);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        MCLog("status error : %s %i", MCUTF8DESC(this), * pError);
        mailimap_status_att_list_free(status_att_list);
        return fs;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        mailimap_status_att_list_free(status_att_list);
        return fs;
    }
    else if (hasError(r)) {
        * pError = ErrorNonExistantFolder;
        mailimap_status_att_list_free(status_att_list);
        return fs;
    }
    
    clistiter * cur;
    
    
    if (status != NULL) {
        
            struct mailimap_status_info * status_info;
            for(cur = clist_begin(status->st_info_list) ; cur != NULL ;
                cur = clist_next(cur)) {                
                
                status_info = (struct mailimap_status_info *) clist_content(cur);
                                
                switch (status_info->st_att) {
                    case MAILIMAP_STATUS_ATT_UNSEEN:
                        fs->setUnseenCount(status_info->st_value);
                        break;
                    case MAILIMAP_STATUS_ATT_MESSAGES:
                        fs->setMessageCount(status_info->st_value);
                        break;
                    case MAILIMAP_STATUS_ATT_RECENT:
                        fs->setRecentCount(status_info->st_value);
                        break;
                    case MAILIMAP_STATUS_ATT_UIDNEXT:
                        fs->setUidNext(status_info->st_value);
                        break;                        
                    case MAILIMAP_STATUS_ATT_UIDVALIDITY:
                        fs->setUidValidity(status_info->st_value);
                        break;
                    case MAILIMAP_STATUS_ATT_EXTENSION: {
                        struct mailimap_extension_data * ext_data = status_info->st_ext_data;
                        if (ext_data->ext_extension == &mailimap_extension_condstore) {
                            struct mailimap_condstore_status_info * status_info = (struct mailimap_condstore_status_info *) ext_data->ext_data;
                            fs->setHighestModSeqValue(status_info->cs_highestmodseq_value);
                        }
                        break;
                    }
                }
            }            

        mailimap_mailbox_data_status_free(status);
    }

    mailimap_status_att_list_free(status_att_list);

    return fs;
}

void IMAPSession::noop(ErrorCode * pError)
{
    int r;
    
    if (mImap == NULL)
        return;
    
    MCLog("connect");
    loginIfNeeded(pError);
    if (* pError != ErrorNone) {
        return;
    }
    if (mImap->imap_stream != NULL) {
        r = mailimap_noop(mImap);
        if (r == MAILIMAP_ERROR_STREAM) {
            * pError = ErrorConnection;
        }
        if (r == MAILIMAP_ERROR_NOOP) {
            * pError = ErrorNoop;
        }
    }
}

#pragma mark mailbox flags conversion

static struct {
    const char * name;
    int flag;
} mb_keyword_flag[] = {
    {"Inbox",     IMAPFolderFlagInbox},
    {"AllMail",   IMAPFolderFlagAllMail},
    {"Sent",      IMAPFolderFlagSentMail},
    {"Spam",      IMAPFolderFlagSpam},
    {"Starred",   IMAPFolderFlagStarred},
    {"Trash",     IMAPFolderFlagTrash},
    {"Important", IMAPFolderFlagImportant},
    {"Drafts",    IMAPFolderFlagDrafts},
    {"Archive",   IMAPFolderFlagArchive},
    {"All",       IMAPFolderFlagAll},
    {"Junk",      IMAPFolderFlagJunk},
    {"Flagged",   IMAPFolderFlagFlagged},
};

static int imap_mailbox_flags_to_flags(struct mailimap_mbx_list_flags * imap_flags)
{
    int flags;
    clistiter * cur;
    
    flags = 0;
    if (imap_flags->mbf_type == MAILIMAP_MBX_LIST_FLAGS_SFLAG) {
        switch (imap_flags->mbf_sflag) {
            case MAILIMAP_MBX_LIST_SFLAG_MARKED:
                flags |= IMAPFolderFlagMarked;
                break;
            case MAILIMAP_MBX_LIST_SFLAG_NOSELECT:
                flags |= IMAPFolderFlagNoSelect;
                break;
            case MAILIMAP_MBX_LIST_SFLAG_UNMARKED:
                flags |= IMAPFolderFlagUnmarked;
                break;
        }
    }
    
    for(cur = clist_begin(imap_flags->mbf_oflags) ; cur != NULL ;
        cur = clist_next(cur)) {
        struct mailimap_mbx_list_oflag * oflag;
        
        oflag = (struct mailimap_mbx_list_oflag *) clist_content(cur);
        
        switch (oflag->of_type) {
            case MAILIMAP_MBX_LIST_OFLAG_NOINFERIORS:
                flags |= IMAPFolderFlagNoInferiors;
                break;
                
            case MAILIMAP_MBX_LIST_OFLAG_FLAG_EXT:
                for(unsigned int i = 0 ; i < sizeof(mb_keyword_flag) / sizeof(mb_keyword_flag[0]) ; i ++) {
                    if (strcasecmp(mb_keyword_flag[i].name, oflag->of_flag_ext) == 0) {
                        flags |= mb_keyword_flag[i].flag;
                    }
                }
                break;
        }
    }
    
    return flags;
}

static Array * resultsWithError(int r, clist * list, ErrorCode * pError)
{
    clistiter * cur;
    Array * result;
    
    result = Array::array();
    if (r == MAILIMAP_ERROR_STREAM) {
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        * pError = ErrorParse;
        return NULL;
    }
    else if (hasError(r)) {
        * pError = ErrorNonExistantFolder;
        return NULL;
    }
    
    for(cur = clist_begin(list) ; cur != NULL ; cur = cur->next) {
        struct mailimap_mailbox_list * mb_list;
        IMAPFolderFlag flags;
        IMAPFolder * folder;
        String * path;
        
        mb_list = (struct mailimap_mailbox_list *) cur->data;
        
        flags = IMAPFolderFlagNone;
        if (mb_list->mb_flag != NULL)
            flags = (IMAPFolderFlag) imap_mailbox_flags_to_flags(mb_list->mb_flag);
        
        folder = new IMAPFolder();
        path = String::stringWithUTF8Characters(mb_list->mb_name);
        if (path->uppercaseString()->isEqual(MCSTR("INBOX"))) {
            folder->setPath(MCSTR("INBOX"));
        }
        else {
            folder->setPath(path);
        }
        folder->setDelimiter(mb_list->mb_delimiter);
        folder->setFlags(flags);
        
        result->addObject(folder);
        
        folder->release();
    }
    
    mailimap_list_result_free(list);
    
    * pError = ErrorNone;
    return result;
}

// Deprecated
char IMAPSession::fetchDelimiterIfNeeded(char defaultDelimiter, ErrorCode * pError)
{
    int r;
    clist * imap_folders;
    IMAPFolder * folder;
    Array * folders;
    
    if (defaultDelimiter != 0)
        return defaultDelimiter;
    
    r = mailimap_list(mImap, "", "", &imap_folders);
    folders = resultsWithError(r, imap_folders, pError);
    if (* pError == ErrorConnection || * pError == ErrorParse)
        mShouldDisconnect = true;
    if (* pError != ErrorNone)
        return 0;
    
    if (folders->count() > 0) {
        folder = (IMAPFolder *) folders->objectAtIndex(0);
    }
    else {
        folder = NULL;
    }
    if (folder == NULL)
        return 0;
    
    * pError = ErrorNone;
    return folder->delimiter();
}

Array * /* IMAPFolder */ IMAPSession::fetchSubscribedFolders(ErrorCode * pError)
{
    int r;
    clist * imap_folders;
    
    MCLog("fetch subscribed");
    loginIfNeeded(pError);
    if (* pError != ErrorNone)
        return NULL;
    
    if (mDelimiter == 0) {
        char delimiter;
        
        delimiter = fetchDelimiterIfNeeded(mDelimiter, pError);
        if (* pError != ErrorNone)
            return NULL;
        
        //setDelimiter(delimiter);
        mDelimiter = delimiter;
    }
    
    String * prefix;
    prefix = defaultNamespace()->mainPrefix();
    if (prefix == NULL) {
        prefix = MCSTR("");
    }
    if (prefix->length() > 0) {
        if (!prefix->hasSuffix(String::stringWithUTF8Format("%c", mDelimiter))) {
            prefix = prefix->stringByAppendingUTF8Format("%c", mDelimiter);
        }
    }
    
    r = mailimap_lsub(mImap, MCUTF8(prefix), "*", &imap_folders);
    MCLog("fetch subscribed %u", r);
    Array * result = resultsWithError(r, imap_folders, pError);
    if (* pError == ErrorConnection || * pError == ErrorParse)
        mShouldDisconnect = true;
    return result;
}

Array * /* IMAPFolder */ IMAPSession::fetchAllFolders(ErrorCode * pError)
{
    int r;
    clist * imap_folders;
    
    loginIfNeeded(pError);
    if (* pError != ErrorNone)
        return NULL;
    
    if (mDelimiter == 0) {
        char delimiter;
        
        delimiter = fetchDelimiterIfNeeded(mDelimiter, pError);
        if (* pError != ErrorNone)
            return NULL;
        
        //setDelimiter(delimiter);
        mDelimiter = delimiter;
    }
    
    String * prefix = NULL;
    if (defaultNamespace()) {
        prefix = defaultNamespace()->mainPrefix();
    }
    if (prefix == NULL) {
        prefix = MCSTR("");
    }
    if (prefix->length() > 0) {
        if (!prefix->hasSuffix(String::stringWithUTF8Format("%c", mDelimiter))) {
            prefix = prefix->stringByAppendingUTF8Format("%c", mDelimiter);
        }
    }
    
    if (mXListEnabled) {
        r = mailimap_xlist(mImap, MCUTF8(prefix), "*", &imap_folders);
    }
    else {
        r = mailimap_list(mImap, MCUTF8(prefix), "*", &imap_folders);
    }
    Array * result = resultsWithError(r, imap_folders, pError);
    if (* pError == ErrorConnection || * pError == ErrorParse)
        mShouldDisconnect = true;
    
    if (result != NULL) {
        bool hasInbox = false;
        mc_foreacharray(IMAPFolder, folder, result) {
            if (folder->path()->isEqual(MCSTR("INBOX"))) {
                hasInbox = true;
            }
        }

        if (!hasInbox) {
            mc_foreacharray(IMAPFolder, folder, result) {
                if (folder->flags() & IMAPFolderFlagInbox) {
                    // some mail providers use non-standart name for inbox folder
                    hasInbox = true;
                    folder->setPath(MCSTR("INBOX"));
                    break;
                }
            }

            if (!hasInbox) {
                r = mailimap_list(mImap, "", "INBOX", &imap_folders);
                Array * inboxResult = resultsWithError(r, imap_folders, pError);
                if (* pError == ErrorConnection || * pError == ErrorParse)
                    mShouldDisconnect = true;
                result->addObjectsFromArray(inboxResult);
                hasInbox = true;
            }
        }
    }
    
    return result;
}

void IMAPSession::renameFolder(String * folder, String * otherName, ErrorCode * pError)
{
    int r;
    
    selectIfNeeded(MCSTR("INBOX"), pError);
    if (* pError != ErrorNone)
        return;
    
    r = mailimap_rename(mImap, MCUTF8(folder), MCUTF8(otherName));
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorRename;
        return;
    }
    * pError = ErrorNone;
}

void IMAPSession::deleteFolder(String * folder, ErrorCode * pError)
{
    int r;
    
    selectIfNeeded(MCSTR("INBOX"), pError);
    if (* pError != ErrorNone)
        return;
    
    r = mailimap_delete(mImap, MCUTF8(folder));
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorDelete;
        return;
    }
    * pError = ErrorNone;
}

void IMAPSession::createFolder(String * folder, ErrorCode * pError)
{
    int r;
    
    selectIfNeeded(MCSTR("INBOX"), pError);
    if (* pError != ErrorNone)
        return;
    
    r = mailimap_create(mImap, MCUTF8(folder));
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorCreate;
        return;
    }
    
    * pError = ErrorNone;
    subscribeFolder(folder, pError);
}

void IMAPSession::subscribeFolder(String * folder, ErrorCode * pError)
{
    int r;
    
    selectIfNeeded(MCSTR("INBOX"), pError);
    if (* pError != ErrorNone)
        return;
    
    r = mailimap_subscribe(mImap, MCUTF8(folder));
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorSubscribe;
        return;
    }
    * pError = ErrorNone;
}

void IMAPSession::unsubscribeFolder(String * folder, ErrorCode * pError)
{
    int r;
    
    selectIfNeeded(MCSTR("INBOX"), pError);
    if (* pError != ErrorNone)
        return;
    
    r = mailimap_unsubscribe(mImap, MCUTF8(folder));
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorSubscribe;
        return;
    }
    * pError = ErrorNone;
}

void IMAPSession::appendMessage(String * folder, Data * messageData, MessageFlag flags,
    IMAPProgressCallback * progressCallback, uint32_t * createdUID, ErrorCode * pError)
{
    this->appendMessageWithCustomFlags(folder, messageData, flags, NULL, progressCallback, createdUID, pError);
}

void IMAPSession::appendMessageWithCustomFlags(String * folder, Data * messageData, MessageFlag flags, Array * customFlags,
    IMAPProgressCallback * progressCallback, uint32_t * createdUID, ErrorCode * pError)
{
    this->appendMessageWithCustomFlagsAndDate(folder, messageData, flags, NULL, (time_t) -1, progressCallback, createdUID, pError);
}

void IMAPSession::appendMessageWithCustomFlagsAndDate(String * folder, Data * messageData, MessageFlag flags, Array * customFlags, time_t date,
                                                      IMAPProgressCallback * progressCallback, uint32_t * createdUID, ErrorCode * pError)
{
    int r;
    struct mailimap_flag_list * flag_list;
    uint32_t uidvalidity;
    uint32_t uidresult;
    
    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return;
    
    mProgressCallback = progressCallback;
    bodyProgress(0, messageData->length());
    
    flag_list = flags_to_lep(flags);
    if (customFlags != NULL) {
        for (unsigned int i = 0 ; i < customFlags->count() ; i ++) {
            struct mailimap_flag * f;
            String * customFlag = (String *) customFlags->objectAtIndex(i);
            
            f = mailimap_flag_new_flag_keyword(strdup(customFlag->UTF8Characters()));
            mailimap_flag_list_add(flag_list, f);
        }
    }
    struct mailimap_date_time * imap_date = NULL;
    if (date != (time_t) -1) {
        imap_date = imapDateFromTimestamp(date);
    }
    r = mailimap_uidplus_append(mImap, MCUTF8(folder), flag_list, imap_date, messageData->bytes(), messageData->length(),
        &uidvalidity, &uidresult);
    if (imap_date != NULL) {
        mailimap_date_time_free(imap_date);
    }
    mailimap_flag_list_free(flag_list);
    
    bodyProgress(messageData->length(), messageData->length());
    mProgressCallback = NULL;
    
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorAppend;
        return;
    }
    
    * createdUID = uidresult;
    * pError = ErrorNone;
}

void IMAPSession::appendMessageWithCustomFlagsAndDate(String * folder, String * messagePath, MessageFlag flags, Array * customFlags, time_t date,
                                                      IMAPProgressCallback * progressCallback, uint32_t * createdUID, ErrorCode * pError)
{
    Data * messageData = Data::dataWithContentsOfFile(messagePath);
    if (!messageData) {
        * pError = ErrorFile;
        return;
    }

    return appendMessageWithCustomFlagsAndDate(folder, messageData, flags, customFlags, date, progressCallback, createdUID, pError);
}

void IMAPSession::copyMessages(String * folder, IndexSet * uidSet, String * destFolder,
     HashMap ** pUidMapping, ErrorCode * pError)
{
    int r;
    struct mailimap_set * set;
    struct mailimap_set * src_uid;
    struct mailimap_set * dest_uid;
    uint32_t uidvalidity;
    clist * setList;
    IndexSet * uidSetResult;
    HashMap * uidMapping = NULL;

    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return;

    set = setFromIndexSet(uidSet);
    if (clist_count(set->set_list) == 0) {
        mailimap_set_free(set);
        return;
    }

    setList = splitSet(set, 10);
    uidSetResult = NULL;

    for(clistiter * iter = clist_begin(setList) ; iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_set * current_set;

        current_set = (struct mailimap_set *) clist_content(iter);

        r = mailimap_uidplus_uid_copy(mImap, current_set, MCUTF8(destFolder),
            &uidvalidity, &src_uid, &dest_uid);
        if (r == MAILIMAP_ERROR_STREAM) {
            mShouldDisconnect = true;
            * pError = ErrorConnection;
            goto release;
        }
        else if (r == MAILIMAP_ERROR_PARSE) {
            mShouldDisconnect = true;
            * pError = ErrorParse;
            goto release;
        }
        else if (hasError(r)) {
            * pError = ErrorCopy;
            goto release;
        }

        if ((src_uid != NULL) && (dest_uid != NULL)) {
            if (uidMapping == NULL) {
                uidMapping = HashMap::hashMap();
            }
            
            Array * srcUidsArray = arrayFromSet(src_uid);
            Array * destUidsArray = arrayFromSet(dest_uid);

            for(int i = 0 ; i < srcUidsArray->count() && i < destUidsArray->count() ; i ++) {
                uidMapping->setObjectForKey(srcUidsArray->objectAtIndex(i), destUidsArray->objectAtIndex(i));
            }
        }

        if (src_uid != NULL) {
            mailimap_set_free(src_uid);
        }

        if (dest_uid != NULL) {
            mailimap_set_free(dest_uid);
        }
    }
    if (pUidMapping != NULL) {
        * pUidMapping = uidMapping;
    }
    * pError = ErrorNone;

    release:

    for(clistiter * iter = clist_begin(setList) ; iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_set * current_set;

        current_set = (struct mailimap_set *) clist_content(iter);
        mailimap_set_free(current_set);
    }
    clist_free(setList);
    mailimap_set_free(set);
}

void IMAPSession::moveMessages(String * folder, IndexSet * uidSet, String * destFolder,
     HashMap ** pUidMapping, ErrorCode * pError)
{
    int r;
    struct mailimap_set * set;
    struct mailimap_set * src_uid;
    struct mailimap_set * dest_uid;
    uint32_t uidvalidity;
    clist * setList;
    IndexSet * uidSetResult;
    HashMap * uidMapping = NULL;

    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return;

    set = setFromIndexSet(uidSet);
    if (clist_count(set->set_list) == 0) {
        mailimap_set_free(set);
        return;
    }

    setList = splitSet(set, 10);
    uidSetResult = NULL;

    for(clistiter * iter = clist_begin(setList) ; iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_set * current_set;

        current_set = (struct mailimap_set *) clist_content(iter);

        r = mailimap_uidplus_uid_move(mImap, current_set, MCUTF8(destFolder),
            &uidvalidity, &src_uid, &dest_uid);
        if (r == MAILIMAP_ERROR_STREAM) {
            mShouldDisconnect = true;
            * pError = ErrorConnection;
            goto release;
        }
        else if (r == MAILIMAP_ERROR_PARSE) {
            mShouldDisconnect = true;
            * pError = ErrorParse;
            goto release;
        }
        else if (hasError(r)) {
            * pError = ErrorCopy;
            goto release;
        }

        if ((src_uid != NULL) && (dest_uid != NULL)) {
            if (uidMapping == NULL) {
                uidMapping = HashMap::hashMap();
            }
            
            Array * srcUidsArray = arrayFromSet(src_uid);
            Array * destUidsArray = arrayFromSet(dest_uid);

            for(int i = 0 ; i < srcUidsArray->count() && i < destUidsArray->count() ; i ++) {
                uidMapping->setObjectForKey(srcUidsArray->objectAtIndex(i), destUidsArray->objectAtIndex(i));
            }
        }

        if (src_uid != NULL) {
            mailimap_set_free(src_uid);
        }

        if (dest_uid != NULL) {
            mailimap_set_free(dest_uid);
        }
    }
    if (pUidMapping != NULL) {
        * pUidMapping = uidMapping;
    }
    * pError = ErrorNone;

    release:

    for(clistiter * iter = clist_begin(setList) ; iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_set * current_set;

        current_set = (struct mailimap_set *) clist_content(iter);
        mailimap_set_free(current_set);
    }
    clist_free(setList);
    mailimap_set_free(set);
}

void IMAPSession::expunge(String * folder, ErrorCode * pError)
{
    int r;
    
    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return;
    
    r = mailimap_expunge(mImap);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorExpunge;
        return;
    }
    * pError = ErrorNone;
}

static int
fetch_imap(mailimap * imap, bool identifier_is_uid, uint32_t identifier,
           struct mailimap_fetch_type * fetch_type,
           char ** result, size_t * result_len)
{
    int r;
    struct mailimap_msg_att * msg_att;
    struct mailimap_msg_att_item * msg_att_item;
    clist * fetch_result;
    struct mailimap_set * set;
    char * text;
    size_t text_length;
    clistiter * cur;
    
    set = mailimap_set_new_single(identifier);
    if (identifier_is_uid) {
        r = mailimap_uid_fetch(imap, set, fetch_type, &fetch_result);
    }
    else {
        r = mailimap_fetch(imap, set, fetch_type, &fetch_result);
    }
    
    mailimap_set_free(set);
    
    switch (r) {
        case MAILIMAP_NO_ERROR:
            break;
        default:
            return r;
    }
    
    if (clist_isempty(fetch_result)) {
        mailimap_fetch_list_free(fetch_result);
        return MAILIMAP_ERROR_FETCH;
    }
    
    msg_att = (struct mailimap_msg_att *) clist_begin(fetch_result)->data;
    
    text = NULL;
    text_length = 0;
    
    for(cur = clist_begin(msg_att->att_list) ; cur != NULL ;
        cur = clist_next(cur)) {
        msg_att_item = (struct mailimap_msg_att_item *) clist_content(cur);
        
        if (msg_att_item->att_type != MAILIMAP_MSG_ATT_ITEM_STATIC) {
            continue;
        }
        
        if (msg_att_item->att_data.att_static->att_type !=
            MAILIMAP_MSG_ATT_BODY_SECTION) {
            continue;
        }
        
        text = msg_att_item->att_data.att_static->att_data.att_body_section->sec_body_part;
        msg_att_item->att_data.att_static->att_data.att_body_section->sec_body_part = NULL;
        text_length = msg_att_item->att_data.att_static->att_data.att_body_section->sec_length;
    }
    
    mailimap_fetch_list_free(fetch_result);
    
    if (text == NULL)
        return MAILIMAP_ERROR_FETCH;
    
    * result = text;
    * result_len = text_length;
    
    return MAILIMAP_NO_ERROR;
}

HashMap * IMAPSession::fetchMessageNumberUIDMapping(String * folder, uint32_t fromUID, uint32_t toUID,
    ErrorCode * pError)
{
    struct mailimap_set * imap_set;
    struct mailimap_fetch_type * fetch_type;
    clist * fetch_result;
    HashMap * result;
    struct mailimap_fetch_att * fetch_att;
    int r;
    clistiter * iter;
    
    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return NULL;
    
    result = HashMap::hashMap();
    
    imap_set = mailimap_set_new_interval(fromUID, toUID);
    fetch_type = mailimap_fetch_type_new_fetch_att_list_empty();
    fetch_att = mailimap_fetch_att_new_uid();
    mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
    
    r = mailimap_uid_fetch(mImap, imap_set, fetch_type, &fetch_result);
    mailimap_fetch_type_free(fetch_type);
    mailimap_set_free(imap_set);
    
    if (r == MAILIMAP_ERROR_STREAM) {
        MCLog("error stream");
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        MCLog("error parse");
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return NULL;
    }
    else if (hasError(r)) {
        MCLog("error fetch");
        * pError = ErrorFetch;
        return NULL;
    }
    
    for(iter = clist_begin(fetch_result) ; iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_msg_att * msg_att;
        clistiter * item_iter;
        uint32_t uid;
        
        msg_att = (struct mailimap_msg_att *) clist_content(iter);
        uid = 0;
        for(item_iter = clist_begin(msg_att->att_list) ; item_iter != NULL ; item_iter = clist_next(item_iter)) {
            struct mailimap_msg_att_item * att_item;
            
            att_item = (struct mailimap_msg_att_item *) clist_content(item_iter);
            if (att_item->att_type == MAILIMAP_MSG_ATT_ITEM_STATIC) {
                struct mailimap_msg_att_static * att_static;
                
                att_static = att_item->att_data.att_static;
                if (att_static->att_type == MAILIMAP_MSG_ATT_UID) {
                    uid = att_static->att_data.att_uid;
                }
            }
        }
        
        if (uid < fromUID) {
            uid = 0;
        }
        
        if (uid != 0) {
            result->setObjectForKey(Value::valueWithUnsignedLongValue(msg_att->att_number),
                Value::valueWithUnsignedLongValue(uid));
        }
    }
    
    mailimap_fetch_list_free(fetch_result);
    * pError = ErrorNone;
    
    return result;
}

struct msg_att_handler_data {
    IndexSet * uidsFilter;
    IndexSet * numbersFilter;
    bool fetchByUID;
    Array * result;
    IMAPMessagesRequestKind requestKind;
    uint32_t mLastFetchedSequenceNumber;
    HashMap * mapping;
    bool needsHeader;
    bool needsBody;
    bool needsFlags;
    bool needsGmailLabels;
    bool needsGmailMessageID;
    bool needsGmailThreadID;
};

static void msg_att_handler(struct mailimap_msg_att * msg_att, void * context)
{
    clistiter * item_iter;
    uint32_t uid;
    IMAPMessage * msg;
    bool hasHeader;
    bool hasBody;
    bool hasFlags;
    bool hasGmailLabels;
    bool hasGmailMessageID;
    bool hasGmailThreadID;
    struct msg_att_handler_data * msg_att_context;
    bool fetchByUID;
    Array * result;
    IMAPMessagesRequestKind requestKind;
    uint32_t mLastFetchedSequenceNumber;
    HashMap * mapping;
    bool needsHeader;
    bool needsBody;
    bool needsFlags;
    bool needsGmailLabels;
    bool needsGmailMessageID;
    bool needsGmailThreadID;
    IndexSet * uidsFilter;
    IndexSet * numbersFilter;
    
    msg_att_context = (struct msg_att_handler_data *) context;
    uidsFilter = msg_att_context->uidsFilter;
    numbersFilter = msg_att_context->numbersFilter;
    fetchByUID = msg_att_context->fetchByUID;
    result = msg_att_context->result;
    requestKind = msg_att_context->requestKind;
    mapping = msg_att_context->mapping;
    needsHeader = msg_att_context->needsHeader;
    needsBody = msg_att_context->needsBody;
    needsFlags = msg_att_context->needsFlags;
    needsGmailLabels = msg_att_context->needsGmailLabels;
    needsGmailMessageID = msg_att_context->needsGmailMessageID;
    needsGmailThreadID = msg_att_context->needsGmailThreadID;

    hasHeader = false;
    hasBody = false;
    hasFlags = false;
    hasGmailLabels = false;
    hasGmailMessageID = false;
    hasGmailThreadID = false;
    
    if (numbersFilter != NULL) {
        if (!numbersFilter->containsIndex((uint64_t) msg_att->att_number)) {
            return;
        }
    }

    msg = new IMAPMessage();
    
    uid = 0;
    mLastFetchedSequenceNumber = msg_att->att_number;
    if (mapping != NULL) {
        uid = (uint32_t) ((Value *) mapping->objectForKey(Value::valueWithUnsignedLongValue(msg_att->att_number)))->longLongValue();
    }

    msg->setSequenceNumber(msg_att->att_number);
    for(item_iter = clist_begin(msg_att->att_list) ; item_iter != NULL ; item_iter = clist_next(item_iter)) {
        struct mailimap_msg_att_item * att_item;
        
        att_item = (struct mailimap_msg_att_item *) clist_content(item_iter);
        if (att_item->att_type == MAILIMAP_MSG_ATT_ITEM_DYNAMIC) {
            MessageFlag flags;
            
            flags = flags_from_lep_att_dynamic(att_item->att_data.att_dyn);
            msg->setFlags(flags);
            msg->setOriginalFlags(flags);
            hasFlags = true;
            
            Array * customFlags;
            customFlags = custom_flags_from_lep_att_dynamic(att_item->att_data.att_dyn);
            msg->setCustomFlags(customFlags);
        }
        else if (att_item->att_type == MAILIMAP_MSG_ATT_ITEM_STATIC) {
            struct mailimap_msg_att_static * att_static;
            
            att_static = att_item->att_data.att_static;
            if (att_static->att_type == MAILIMAP_MSG_ATT_UID) {
                uid = att_static->att_data.att_uid;
            }
            else if (att_static->att_type == MAILIMAP_MSG_ATT_ENVELOPE) {
                struct mailimap_envelope * env;
                
                MCLog("parse envelope %lu", (unsigned long) uid);
                env = att_static->att_data.att_env;
                msg->header()->importIMAPEnvelope(env);
                hasHeader = true;
            }
            else if (att_static->att_type == MAILIMAP_MSG_ATT_BODY_SECTION) {
                if ((requestKind & IMAPMessagesRequestKindFullHeaders) != 0 ||
                    (requestKind & IMAPMessagesRequestKindExtraHeaders) != 0) {
                    char * bytes;
                    size_t length;
                    
                    bytes = att_static->att_data.att_body_section->sec_body_part;
                    length = att_static->att_data.att_body_section->sec_length;
                    
                    msg->header()->importHeadersData(Data::dataWithBytes(bytes, (unsigned int) length));
                    hasHeader = true;
                }
                else {
                    char * references;
                    size_t ref_size;
                    
                    // references
                    references = att_static->att_data.att_body_section->sec_body_part;
                    ref_size = att_static->att_data.att_body_section->sec_length;
                    
                    msg->header()->importIMAPReferences(Data::dataWithBytes(references, (unsigned int) ref_size));
                }
            }
            else if (att_static->att_type == MAILIMAP_MSG_ATT_BODYSTRUCTURE) {
                AbstractPart * mainPart;
                
                // bodystructure
                mainPart = IMAPPart::attachmentWithIMAPBody(att_static->att_data.att_body);
                msg->setMainPart(mainPart);
                hasBody = true;
            }
        }
        else if (att_item->att_type == MAILIMAP_MSG_ATT_ITEM_EXTENSION) {
            struct mailimap_extension_data * ext_data;
            
            ext_data = att_item->att_data.att_extension_data;
            if (ext_data->ext_extension == &mailimap_extension_condstore) {
                struct mailimap_condstore_fetch_mod_resp * fetch_data;
                
                fetch_data = (struct mailimap_condstore_fetch_mod_resp *) ext_data->ext_data;
                msg->setModSeqValue(fetch_data->cs_modseq_value);
            }
            else if (ext_data->ext_extension == &mailimap_extension_xgmlabels) {
                struct mailimap_msg_att_xgmlabels * cLabels;
                Array * labels;
                clistiter * cur;
                
                labels = new Array();
                hasGmailLabels = true;
                cLabels = (struct mailimap_msg_att_xgmlabels *) ext_data->ext_data;
                for(cur = clist_begin(cLabels->att_labels) ; cur != NULL ; cur = clist_next(cur)) {
                    char * cLabel;
                    String * label;
                    
                    cLabel = (char *) clist_content(cur);
                    label = String::stringWithUTF8Characters(cLabel);
                    labels->addObject(label);
                }
                if (labels->count() > 0) {
                    msg->setGmailLabels(labels);
                }
                labels->release();
            }
            else if (ext_data->ext_extension == &mailimap_extension_xgmthrid) {
                uint64_t * threadID;
                
                threadID = (uint64_t *) ext_data->ext_data;
                msg->setGmailThreadID(*threadID);
                hasGmailThreadID = true;
            }
            else if (ext_data->ext_extension == &mailimap_extension_xgmmsgid) {
                uint64_t * msgID;
                
                msgID = (uint64_t *) ext_data->ext_data;
                msg->setGmailMessageID(*msgID);
                hasGmailMessageID = true;
            }
        }
    }
    for(item_iter = clist_begin(msg_att->att_list) ; item_iter != NULL ; item_iter = clist_next(item_iter)) {
        struct mailimap_msg_att_item * att_item;
        
        att_item = (struct mailimap_msg_att_item *) clist_content(item_iter);
        if (att_item->att_type == MAILIMAP_MSG_ATT_ITEM_STATIC) {
            struct mailimap_msg_att_static * att_static;
            
            att_static = att_item->att_data.att_static;
            if (att_static->att_type == MAILIMAP_MSG_ATT_INTERNALDATE) {
                msg->header()->importIMAPInternalDate(att_static->att_data.att_internal_date);
            } else if (att_static->att_type == MAILIMAP_MSG_ATT_RFC822_SIZE) {
                msg->setSize(att_static->att_data.att_rfc822_size);
            }
        }
    }
    
    if (needsBody && !hasBody) {
        msg->release();
        return;
    }
    if (needsHeader && !hasHeader) {
        msg->release();
        return;
    }
    if (needsFlags && !hasFlags) {
        msg->release();
        return;
    }
    if (needsGmailThreadID && !hasGmailThreadID) {
        msg->release();
        return;
    }
    if (needsGmailMessageID && !hasGmailMessageID) {
        msg->release();
        return;
    }
    if (needsGmailLabels && !hasGmailLabels) {
        msg->release();
        return;
    }
    if (uid != 0) {
        msg->setUid(uid);
    }
    else {
        msg->release();
        return;
    }

    if (uidsFilter != NULL) {
        if (!uidsFilter->containsIndex((uint64_t) uid)) {
            msg->release();
            return;
        }
    }
    
    result->addObject(msg);
    msg->release();
    
    msg_att_context->mLastFetchedSequenceNumber = mLastFetchedSequenceNumber;
}

IMAPSyncResult * IMAPSession::fetchMessages(String * folder, IMAPMessagesRequestKind requestKind, bool fetchByUID,
                                            struct mailimap_set * imapset, IndexSet * uidsFilter, IndexSet * numbersFilter,
                                            uint64_t modseq, HashMap * mapping,
                                            IMAPProgressCallback * progressCallback, Array * extraHeaders, ErrorCode * pError)
{
    struct mailimap_fetch_type * fetch_type;
    clist * fetch_result;
    struct mailimap_qresync_vanished * vanished;
    struct mailimap_fetch_att * fetch_att;
    int r;
    bool needsHeader;
    bool needsBody;
    bool needsFlags;
    bool needsGmailLabels;
    bool needsGmailMessageID;
    bool needsGmailThreadID;
    Array * messages;
    IndexSet * vanishedMessages;
    
    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return NULL;
    
    if (mNeedsMboxMailWorkaround && ((requestKind & IMAPMessagesRequestKindHeaders) != 0)) {
        requestKind = (IMAPMessagesRequestKind) (requestKind & ~IMAPMessagesRequestKindHeaders);
        requestKind = (IMAPMessagesRequestKind) (requestKind | IMAPMessagesRequestKindFullHeaders);
    }
    if (extraHeaders != NULL) {
        requestKind = (IMAPMessagesRequestKind) (requestKind | IMAPMessagesRequestKindExtraHeaders);
    }
    
    if ((requestKind & IMAPMessagesRequestKindHeaders) != 0) {
        mProgressItemsCount = 0;
        mProgressCallback = progressCallback;
    }
    
    messages = Array::array();
    
    needsHeader = false;
    needsBody = false;
    needsFlags = false;
    needsGmailLabels = false;
    needsGmailMessageID = false;
    needsGmailThreadID = false;
    clist * hdrlist = clist_new();
    
    fetch_type = mailimap_fetch_type_new_fetch_att_list_empty();
    fetch_att = mailimap_fetch_att_new_uid();
    mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
    if ((requestKind & IMAPMessagesRequestKindFlags) != 0) {
        MCLog("request flags");
        fetch_att = mailimap_fetch_att_new_flags();
        mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
        needsFlags = true;
    }
    if ((requestKind & IMAPMessagesRequestKindGmailLabels) != 0) {
        MCLog("request flags");
        fetch_att = mailimap_fetch_att_new_xgmlabels();
        mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
        needsGmailLabels = true;
    }
    if ((requestKind & IMAPMessagesRequestKindGmailThreadID) != 0) {
        fetch_att = mailimap_fetch_att_new_xgmthrid();
        mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
        needsGmailThreadID = true;
    }
    if ((requestKind & IMAPMessagesRequestKindGmailMessageID) != 0) {
        fetch_att = mailimap_fetch_att_new_xgmmsgid();
        mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
        needsGmailMessageID = true;
    }
    if ((requestKind & IMAPMessagesRequestKindFullHeaders) != 0) {
        char * header;
        
        MCLog("request envelope");
        
        // most important header
        header = strdup("Date");
        clist_append(hdrlist, header);
        header = strdup("Subject");
        clist_append(hdrlist, header);
        header = strdup("From");
        clist_append(hdrlist, header);
        header = strdup("Sender");
        clist_append(hdrlist, header);
        header = strdup("Reply-To");
        clist_append(hdrlist, header);
        header = strdup("To");
        clist_append(hdrlist, header);
        header = strdup("Cc");
        clist_append(hdrlist, header);
        header = strdup("Message-ID");
        clist_append(hdrlist, header);
        header = strdup("References");
        clist_append(hdrlist, header);
        header = strdup("In-Reply-To");
        clist_append(hdrlist, header);
    }
    if ((requestKind & IMAPMessagesRequestKindHeaders) != 0) {
        char * header;
        
        MCLog("request envelope");
        // envelope
        fetch_att = mailimap_fetch_att_new_envelope();
        mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
        
        // references header
        header = strdup("References");
        clist_append(hdrlist, header);
        if ((requestKind & IMAPMessagesRequestKindHeaderSubject) != 0) {
            header = strdup("Subject");
            clist_append(hdrlist, header);
        }
    }
    if ((requestKind & IMAPMessagesRequestKindSize) != 0) {
        // message structure
        MCLog("request size");
        fetch_att = mailimap_fetch_att_new_rfc822_size();
        mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
    }
    
    if ((requestKind & IMAPMessagesRequestKindStructure) != 0) {
        // message structure
        MCLog("request bodystructure");
        fetch_att = mailimap_fetch_att_new_bodystructure();
        mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
        needsBody = true;
    }
    if ((requestKind & IMAPMessagesRequestKindInternalDate) != 0) {
        // internal date
        fetch_att = mailimap_fetch_att_new_internaldate();
        mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
    }
    if ((requestKind & IMAPMessagesRequestKindExtraHeaders) != 0) {
        // custom header request
        char * header;
        
        if (extraHeaders && extraHeaders->count() > 0) {
            for (unsigned int i = 0; i < extraHeaders->count(); i++) {
                String * headerString = (String *)extraHeaders->objectAtIndex(i);
                header = strdup(headerString->UTF8Characters());
                clist_append(hdrlist, header);
            }
        }
    }
    
    if (clist_begin(hdrlist) != NULL) {
        struct mailimap_header_list * imap_hdrlist;
        struct mailimap_section * section;
        
        imap_hdrlist = mailimap_header_list_new(hdrlist);
        
        /*
         * If the IMAPRequestKindFullHeaders is set then we have to fetch the full headers 
         * otherwise only the specified list of headers 
         */
        if ((requestKind & IMAPMessagesRequestKindAllHeaders) != 0) {
           section = mailimap_section_new_header();
        } else {
           section = mailimap_section_new_header_fields(imap_hdrlist);
        }

        fetch_att = mailimap_fetch_att_new_body_peek_section(section);
        mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
        needsHeader = true;
    }
    else {
        clist_free(hdrlist);
    }
    
    struct msg_att_handler_data msg_att_data;
    
    memset(&msg_att_data, 0, sizeof(msg_att_data));
    msg_att_data.uidsFilter = uidsFilter;
    msg_att_data.numbersFilter = numbersFilter;
    msg_att_data.fetchByUID = fetchByUID;
    msg_att_data.result = messages;
    msg_att_data.requestKind = requestKind;
    msg_att_data.mLastFetchedSequenceNumber = mLastFetchedSequenceNumber;
    msg_att_data.mapping = mapping;
    msg_att_data.needsHeader = needsHeader;
    msg_att_data.needsBody = needsBody;
    msg_att_data.needsFlags = needsFlags;
    msg_att_data.needsGmailLabels = needsGmailLabels;
    msg_att_data.needsGmailMessageID = needsGmailMessageID;
    msg_att_data.needsGmailThreadID = needsGmailThreadID;
    mailimap_set_msg_att_handler(mImap, msg_att_handler, &msg_att_data);
    
    mBodyProgressEnabled = false;
    vanished = NULL;
    
    if (fetchByUID) {
        if ((modseq != 0) && (mCondstoreEnabled || mQResyncEnabled)) {
            if (mQResyncEnabled) {
                r = mailimap_uid_fetch_qresync(mImap, imapset, fetch_type, modseq,
                                               &fetch_result,  &vanished);
            }
            else { /* condstore */
                r = mailimap_uid_fetch_changedsince(mImap, imapset, fetch_type, modseq,
                                                    &fetch_result);
            }
        }
        else {
            r = mailimap_uid_fetch(mImap, imapset, fetch_type, &fetch_result);
        }
    } else {
        if ((modseq != 0) && (mCondstoreEnabled || mQResyncEnabled)) {
            if (mQResyncEnabled) {
                r = mailimap_fetch_qresync(mImap, imapset, fetch_type, modseq,
                                           &fetch_result,  &vanished);
            }
            else { /* condstore */
                r = mailimap_fetch_changedsince(mImap, imapset, fetch_type, modseq,
                                                &fetch_result);
            }
        }
        else {
            r = mailimap_fetch(mImap, imapset, fetch_type, &fetch_result);
        }
    }
    
    vanishedMessages = NULL;
    if (vanished != NULL) {
        vanishedMessages = indexSetFromSet(vanished->qr_known_uids);
    }
    
    mBodyProgressEnabled = true;
    
    mProgressCallback = NULL;
    
    mLastFetchedSequenceNumber = msg_att_data.mLastFetchedSequenceNumber;
    
    mailimap_fetch_type_free(fetch_type);
    
    mailimap_set_msg_att_handler(mImap, NULL, NULL);
    
    if (r == MAILIMAP_ERROR_STREAM) {
        MCLog("error stream");
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        MCLog("error parse");
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return NULL;
    }
    else if (hasError(r)) {
        MCLog("error fetch");
        * pError = ErrorFetch;
        return NULL;
    }
    
    IMAPSyncResult * result;
    result = new IMAPSyncResult();
    result->setModifiedOrAddedMessages(messages);
    result->setVanishedMessages(vanishedMessages);
    result->autorelease();
    
    if ((requestKind & IMAPMessagesRequestKindHeaders) != 0) {
        if (messages->count() == 0) {
            unsigned int count;
            
            count = clist_count(fetch_result);
            if (count > 0) {
                requestKind = (IMAPMessagesRequestKind) (requestKind & ~IMAPMessagesRequestKindHeaders);
                requestKind = (IMAPMessagesRequestKind) (requestKind | IMAPMessagesRequestKindFullHeaders);

                result = fetchMessages(folder, requestKind, fetchByUID,
                    imapset, uidsFilter, numbersFilter,
                    modseq, NULL, progressCallback, extraHeaders, pError);
                if (result != NULL) {
                    if (result->modifiedOrAddedMessages() != NULL) {
                        if (result->modifiedOrAddedMessages()->count() > 0) {
                            mNeedsMboxMailWorkaround = true;
                        }
                    }
                }
            }
        }
    }
    
    mailimap_fetch_list_free(fetch_result);
    * pError = ErrorNone;
    
    return result;
}

Array * IMAPSession::fetchMessagesByUID(String * folder, IMAPMessagesRequestKind requestKind,
                                        IndexSet * uids, IMAPProgressCallback * progressCallback, ErrorCode * pError)
{
    return fetchMessagesByUIDWithExtraHeaders(folder, requestKind, uids, progressCallback, NULL, pError);
}


Array * IMAPSession::fetchMessagesByUIDWithExtraHeaders(String * folder, IMAPMessagesRequestKind requestKind,
                                                        IndexSet * uids, IMAPProgressCallback * progressCallback,
                                                        Array * extraHeaders, ErrorCode * pError)
{
    struct mailimap_set * imapset = setFromIndexSet(uids);
    IMAPSyncResult * syncResult = fetchMessages(folder, requestKind, true, imapset, uids, NULL, 0, NULL,
                                                progressCallback, extraHeaders, pError);
    if (syncResult == NULL) {
        mailimap_set_free(imapset);
        return NULL;
    }
    Array * result = syncResult->modifiedOrAddedMessages();
    result->retain()->autorelease();
    mailimap_set_free(imapset);
    return result;
}

Array * IMAPSession::fetchMessagesByNumber(String * folder, IMAPMessagesRequestKind requestKind,
                                           IndexSet * numbers, IMAPProgressCallback * progressCallback,
                                           ErrorCode * pError)
{
    return fetchMessagesByNumberWithExtraHeaders(folder, requestKind, numbers, progressCallback, NULL, pError);
}

Array * IMAPSession::fetchMessagesByNumberWithExtraHeaders(String * folder, IMAPMessagesRequestKind requestKind,
                                                           IndexSet * numbers, IMAPProgressCallback * progressCallback,
                                                           Array * extraHeaders, ErrorCode * pError)
{
    struct mailimap_set * imapset = setFromIndexSet(numbers);
    IMAPSyncResult * syncResult = fetchMessages(folder, requestKind, false, imapset, NULL, numbers, 0, NULL,
                                                progressCallback, extraHeaders, pError);
    if (syncResult == NULL) {
        mailimap_set_free(imapset);
        return NULL;
    }
    Array * result = syncResult->modifiedOrAddedMessages();
    result->retain()->autorelease();
    mailimap_set_free(imapset);
    return result;
}

static int fetch_rfc822(mailimap * session, bool identifier_is_uid,
                        uint32_t identifier, char ** result, size_t * result_len)
{
    struct mailimap_section * section;
    struct mailimap_fetch_att * fetch_att;
    struct mailimap_fetch_type * fetch_type;
    
    section = mailimap_section_new(NULL);
    fetch_att = mailimap_fetch_att_new_body_peek_section(section);
    fetch_type = mailimap_fetch_type_new_fetch_att(fetch_att);
    int r = fetch_imap(session, identifier_is_uid, identifier,
                       fetch_type, result, result_len);
    mailimap_fetch_type_free(fetch_type);
    
    return r;
    
#if 0
    int r;
    clist * fetch_list;
    struct mailimap_section * section;
    struct mailimap_fetch_att * fetch_att;
    struct mailimap_fetch_type * fetch_type;
    struct mailimap_set * set;
    struct mailimap_msg_att * msg_att;
    struct mailimap_msg_att_item * item;
    int res;
    clistiter * cur;
    
    section = mailimap_section_new(NULL);
    fetch_att = mailimap_fetch_att_new_body_peek_section(section);
    fetch_type = mailimap_fetch_type_new_fetch_att(fetch_att);
    
    set = mailimap_set_new_single(identifier);
    
    if (identifier_is_uid) {
        r = mailimap_uid_fetch(session, set, fetch_type, &fetch_list);
    }
    else {
        r = mailimap_fetch(session, set, fetch_type, &fetch_list);
    }
    
    mailimap_set_free(set);
    mailimap_fetch_type_free(fetch_type);
    
    if (r != MAILIMAP_NO_ERROR) {
        res = r;
        goto err;
    }
    
    if (clist_isempty(fetch_list)) {
        res = MAILIMAP_ERROR_FETCH;
        goto free;
    }
    
    msg_att = (struct mailimap_msg_att *) clist_begin(fetch_list)->data;
    
    for(cur = clist_begin(msg_att->att_list) ; cur != NULL ; cur = clist_next(cur)) {
        item = (struct mailimap_msg_att_item *) clist_content(cur);
        
        if (item->att_type != MAILIMAP_MSG_ATT_ITEM_STATIC) {
            continue;
        }
        if (item->att_data.att_static->att_type != MAILIMAP_MSG_ATT_BODY_SECTION) {
            continue;
        }
        
        * result = item->att_data.att_static->att_data.att_body_section->sec_body_part;
        item->att_data.att_static->att_data.att_body_section->sec_body_part = NULL;
        mailimap_fetch_list_free(fetch_list);
        
        return MAILIMAP_NO_ERROR;
    }
    
    res = MAILIMAP_ERROR_FETCH;
    
free:
    mailimap_fetch_list_free(fetch_list);
err:
    return res;
#endif
}

Data * IMAPSession::fetchMessageByUID(String * folder, uint32_t uid,
    IMAPProgressCallback * progressCallback, ErrorCode * pError)
{
    return fetchMessage(folder, true, uid, progressCallback, pError);
}

Data * IMAPSession::fetchMessageByNumber(String * folder, uint32_t number,
                                         IMAPProgressCallback * progressCallback, ErrorCode * pError)
{
    return fetchMessage(folder, false, number, progressCallback, pError);
}

Data * IMAPSession::fetchMessage(String * folder, bool identifier_is_uid, uint32_t identifier,
                                 IMAPProgressCallback * progressCallback, ErrorCode * pError)
{
    char * rfc822;
    size_t rfc822_len;
    int r;
    Data * data;
    
    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return NULL;
    
    mProgressItemsCount = 0;
    mProgressCallback = progressCallback;
    
    rfc822 = NULL;
    r = fetch_rfc822(mImap, identifier_is_uid, identifier, &rfc822, &rfc822_len);
    if (r == MAILIMAP_NO_ERROR) {
        size_t len;
        
        len = 0;
        if (rfc822 != NULL) {
            len = strlen(rfc822);
        }
        bodyProgress((unsigned int) len, (unsigned int) len);
    }
    mProgressCallback = NULL;
    
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return NULL;
    }
    else if (hasError(r)) {
        * pError = ErrorFetch;
        return NULL;
    }
    
    if (rfc822 == NULL) {
        data = Data::data();
    }
    else {
        data = Data::dataWithBytes(rfc822, (unsigned int) rfc822_len);
    }
    
    mailimap_nstring_free(rfc822);
    * pError = ErrorNone;
    
    return data;
}

static void nstringDeallocator(char * bytes, unsigned int length) {
    mailimap_nstring_free(bytes);
};

Data * IMAPSession::fetchNonDecodedMessageAttachment(String * folder, bool identifier_is_uid,
                                           uint32_t identifier, String * partID,
                                           bool wholePart, uint32_t offset, uint32_t length,
                                           Encoding encoding, IMAPProgressCallback * progressCallback, ErrorCode * pError)
{
    struct mailimap_fetch_type * fetch_type;
    struct mailimap_fetch_att * fetch_att;
    struct mailimap_section * section;
    struct mailimap_section_part * section_part;
    clist * sec_list;
    Array * partIDArray;
    int r;
    char * text = NULL;
    size_t text_length = 0;
    Data * data;

    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return NULL;

    mProgressItemsCount = 0;
    mProgressCallback = progressCallback;
    bodyProgress(0, 0);

    partIDArray = partID->componentsSeparatedByString(MCSTR("."));
    sec_list = clist_new();
    for(unsigned int i = 0 ; i < partIDArray->count() ; i ++) {
        uint32_t * value;
        String * element;

        element = (String *) partIDArray->objectAtIndex(i);
        value = (uint32_t *) malloc(sizeof(* value));
        * value = element->intValue();
        clist_append(sec_list, value);
    }
    section_part = mailimap_section_part_new(sec_list);
    section = mailimap_section_new_part(section_part);
    if (wholePart) {
        fetch_att = mailimap_fetch_att_new_body_peek_section(section);
    }
    else {
        fetch_att = mailimap_fetch_att_new_body_peek_section_partial(section, offset, length);
    }
    fetch_type = mailimap_fetch_type_new_fetch_att(fetch_att);

#ifdef LIBETPAN_HAS_MAILIMAP_RAMBLER_WORKAROUND
    if (mRamblerRuServer && (encoding == EncodingBase64 || encoding == EncodingUUEncode)) {
        mailimap_set_rambler_workaround_enabled(mImap, 1);
    }
#endif

    r = fetch_imap(mImap, identifier_is_uid, identifier, fetch_type, &text, &text_length);
    mailimap_fetch_type_free(fetch_type);

#ifdef LIBETPAN_HAS_MAILIMAP_RAMBLER_WORKAROUND
    mailimap_set_rambler_workaround_enabled(mImap, 0);
#endif

    mProgressCallback = NULL;
    
    MCLog("had error : %i", r);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return NULL;
    }
    else if (hasError(r)) {
        * pError = ErrorFetch;
        return NULL;
    }

    data = Data::data();
    data->takeBytesOwnership(text, (unsigned int) text_length, nstringDeallocator);
    
    * pError = ErrorNone;
    
    return data;
}

Data * IMAPSession::fetchMessageAttachment(String * folder, bool identifier_is_uid,
                                           uint32_t identifier, String * partID,
                                           Encoding encoding, IMAPProgressCallback * progressCallback, ErrorCode * pError)
{
    Data * data = fetchNonDecodedMessageAttachment(folder, identifier_is_uid, identifier, partID, true, 0, 0, encoding, progressCallback, pError);
    if (data) {
        data = data->decodedDataUsingEncoding(encoding);
    }
    return data;
}

Data * IMAPSession::fetchMessageAttachmentByUID(String * folder, uint32_t uid, String * partID,
                                                Encoding encoding, IMAPProgressCallback * progressCallback, ErrorCode * pError)
{
    return fetchMessageAttachment(folder, true, uid, partID, encoding, progressCallback, pError);
}

Data * IMAPSession::fetchMessageAttachmentByNumber(String * folder, uint32_t number, String * partID,
                                              Encoding encoding, IMAPProgressCallback * progressCallback, ErrorCode * pError)
{
    return fetchMessageAttachment(folder, false, number, partID, encoding, progressCallback, pError);
}

void IMAPSession::fetchMessageAttachmentToFileByChunksByUID(String * folder, uint32_t uid, String * partID,
                                                    uint32_t estimatedSize, Encoding encoding,
                                                    String * outputFile, uint32_t chunkSize,
                                                    IMAPProgressCallback * progressCallback, ErrorCode * pError)
{
    DataStreamDecoder * decoder = new DataStreamDecoder();
    decoder->setEncoding(encoding);
    decoder->setFilename(outputFile);

    int nRetries = 0;
    int const maxRetries = 3;
    ErrorCode error = ErrorNone;
    uint32_t offset = 0;
    while (1) {
        AutoreleasePool * pool = new AutoreleasePool();

        LoadByChunkProgress * chunkProgressCallback = new LoadByChunkProgress();
        chunkProgressCallback->setOffset(offset);
        chunkProgressCallback->setEstimatedSize(estimatedSize);
        chunkProgressCallback->setProgressCallback(progressCallback);

        Data * data = fetchNonDecodedMessageAttachment(folder, true, uid, partID, false, offset, chunkSize, encoding, chunkProgressCallback, &error);

        MC_SAFE_RELEASE(chunkProgressCallback);

        if (error != ErrorNone) {
            pool->release();
            if ((error == ErrorConnection || error == ErrorParse) && nRetries < maxRetries) {
                error = ErrorNone;
                nRetries++;
                continue;
            }
            break;
        } else {
            nRetries = 0;
        }

        if (data == NULL) {
            pool->release();
            break;
        }

        uint32_t encodedSize = data->length();
        if (encodedSize == 0) {
            pool->release();
            break;
        }

        error = decoder->appendData(data);

        pool->release();

        if (error != ErrorNone) {
            break;
        }

        offset += encodedSize;

        // Try detect is this chunk last.
        // Estimated size (extracted from BODYSTRUCTURE info) may be incorrect.
        // Also, server may return chunk with size less than requested.
        // So this detection is some tricky.
        bool endOfPart = ((encodedSize == 0) ||
                          (estimatedSize > 0 && (estimatedSize <= offset) && (encodedSize != chunkSize)) ||
                          (estimatedSize == 0 && encodedSize < chunkSize));
        if (endOfPart) {
            break;
        }
    }

    if (error == ErrorNone) {
        decoder->flushData();
    }

    MC_SAFE_RELEASE(decoder);

    * pError = error;
}

static bool msg_body_handler(int msg_att_type, struct mailimap_msg_att_body_section * section,
                             const char * bytes, size_t len, void * context)
{
    DataStreamDecoder * decoder = (DataStreamDecoder *)context;

    AutoreleasePool * pool = new AutoreleasePool();

    Data * data = Data::dataWithBytes(bytes, (unsigned int) len);
    ErrorCode error = decoder->appendData(data);

    pool->release();

    return error == ErrorNone;
}

void IMAPSession::fetchMessageAttachmentToFileByUID(String * folder, uint32_t uid, String * partID,
                                                    Encoding encoding, String * outputFile,
                                                    IMAPProgressCallback * progressCallback, ErrorCode * pError)
{
    DataStreamDecoder * decoder = new DataStreamDecoder();
    decoder->setEncoding(encoding);
    decoder->setFilename(outputFile);

    ErrorCode error = ErrorNone;
    selectIfNeeded(folder, &error);
    if (error != ErrorNone) {
        * pError = error;
        return;
    }

    mailimap_set_msg_body_handler(mImap, msg_body_handler, decoder);

    fetchNonDecodedMessageAttachment(folder, true, uid, partID, true, 0, 0, encoding, progressCallback, &error);

    mailimap_set_msg_body_handler(mImap, NULL, NULL);

    if (error == ErrorNone) {
        error = decoder->flushData();
    }

    MC_SAFE_RELEASE(decoder);

    * pError = error;
}

IndexSet * IMAPSession::search(String * folder, IMAPSearchKind kind, String * searchString, ErrorCode * pError)
{
    IMAPSearchExpression * expr;
    
    expr = NULL;
    switch (kind) {
        case IMAPSearchKindAll:
        {
            expr = IMAPSearchExpression::searchAll();
            break;
        }
        case IMAPSearchKindFrom:
        {
            expr = IMAPSearchExpression::searchFrom(searchString);
            break;
        }
        case IMAPSearchKindTo:
        {
            expr = IMAPSearchExpression::searchTo(searchString);
            break;
        }
        case IMAPSearchKindCc:
        {
            expr = IMAPSearchExpression::searchCc(searchString);
            break;
        }
        case IMAPSearchKindBcc:
        {
            expr = IMAPSearchExpression::searchBcc(searchString);
            break;
        }
        case IMAPSearchKindRecipient:
        {
            expr = IMAPSearchExpression::searchRecipient(searchString);
            break;
        }
        case IMAPSearchKindSubject:
        {
            expr = IMAPSearchExpression::searchSubject(searchString);
            break;
        }
        case IMAPSearchKindContent:
        {
            expr = IMAPSearchExpression::searchContent(searchString);
            break;
        }
        case IMAPSearchKindBody:
        {
            expr = IMAPSearchExpression::searchBody(searchString);
            break;
        }
        case IMAPSearchKindRead:
        {
            expr = IMAPSearchExpression::searchRead();
            break;
        }
        case IMAPSearchKindUnread:
        {
            expr = IMAPSearchExpression::searchUnread();
            break;
        }
        case IMAPSearchKindFlagged:
        {
            expr = IMAPSearchExpression::searchFlagged();
            break;
        }
        case IMAPSearchKindUnflagged:
        {
            expr = IMAPSearchExpression::searchUnflagged();
            break;
        }
        case IMAPSearchKindAnswered:
        {
            expr = IMAPSearchExpression::searchAnswered();
            break;
        }
        case IMAPSearchKindUnanswered:
        {
            expr = IMAPSearchExpression::searchUnanswered();
            break;
        }
        case IMAPSearchKindDraft:
        {
            expr = IMAPSearchExpression::searchDraft();
            break;
        }
        case IMAPSearchKindUndraft:
        {
            expr = IMAPSearchExpression::searchUndraft();
            break;
        }
        case IMAPSearchKindDeleted:
        {
            expr = IMAPSearchExpression::searchDeleted();
            break;
        }
        case IMAPSearchKindSpam:
        {
            expr = IMAPSearchExpression::searchSpam();
            break;
        }
        default:
        {
            MCAssert(0);
            break;
        }
    }
    return search(folder, expr, pError);
}

static struct mailimap_search_key * searchKeyFromSearchExpression(IMAPSearchExpression * expression)
{
    switch (expression->kind()) {
        case IMAPSearchKindAll:
        {
            return mailimap_search_key_new_all();
        }
        case IMAPSearchKindFrom:
        {
            return mailimap_search_key_new_from(strdup(expression->value()->UTF8Characters()));
        }
        case IMAPSearchKindTo:
        {
            return mailimap_search_key_new_to(strdup(expression->value()->UTF8Characters()));
        }
        case IMAPSearchKindCc:
        {
            return mailimap_search_key_new_cc(strdup(expression->value()->UTF8Characters()));
        }
        case IMAPSearchKindBcc:
        {
            return mailimap_search_key_new_bcc(strdup(expression->value()->UTF8Characters()));
        }
        case IMAPSearchKindRecipient:
        {
            struct mailimap_search_key * to_search;
            struct mailimap_search_key * cc_search;
            struct mailimap_search_key * bcc_search;
            struct mailimap_search_key * or_search1;
            struct mailimap_search_key * or_search2;
            
            to_search = mailimap_search_key_new_to(strdup(expression->value()->UTF8Characters()));
            cc_search = mailimap_search_key_new_cc(strdup(expression->value()->UTF8Characters()));
            bcc_search = mailimap_search_key_new_bcc(strdup(expression->value()->UTF8Characters()));
            
            or_search1 = mailimap_search_key_new_or(to_search, cc_search);
            or_search2 = mailimap_search_key_new_or(or_search1, bcc_search);
            
            return or_search2;
        }
        case IMAPSearchKindSubject:
        {
            return mailimap_search_key_new_subject(strdup(expression->value()->UTF8Characters()));
        }
        case IMAPSearchKindContent:
        {
            return mailimap_search_key_new_text(strdup(expression->value()->UTF8Characters()));
        }
        case IMAPSearchKindBody:
        {
            return mailimap_search_key_new_body(strdup(expression->value()->UTF8Characters()));
        }
        case IMAPSearchKindUIDs:
        {
            return mailimap_search_key_new_uid(setFromIndexSet(expression->uids()));
        }
        case IMAPSearchKindNumbers:
        {
            return mailimap_search_key_new_set(setFromIndexSet(expression->numbers()));
        }
        case IMAPSearchKindHeader:
        {
            return mailimap_search_key_new_header(strdup(expression->header()->UTF8Characters()), strdup(expression->value()->UTF8Characters()));
        }
        case IMAPSearchKindBeforeDate:
        {
            time_t date = expression->date();
            struct tm timeinfo;
            localtime_r(&date, &timeinfo);
            return mailimap_search_key_new_sentbefore(mailimap_date_new(timeinfo.tm_mday, timeinfo.tm_mon+1, timeinfo.tm_year+1900));
        }
        case IMAPSearchKindOnDate:
        {
            time_t date = expression->date();
            struct tm timeinfo;
            localtime_r(&date, &timeinfo);
            return mailimap_search_key_new_senton(mailimap_date_new(timeinfo.tm_mday, timeinfo.tm_mon+1, timeinfo.tm_year+1900));
        }
        case IMAPSearchKindSinceDate:
        {
            time_t date = expression->date();
            struct tm timeinfo;
            localtime_r(&date, &timeinfo);
            return mailimap_search_key_new_sentsince(mailimap_date_new(timeinfo.tm_mday, timeinfo.tm_mon+1, timeinfo.tm_year+1900));
        }
        case IMAPSearchKindBeforeReceivedDate:
        {
            time_t date = expression->date();
            struct tm timeinfo;
            localtime_r(&date, &timeinfo);
            return mailimap_search_key_new_before(mailimap_date_new(timeinfo.tm_mday, timeinfo.tm_mon+1, timeinfo.tm_year+1900));
        }
        case IMAPSearchKindOnReceivedDate:
        {
            time_t date = expression->date();
            struct tm timeinfo;
            localtime_r(&date, &timeinfo);
            return mailimap_search_key_new_on(mailimap_date_new(timeinfo.tm_mday, timeinfo.tm_mon+1, timeinfo.tm_year+1900));
        }
        case IMAPSearchKindSinceReceivedDate:
        {
            time_t date = expression->date();
            struct tm timeinfo;
            localtime_r(&date, &timeinfo);
            return mailimap_search_key_new_since(mailimap_date_new(timeinfo.tm_mday, timeinfo.tm_mon+1, timeinfo.tm_year+1900));
        }
        case IMAPSearchKindGmailThreadID:
        {
            return mailimap_search_key_new_xgmthrid(expression->longNumber());
        }
        case IMAPSearchKindGmailMessageID:
        {
            return mailimap_search_key_new_xgmmsgid(expression->longNumber());
        }
        case IMAPSearchKindRead:
        {
            return mailimap_search_key_new(MAILIMAP_SEARCH_KEY_SEEN, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, 0, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, 0, NULL, NULL, NULL);
        }
        case IMAPSearchKindUnread:
        {
            return mailimap_search_key_new(MAILIMAP_SEARCH_KEY_UNSEEN, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, 0, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, 0, NULL, NULL, NULL);
        }
        case IMAPSearchKindFlagged:
        {
            return mailimap_search_key_new(MAILIMAP_SEARCH_KEY_FLAGGED, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, 0, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, 0, NULL, NULL, NULL);
        }
        case IMAPSearchKindUnflagged:
        {
            return mailimap_search_key_new(MAILIMAP_SEARCH_KEY_UNFLAGGED, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, 0, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, 0, NULL, NULL, NULL);
        }
        case IMAPSearchKindAnswered:
        {
            return mailimap_search_key_new(MAILIMAP_SEARCH_KEY_ANSWERED, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, 0, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, 0, NULL, NULL, NULL);
        }
        case IMAPSearchKindUnanswered:
        {
            return mailimap_search_key_new(MAILIMAP_SEARCH_KEY_UNANSWERED, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, 0, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, 0, NULL, NULL, NULL);
        }
        case IMAPSearchKindDraft:
        {
            return mailimap_search_key_new(MAILIMAP_SEARCH_KEY_DRAFT, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, 0, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, 0, NULL, NULL, NULL);
        }
        case IMAPSearchKindUndraft:
        {
            return mailimap_search_key_new(MAILIMAP_SEARCH_KEY_UNDRAFT, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, 0, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, 0, NULL, NULL, NULL);
        }
        case IMAPSearchKindDeleted:
        {
            return mailimap_search_key_new(MAILIMAP_SEARCH_KEY_DELETED, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, 0, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, 0, NULL, NULL, NULL);
        }
        case IMAPSearchKindSpam:
        {
            return mailimap_search_key_new(MAILIMAP_SEARCH_KEY_KEYWORD, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           strdup("Junk"), NULL, NULL, NULL, NULL, 
                                           NULL, NULL, NULL, NULL, 0, 
                                           NULL, NULL, NULL, NULL, NULL, 
                                           NULL, 0, NULL, NULL, NULL);
        }
        case IMAPSearchKindSizeLarger:
        {
            return mailimap_search_key_new_larger( (uint32_t) expression->longNumber());
        }
        case IMAPSearchKindSizeSmaller:
        {
            return mailimap_search_key_new_smaller( (uint32_t) expression->longNumber());
        }
        case IMAPSearchKindGmailRaw:
        {
            return mailimap_search_key_new_xgmraw(strdup(expression->value()->UTF8Characters()));
        }
        case IMAPSearchKindOr:
        {
            return mailimap_search_key_new_or(searchKeyFromSearchExpression(expression->leftExpression()), searchKeyFromSearchExpression(expression->rightExpression()));
        }
        case IMAPSearchKindAnd:
        {
            clist * list;
            list = clist_new();
            clist_append(list, searchKeyFromSearchExpression(expression->leftExpression()));
            clist_append(list, searchKeyFromSearchExpression(expression->rightExpression()));
            return mailimap_search_key_new_multiple(list);
        }
        case IMAPSearchKindNot:
        {
            return mailimap_search_key_new_not(searchKeyFromSearchExpression(expression->leftExpression()));
        }

        default:
        MCAssert(0);
        return NULL;
    }
}

IndexSet * IMAPSession::search(String * folder, IMAPSearchExpression * expression, ErrorCode * pError)
{
    struct mailimap_search_key * key;
    
    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return NULL;

    clist * result_list = NULL;
    
    const char * charset = "utf-8";
    if (mYahooServer) {
        charset = NULL;
    }
    
    int r;
    key = searchKeyFromSearchExpression(expression);
    if (mIsGmail) {
        r = mailimap_uid_search_literalplus(mImap, charset, key, &result_list);
    }
    else {
        r = mailimap_uid_search(mImap, charset, key, &result_list);
    }
    mailimap_search_key_free(key);
    MCLog("had error : %i", r);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return NULL;
    }
    else if (hasError(r)) {
        * pError = ErrorFetch;
        return NULL;
    }

    IndexSet * result = IndexSet::indexSet();
    for(clistiter * cur = clist_begin(result_list) ; cur != NULL ; cur = clist_next(cur))  {
        uint32_t * uid = (uint32_t *) clist_content(cur);
        result->addIndex(* uid);
    }
    mailimap_search_result_free(result_list);
    * pError = ErrorNone;
    return result;
}

void IMAPSession::getQuota(uint32_t *usage, uint32_t *limit, ErrorCode * pError)
{
    mailimap_quota_complete_data *quota_data;
    
    int r = mailimap_quota_getquotaroot(mImap, "INBOX", &quota_data);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorFetch;
        return;
    }
    for(clistiter * cur = clist_begin(quota_data->quota_list); cur != NULL; cur = clist_next(cur)) {
        mailimap_quota_quota_data *quota = (mailimap_quota_quota_data*)clist_content(cur);
        for (clistiter *cur2 = clist_begin(quota->quota_list); cur2 != NULL; cur2 = clist_next(cur2)) {
            mailimap_quota_quota_resource *res = (mailimap_quota_quota_resource*)clist_content(cur2);
            if (!strcasecmp("STORAGE", res->resource_name)) {
                *usage = res->usage;
                *limit = res->limit;
            }
        }
    }
    mailimap_quota_complete_data_free(quota_data);    
}

bool IMAPSession::setupIdle()
{
    // main thread
    LOCK();
    bool canIdle = mIdleEnabled;
    if (mIdleEnabled) {
        mailstream_setup_idle(mImap->imap_stream);
    }
    UNLOCK();
    return canIdle;
}

void IMAPSession::idle(String * folder, uint32_t lastKnownUID, ErrorCode * pError)
{
    int r;
    
    // connection thread
    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return;
    
    if (lastKnownUID != 0) {
        Array * msgs;
        
        msgs = fetchMessagesByUID(folder, IMAPMessagesRequestKindUid, IndexSet::indexSetWithRange(RangeMake(lastKnownUID, UINT64_MAX)),
                                  NULL, pError);
        if (* pError != ErrorNone)
            return;
        if (msgs->count() > 0) {
            IMAPMessage * msg;
            
            msg = (IMAPMessage *) msgs->objectAtIndex(0);
            if (msg->uid() > lastKnownUID) {
                MCLog("found msg UID %u %u", (unsigned int) msg->uid(), (unsigned int) lastKnownUID);
                return;
            }
        }
    }
    
    r = mailimap_idle(mImap);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorIdle;
        return;
    }
    
    if (!mImap->imap_selection_info->sel_has_exists && !mImap->imap_selection_info->sel_has_recent) {
        int r;
        r = mailstream_wait_idle(mImap->imap_stream, MAX_IDLE_DELAY);
        switch (r) {
            case MAILSTREAM_IDLE_ERROR:
            case MAILSTREAM_IDLE_CANCELLED:
            {
                mShouldDisconnect = true;
                * pError = ErrorConnection;
                MCLog("error or cancelled");
                return;
            }
            case MAILSTREAM_IDLE_INTERRUPTED:
                MCLog("interrupted by user");
                break;
            case MAILSTREAM_IDLE_HASDATA:
                MCLog("something on the socket");
                break;
            case MAILSTREAM_IDLE_TIMEOUT:
                MCLog("idle timeout");
                break;
        }
    }
    else {
        MCLog("found info before idling");
    }
    
    r = mailimap_idle_done(mImap);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorIdle;
        return;
    }
    * pError = ErrorNone;
}

void IMAPSession::interruptIdle()
{
    // main thread
    LOCK();
    if (mIdleEnabled) {
        mailstream_interrupt_idle(mImap->imap_stream);
    }
    UNLOCK();
}

void IMAPSession::unsetupIdle()
{
    // main thread
    LOCK();
    if (mIdleEnabled) {
        mailstream_unsetup_idle(mImap->imap_stream);
    }
    UNLOCK();
}

void IMAPSession::disconnect()
{
    unsetup();
}

IMAPIdentity * IMAPSession::identity(IMAPIdentity * clientIdentity, ErrorCode * pError)
{
    connectIfNeeded(pError);
    if (* pError != ErrorNone)
        return NULL;

    struct mailimap_id_params_list * client_identification;

    client_identification = mailimap_id_params_list_new_empty();

    mc_foreacharray(String, key, clientIdentity->allInfoKeys()) {
        MMAPString * mmap_str_name = mmap_string_new(key->UTF8Characters());
        MMAPString * mmap_str_value = mmap_string_new(clientIdentity->infoForKey(key)->UTF8Characters());
        mmap_string_ref(mmap_str_name);
        mmap_string_ref(mmap_str_value);
        mailimap_id_params_list_add_name_value(client_identification, mmap_str_name->str, mmap_str_value->str);
    }

    int r;
    struct mailimap_id_params_list * server_identification;
    r = mailimap_id(mImap, client_identification, &server_identification);
    mailimap_id_params_list_free(client_identification);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return NULL;
    }
    else if (hasError(r)) {
        * pError = ErrorIdentity;
        return NULL;
    }

    IMAPIdentity * result = new IMAPIdentity();
    
    clistiter * cur;
    for(cur = clist_begin(server_identification->idpa_list) ; cur != NULL ; cur = clist_next(cur)) {
        struct mailimap_id_param * param;

        param = (struct mailimap_id_param *) clist_content(cur);
        
        String * responseKey;
        String * responseValue;
        responseKey = String::stringWithUTF8Characters(param->idpa_name);
        responseValue = String::stringWithUTF8Characters(param->idpa_value);
        result->setInfoForKey(responseKey, responseValue);
    }

    mailimap_id_params_list_free(server_identification);
    * pError = ErrorNone;

    result->autorelease();
    return result;
}

void IMAPSession::bodyProgress(unsigned int current, unsigned int maximum)
{
    if (!mBodyProgressEnabled)
        return;
    
    if (mProgressCallback != NULL) {
        mProgressCallback->bodyProgress(this, current, maximum);
    }
}

void IMAPSession::itemsProgress(unsigned int current, unsigned int maximum)
{
    mProgressItemsCount ++;
    if (mProgressCallback != NULL) {
        mProgressCallback->itemsProgress(this, mProgressItemsCount, maximum);
    }
}

IMAPNamespace * IMAPSession::defaultNamespace()
{
    return mDefaultNamespace;
}

void IMAPSession::setDefaultNamespace(IMAPNamespace * ns)
{
    MC_SAFE_REPLACE_RETAIN(IMAPNamespace, mDefaultNamespace, ns);
}

IMAPIdentity * IMAPSession::serverIdentity()
{
    return mServerIdentity;
}

IMAPIdentity * IMAPSession::clientIdentity()
{
    return mClientIdentity;
}

void IMAPSession::setClientIdentity(IMAPIdentity * identity)
{
    MC_SAFE_REPLACE_COPY(IMAPIdentity, mClientIdentity, identity);
}

HashMap * IMAPSession::fetchNamespace(ErrorCode * pError)
{
    HashMap * result;
    struct mailimap_namespace_data * namespace_data;
    int r;
    
    loginIfNeeded(pError);
    if (* pError != ErrorNone)
        return NULL;
    
    result = HashMap::hashMap();
    r = mailimap_namespace(mImap, &namespace_data);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return NULL;
    }
    else if (hasError(r)) {
        * pError = ErrorNamespace;
        return NULL;
    }
    
    IMAPNamespace * ns;
    
    if (namespace_data->ns_personal != NULL) {
        ns = new IMAPNamespace();
        ns->importIMAPNamespace(namespace_data->ns_personal);
        result->setObjectForKey(IMAPNamespacePersonal, ns);
        ns->release();
    }
    
    if (namespace_data->ns_other != NULL) {
        ns = new IMAPNamespace();
        ns->importIMAPNamespace(namespace_data->ns_other);
        result->setObjectForKey(IMAPNamespaceOther, ns);
        ns->release();
    }
    
    if (namespace_data->ns_shared != NULL) {
        ns = new IMAPNamespace();
        ns->importIMAPNamespace(namespace_data->ns_shared);
        result->setObjectForKey(IMAPNamespaceShared, ns);
        ns->release();
    }
    
    mailimap_namespace_data_free(namespace_data);
    * pError = ErrorNone;
    
    return result;
}

void IMAPSession::storeFlagsByUID(String * folder, IndexSet * uids, IMAPStoreFlagsRequestKind kind, MessageFlag flags, ErrorCode * pError)
{
    this->storeFlagsAndCustomFlagsByUID(folder, uids, kind, flags, NULL, pError);
}

void IMAPSession::storeFlagsAndCustomFlagsByUID(String * folder, IndexSet * uids, IMAPStoreFlagsRequestKind kind, MessageFlag flags, Array * customFlags, ErrorCode * pError)
{
    storeFlagsAndCustomFlags(folder, true, uids, kind, flags, customFlags, pError);
}

void IMAPSession::storeFlagsAndCustomFlags(String * folder, bool identifier_is_uid, IndexSet * identifiers,
                                                      IMAPStoreFlagsRequestKind kind, MessageFlag flags, Array * customFlags, ErrorCode * pError)
{
    struct mailimap_set * imap_set;
    struct mailimap_store_att_flags * store_att_flags;
    struct mailimap_flag_list * flag_list;
    int r;
    clist * setList;

    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return;

    imap_set = setFromIndexSet(identifiers);
    if (clist_count(imap_set->set_list) == 0) {
        mailimap_set_free(imap_set);
        return;
    }

    setList = splitSet(imap_set, 50);

    flag_list = mailimap_flag_list_new_empty();
    if ((flags & MessageFlagSeen) != 0) {
        struct mailimap_flag * f;

        f = mailimap_flag_new_seen();
        mailimap_flag_list_add(flag_list, f);
    }
    if ((flags & MessageFlagAnswered) != 0) {
        struct mailimap_flag * f;

        f = mailimap_flag_new_answered();
        mailimap_flag_list_add(flag_list, f);
    }
    if ((flags & MessageFlagFlagged) != 0) {
        struct mailimap_flag * f;

        f = mailimap_flag_new_flagged();
        mailimap_flag_list_add(flag_list, f);
    }
    if ((flags & MessageFlagDeleted) != 0) {
        struct mailimap_flag * f;

        f = mailimap_flag_new_deleted();
        mailimap_flag_list_add(flag_list, f);
    }
    if ((flags & MessageFlagDraft) != 0) {
        struct mailimap_flag * f;

        f = mailimap_flag_new_draft();
        mailimap_flag_list_add(flag_list, f);
    }
    if ((flags & MessageFlagMDNSent) != 0) {
        struct mailimap_flag * f;

        f = mailimap_flag_new_flag_keyword(strdup("$MDNSent"));
        mailimap_flag_list_add(flag_list, f);
    }
    if ((flags & MessageFlagForwarded) != 0) {
        struct mailimap_flag * f;

        f = mailimap_flag_new_flag_keyword(strdup("$Forwarded"));
        mailimap_flag_list_add(flag_list, f);
    }
    if ((flags & MessageFlagSubmitPending) != 0) {
        struct mailimap_flag * f;

        f = mailimap_flag_new_flag_keyword(strdup("$SubmitPending"));
        mailimap_flag_list_add(flag_list, f);
    }
    if ((flags & MessageFlagSubmitted) != 0) {
        struct mailimap_flag * f;
        
        f = mailimap_flag_new_flag_keyword(strdup("$Submitted"));
        mailimap_flag_list_add(flag_list, f);
    }
    
    if (customFlags != NULL) {
        for (unsigned int i = 0 ; i < customFlags->count() ; i ++) {
            struct mailimap_flag * f;
            String * customFlag = (String *) customFlags->objectAtIndex(i);
            
            f = mailimap_flag_new_flag_keyword(strdup(customFlag->UTF8Characters()));
            mailimap_flag_list_add(flag_list, f);
        }
    }

    store_att_flags = NULL;
    for(clistiter * iter = clist_begin(setList) ; iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_set * current_set;

        current_set = (struct mailimap_set *) clist_content(iter);

        switch (kind) {
            case IMAPStoreFlagsRequestKindRemove:
            store_att_flags = mailimap_store_att_flags_new_remove_flags_silent(flag_list);
            break;
            case IMAPStoreFlagsRequestKindAdd:
            store_att_flags = mailimap_store_att_flags_new_add_flags_silent(flag_list);
            break;
            case IMAPStoreFlagsRequestKindSet:
            store_att_flags = mailimap_store_att_flags_new_set_flags_silent(flag_list);
            break;
        }

#ifdef LIBETPAN_HAS_MAILIMAP_QIP_WORKAROUND
        if (mQipServer) {
            mailimap_set_qip_workaround_enabled(mImap, 1);
        }
#endif

        if (identifier_is_uid) {
            r = mailimap_uid_store(mImap, current_set, store_att_flags);
        }
        else {
            r = mailimap_store(mImap, current_set, store_att_flags);
        }

#ifdef LIBETPAN_HAS_MAILIMAP_QIP_WORKAROUND
        mailimap_set_qip_workaround_enabled(mImap, 0);
#endif

        if (r == MAILIMAP_ERROR_STREAM) {
            mShouldDisconnect = true;
            * pError = ErrorConnection;
            goto release;
        }
        else if (r == MAILIMAP_ERROR_PARSE) {
            mShouldDisconnect = true;
            * pError = ErrorParse;
            goto release;
        }
        else if (hasError(r)) {
            * pError = ErrorStore;
            goto release;
        }
    }
    * pError = ErrorNone;

    release:
    for(clistiter * iter = clist_begin(setList) ; iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_set * current_set;

        current_set = (struct mailimap_set *) clist_content(iter);
        mailimap_set_free(current_set);
    }
    clist_free(setList);
    mailimap_store_att_flags_free(store_att_flags);
    mailimap_set_free(imap_set);
}

void IMAPSession::storeFlagsByNumber(String * folder, IndexSet * numbers, IMAPStoreFlagsRequestKind kind, MessageFlag flags, ErrorCode * pError)
{
    this->storeFlagsAndCustomFlagsByNumber(folder, numbers, kind, flags, NULL, pError);
}

void IMAPSession::storeFlagsAndCustomFlagsByNumber(String * folder, IndexSet * numbers, IMAPStoreFlagsRequestKind kind, MessageFlag flags, Array * customFlags, ErrorCode * pError)
{
    storeFlagsAndCustomFlags(folder, false, numbers, kind, flags, customFlags, pError);
}

void IMAPSession::storeLabelsByUID(String * folder, IndexSet * uids, IMAPStoreFlagsRequestKind kind, Array * labels, ErrorCode * pError)
{
    storeLabels(folder, true, uids, kind, labels, pError);
}

void IMAPSession::storeLabelsByNumber(String * folder, IndexSet * numbers, IMAPStoreFlagsRequestKind kind, Array * labels, ErrorCode * pError)
{
    storeLabels(folder, false, numbers, kind, labels, pError);
}

void IMAPSession::storeLabels(String * folder, bool identifier_is_uid, IndexSet * identifiers, IMAPStoreFlagsRequestKind kind, Array * labels, ErrorCode * pError)
{
    struct mailimap_set * imap_set;
    struct mailimap_msg_att_xgmlabels * xgmlabels;
    int r;
    clist * setList;

    selectIfNeeded(folder, pError);
    if (* pError != ErrorNone)
        return;

    imap_set = setFromIndexSet(identifiers);
    if (clist_count(imap_set->set_list) == 0) {
        mailimap_set_free(imap_set);
        return;
    }

    setList = splitSet(imap_set, 10);

    xgmlabels = mailimap_msg_att_xgmlabels_new_empty();
    for(unsigned int i = 0 ; i < labels->count() ; i ++) {
        String * label = (String *) labels->objectAtIndex(i);
        mailimap_msg_att_xgmlabels_add(xgmlabels, strdup(label->UTF8Characters()));
    }

    for(clistiter * iter = clist_begin(setList) ; iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_set * current_set;
        int fl_sign;

        current_set = (struct mailimap_set *) clist_content(iter);

        switch (kind) {
            case IMAPStoreFlagsRequestKindRemove:
            fl_sign = -1;
            break;
            case IMAPStoreFlagsRequestKindAdd:
            fl_sign = 1;
            break;
            case IMAPStoreFlagsRequestKindSet:
            fl_sign = 0;
            break;
        }
        if (identifier_is_uid) {
            r = mailimap_uid_store_xgmlabels(mImap, current_set, fl_sign, 1, xgmlabels);
        }
        else {
            r = mailimap_store_xgmlabels(mImap, current_set, fl_sign, 1, xgmlabels);
        }
        if (r == MAILIMAP_ERROR_STREAM) {
            mShouldDisconnect = true;
            * pError = ErrorConnection;
            goto release;
        }
        else if (r == MAILIMAP_ERROR_PARSE) {
            mShouldDisconnect = true;
            * pError = ErrorParse;
            goto release;
        }
        else if (hasError(r)) {
            * pError = ErrorStore;
            goto release;
        }
    }
    * pError = ErrorNone;

    release:
    for(clistiter * iter = clist_begin(setList) ; iter != NULL ; iter = clist_next(iter)) {
        struct mailimap_set * current_set;

        current_set = (struct mailimap_set *) clist_content(iter);
        mailimap_set_free(current_set);
    }
    clist_free(setList);
    mailimap_msg_att_xgmlabels_free(xgmlabels);
    mailimap_set_free(imap_set);
}

uint32_t IMAPSession::uidValidity()
{
    return mUIDValidity;
}

uint32_t IMAPSession::uidNext()
{
    return mUIDNext;
}

uint64_t IMAPSession::modSequenceValue()
{
    return mModSequenceValue;
}

unsigned int IMAPSession::lastFolderMessageCount()
{
    return mFolderMsgCount;
}

uint32_t IMAPSession::firstUnseenUid()
{
    return mFirstUnseenUid;
}

IMAPSyncResult * IMAPSession::syncMessagesByUID(String * folder, IMAPMessagesRequestKind requestKind,
                                                IndexSet * uids, uint64_t modseq,
                                                IMAPProgressCallback * progressCallback, ErrorCode * pError)
{
    return syncMessagesByUIDWithExtraHeaders(folder, requestKind, uids, modseq, progressCallback, NULL, pError);
}

IMAPSyncResult * IMAPSession::syncMessagesByUIDWithExtraHeaders(String * folder, IMAPMessagesRequestKind requestKind,
                                                IndexSet * uids, uint64_t modseq,
                                                IMAPProgressCallback * progressCallback, Array * extraHeaders,
                                                ErrorCode * pError)
{
    struct mailimap_set * imapset = setFromIndexSet(uids);
    IMAPSyncResult * result = fetchMessages(folder, requestKind, true, imapset,
                                            uids, NULL,
                                            modseq, NULL,
                                            progressCallback, extraHeaders, pError);
    mailimap_set_free(imapset);
    return result;

}

IndexSet * IMAPSession::capability(ErrorCode * pError)
{
    int r;
    struct mailimap_capability_data * cap;
    
    connectIfNeeded(pError);
    if (* pError != ErrorNone)
        return NULL;
    
    r = mailimap_capability(mImap, &cap);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return NULL;
    }
    else if (hasError(r)) {
        * pError = ErrorCapability;
        return NULL;
    }
    
    mailimap_capability_data_free(cap);
    
    IndexSet * result = new IndexSet();
    capabilitySetWithSessionState(result);
    
    * pError = ErrorNone;
    result->autorelease();
    return result;
}

void IMAPSession::capabilitySetWithSessionState(IndexSet * capabilities)
{
    if (mailimap_has_extension(mImap, (char *)"STARTTLS")) {
        capabilities->addIndex(IMAPCapabilityStartTLS);
    }
    if (mailimap_has_authentication(mImap, (char *)"PLAIN")) {
        capabilities->addIndex(IMAPCapabilityAuthPlain);
    }
    if (mailimap_has_authentication(mImap, (char *)"LOGIN")) {
        capabilities->addIndex(IMAPCapabilityAuthLogin);
    }
    if (mailimap_has_idle(mImap)) {
        capabilities->addIndex(IMAPCapabilityIdle);
    }
    if (mailimap_has_id(mImap)) {
        capabilities->addIndex(IMAPCapabilityId);
    }
    if (mailimap_has_xlist(mImap)) {
        capabilities->addIndex(IMAPCapabilityXList);
    }
    if (mailimap_has_extension(mImap, (char *) "X-GM-EXT-1")) {
        // Disable use of XLIST if this is the Gmail IMAP server because it implements
        // RFC 6154.
        capabilities->addIndex(IMAPCapabilityGmail);
    }
    if (mailimap_has_condstore(mImap)) {
        capabilities->addIndex(IMAPCapabilityCondstore);
    }
    if (mailimap_has_qresync(mImap)) {
        capabilities->addIndex(IMAPCapabilityQResync);
    }
    if (mailimap_has_xoauth2(mImap)) {
        capabilities->addIndex(IMAPCapabilityXOAuth2);
    }
    if (mailimap_has_namespace(mImap)) {
        capabilities->addIndex(IMAPCapabilityNamespace);
    }
    if (mailimap_has_compress_deflate(mImap)) {
        capabilities->addIndex(IMAPCapabilityCompressDeflate);
    }
    if (mailimap_has_extension(mImap, (char *)"CHILDREN")) {
        capabilities->addIndex(IMAPCapabilityChildren);
    }
    if (mailimap_has_extension(mImap, (char *)"MOVE")) {
        capabilities->addIndex(IMAPCapabilityMove);
    }
    if (mailimap_has_extension(mImap, (char *)"XYMHIGHESTMODSEQ")) {
        capabilities->addIndex(IMAPCapabilityXYMHighestModseq);
    }
    if (mailimap_has_uidplus(mImap)) {
        capabilities->addIndex(IMAPCapabilityUIDPlus);
    }
    if (mailimap_has_acl(mImap)) {
        capabilities->addIndex(IMAPCapabilityACL);
    }
    if (mailimap_has_enable(mImap)) {
        capabilities->addIndex(IMAPCapabilityEnable);
    }
    applyCapabilities(capabilities);
}

IndexSet * IMAPSession::storedCapabilities() {
    if (mImap == NULL ||
        mImap->imap_connection_info == NULL ||
        mImap->imap_connection_info->imap_capability == NULL) {
        return NULL;
    }
    IndexSet *result = new IndexSet();
    capabilitySetWithSessionState(result);
    result->autorelease();
    return result;
}

void IMAPSession::applyCapabilities(IndexSet * capabilities)
{
    if (capabilities->containsIndex(IMAPCapabilityId)) {
        mIdentityEnabled = true;
    }
    if (capabilities->containsIndex(IMAPCapabilityXList)) {
        mXListEnabled = true;
    }
    if (capabilities->containsIndex(IMAPCapabilityGmail)) {
        mXListEnabled = false;
        mIsGmail = true;
    }
    if (capabilities->containsIndex(IMAPCapabilityIdle)) {
        LOCK();
        mIdleEnabled = true;
        UNLOCK();
    }
    if (capabilities->containsIndex(IMAPCapabilityCondstore)) {
        mCondstoreEnabled = true;
    }
    if (capabilities->containsIndex(IMAPCapabilityQResync)) {
        mQResyncEnabled = true;
    }
    if (capabilities->containsIndex(IMAPCapabilityXYMHighestModseq)) {
        mXYMHighestModseqEnabled = true;
    }
    if (capabilities->containsIndex(IMAPCapabilityXOAuth2)) {
        mXOauth2Enabled = true;
    }
    if (mHermesServer) {
        // Hermes server improperly advertise a namespace capability.
    }
    else {
        if (capabilities->containsIndex(IMAPCapabilityNamespace)) {
            mNamespaceEnabled = true;
        }
    }
    if (capabilities->containsIndex(IMAPCapabilityCompressDeflate)) {
        mCompressionEnabled = true;
    }
}

bool IMAPSession::isIdleEnabled()
{
    LOCK();
    bool idleEnabled = mIdleEnabled;
    UNLOCK();
    return idleEnabled;
}

bool IMAPSession::isXListEnabled()
{
    return mXListEnabled;
}

bool IMAPSession::isCondstoreEnabled()
{
    return mCondstoreEnabled;
}

bool IMAPSession::isQResyncEnabled()
{
    return mQResyncEnabled;
}

bool IMAPSession::isIdentityEnabled()
{
    return mIdentityEnabled;
}

bool IMAPSession::isXOAuthEnabled()
{
    return mXOauth2Enabled;
}

bool IMAPSession::isNamespaceEnabled()
{
    return mNamespaceEnabled;
}

bool IMAPSession::isCompressionEnabled()
{
    return mCompressionEnabled;
}

bool IMAPSession::allowsNewPermanentFlags() {
    return mAllowsNewPermanentFlags;
}

bool IMAPSession::isDisconnected()
{
    return mState == STATE_DISCONNECTED;
}

void IMAPSession::setConnectionLogger(ConnectionLogger * logger)
{
    lockConnectionLogger();
    mConnectionLogger = logger;
    unlockConnectionLogger();
}

ConnectionLogger * IMAPSession::connectionLogger()
{
    ConnectionLogger * result;

    lockConnectionLogger();
    result = mConnectionLogger;
    unlockConnectionLogger();

    return result;
}

void IMAPSession::lockConnectionLogger()
{
    pthread_mutex_lock(&mConnectionLoggerLock);
}

void IMAPSession::unlockConnectionLogger()
{
    pthread_mutex_unlock(&mConnectionLoggerLock);
}

ConnectionLogger * IMAPSession::connectionLoggerNoLock()
{
    return mConnectionLogger;
}

String * IMAPSession::htmlRendering(IMAPMessage * message, String * folder, ErrorCode * pError)
{
    HTMLRendererIMAPDataCallback * dataCallback = new HTMLRendererIMAPDataCallback(this, message->uid());
    String * htmlString = HTMLRenderer::htmlForIMAPMessage(folder,
                                                           message,
                                                           dataCallback,
                                                           NULL);
    * pError = dataCallback->error();
    
    MC_SAFE_RELEASE(dataCallback);

    if (* pError != ErrorNone) {
        return NULL;
    }
    
    return htmlString;
}

String * IMAPSession::htmlBodyRendering(IMAPMessage * message, String * folder, ErrorCode * pError)
{
    MCAssert(folder != NULL);
    HTMLRendererIMAPDataCallback * dataCallback = new HTMLRendererIMAPDataCallback(this, message->uid());
    HTMLBodyRendererTemplateCallback * htmlCallback = new HTMLBodyRendererTemplateCallback();
    
    String * htmlBodyString = HTMLRenderer::htmlForIMAPMessage(folder,
                                                               message,
                                                               dataCallback,
                                                               htmlCallback);

    * pError = dataCallback->error();
    
    MC_SAFE_RELEASE(dataCallback);
    MC_SAFE_RELEASE(htmlCallback);

    if (* pError != ErrorNone) {
        return NULL;
    }
    
    return htmlBodyString;
}

String * IMAPSession::plainTextRendering(IMAPMessage * message, String * folder, ErrorCode * pError)
{
    String * htmlString = htmlRendering(message, folder, pError);
    
    if (* pError != ErrorNone) {
        return NULL;
    }
    
    String * plainTextString = htmlString->flattenHTML();
    return plainTextString;
}

String * IMAPSession::plainTextBodyRendering(IMAPMessage * message, String * folder, bool stripWhitespace, ErrorCode * pError)
{
    MCAssert(folder != NULL);
    String * htmlBodyString = htmlBodyRendering(message, folder, pError);
    
    if (* pError != ErrorNone) {
        return NULL;
    }
    
    String * plainTextBodyString = htmlBodyString->flattenHTML();
    if (stripWhitespace) {
        return plainTextBodyString->stripWhitespace();
    }
    
    return plainTextBodyString;
}

void IMAPSession::setAutomaticConfigurationEnabled(bool enabled)
{
    mAutomaticConfigurationEnabled = enabled;
}

bool IMAPSession::isAutomaticConfigurationEnabled()
{
    return mAutomaticConfigurationEnabled;
}

bool IMAPSession::enableFeature(String * feature)
{
    struct mailimap_capability_data * caps;
    clist * cap_list;
    struct mailimap_capability * cap;
    int r;
    
    cap_list = clist_new();
    cap = mailimap_capability_new(MAILIMAP_CAPABILITY_NAME, NULL, strdup(MCUTF8(feature)));
    clist_append(cap_list, cap);
    caps = mailimap_capability_data_new(cap_list);
    
    struct mailimap_capability_data * result;
    r = mailimap_enable(mImap, caps, &result);
    mailimap_capability_data_free(caps);
    if (r != MAILIMAP_NO_ERROR)
        return false;
    
    mailimap_capability_data_free(result);
    
    return true;
}

void IMAPSession::enableFeatures()
{
    if (isCompressionEnabled()) {
        ErrorCode error;
        enableCompression(&error);
        if (error != ErrorNone) {
            MCLog("could not enable compression");
        }
    }
    
    if (isQResyncEnabled()) {
        enableFeature(MCSTR("QRESYNC"));
    }
    else if (isCondstoreEnabled()) {
        enableFeature(MCSTR("CONDSTORE"));
    }
}

void IMAPSession::enableCompression(ErrorCode * pError)
{
    int r;
    r = mailimap_compress(mImap);
    if (r == MAILIMAP_ERROR_STREAM) {
        mShouldDisconnect = true;
        * pError = ErrorConnection;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        mShouldDisconnect = true;
        * pError = ErrorParse;
        return;
    }
    else if (hasError(r)) {
        * pError = ErrorCompression;
        return;
    }
    
    * pError = ErrorNone;
}

bool IMAPSession::isAutomaticConfigurationDone()
{
    return mAutomaticConfigurationDone;
}

void IMAPSession::resetAutomaticConfigurationDone()
{
    mAutomaticConfigurationDone = false;
}

String * IMAPSession::gmailUserDisplayName()
{
    return mGmailUserDisplayName;
}
