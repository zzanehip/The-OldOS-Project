#include "MCWin32.h" // should be included first.

#include "MCPOPSession.h"

#include <string.h>
#include <libetpan/libetpan.h>

#include "MCPOPMessageInfo.h"
#include "MCPOPProgressCallback.h"
#include "MCMessageHeader.h"
#include "MCConnectionLoggerUtils.h"
#include "MCCertificateUtils.h"

using namespace mailcore;

enum {
    STATE_DISCONNECTED,
    STATE_CONNECTED,
    STATE_LOGGEDIN,
    STATE_LISTED,
};

void POPSession::init()
{
    mHostname = NULL;
    mPort = 0;
    mUsername = NULL;
    mPassword = NULL;
    mAuthType = AuthTypeSASLNone;
    mConnectionType = ConnectionTypeClear;
    mCheckCertificateEnabled = true;
    mTimeout = 30;
    
    mPop = NULL;
    mCapabilities = POPCapabilityNone;
    mProgressCallback = NULL;
    mState = STATE_DISCONNECTED;
    mConnectionLogger = NULL;
    pthread_mutex_init(&mConnectionLoggerLock, NULL);
}

POPSession::POPSession()
{
    init();
}

POPSession::~POPSession()
{
    pthread_mutex_destroy(&mConnectionLoggerLock);
    MC_SAFE_RELEASE(mHostname);
    MC_SAFE_RELEASE(mUsername);
    MC_SAFE_RELEASE(mPassword);
}

void POPSession::setHostname(String * hostname)
{
    MC_SAFE_REPLACE_COPY(String, mHostname, hostname);
}

String * POPSession::hostname()
{
    return mHostname;
}

void POPSession::setPort(unsigned int port)
{
    mPort = port;
}

unsigned int POPSession::port()
{
    return mPort;
}

void POPSession::setUsername(String * username)
{
    MC_SAFE_REPLACE_COPY(String, mUsername, username);
}

String * POPSession::username()
{
    return mUsername;
}

void POPSession::setPassword(String * password)
{
    MC_SAFE_REPLACE_COPY(String, mPassword, password);
}

String * POPSession::password()
{
    return mPassword;
}

void POPSession::setAuthType(AuthType authType)
{
    mAuthType = authType;
}

AuthType POPSession::authType()
{
    return mAuthType;
}

void POPSession::setConnectionType(ConnectionType connectionType)
{
    mConnectionType = connectionType;
}

ConnectionType POPSession::connectionType()
{
    return mConnectionType;
}

void POPSession::setTimeout(time_t timeout)
{
    mTimeout = timeout;
}

time_t POPSession::timeout()
{
    return mTimeout;
}

void POPSession::setCheckCertificateEnabled(bool enabled)
{
    mCheckCertificateEnabled = enabled;
}

bool POPSession::isCheckCertificateEnabled()
{
    return mCheckCertificateEnabled;
}

bool POPSession::checkCertificate()
{
    if (!isCheckCertificateEnabled())
        return true;
    return mailcore::checkCertificate(mPop->pop3_stream, hostname());
}

void POPSession::bodyProgress(unsigned int current, unsigned int maximum)
{
    if (mProgressCallback != NULL) {
        mProgressCallback->bodyProgress(this, current, maximum);
    }
}

void POPSession::body_progress(size_t current, size_t maximum, void * context)
{
    POPSession * session;
    
    session = (POPSession *) context;
    session->bodyProgress((unsigned int) current, (unsigned int) maximum);
}

static void logger(mailpop3 * pop3, int log_type, const char * buffer, size_t size, void * context)
{
    POPSession * session = (POPSession *) context;
    session->lockConnectionLogger();

    if (session->connectionLoggerNoLock() == NULL) {
        session->unlockConnectionLogger();
        return;
    }
    
    ConnectionLogType type = getConnectionType(log_type);
    bool isBuffer = isBufferFromLogType(log_type);
    
    if (isBuffer) {
        Data * data = Data::dataWithBytes(buffer, (unsigned int) size);
        session->connectionLoggerNoLock()->log(session, type, data);
    }
    else {
        session->connectionLoggerNoLock()->log(session, type, NULL);
    }
    session->unlockConnectionLogger();
}

void POPSession::setup()
{
    mPop = mailpop3_new(0, NULL);
    mailpop3_set_timeout(mPop, timeout());
    mailpop3_set_progress_callback(mPop, POPSession::body_progress, this);
    mailpop3_set_logger(mPop, logger, this);
}

void POPSession::unsetup()
{
    if (mPop != NULL) {
        if (mPop->pop3_stream != NULL) {
            mailstream_close(mPop->pop3_stream);
            mPop->pop3_stream = NULL;
        }
        mailpop3_free(mPop);
        mPop = NULL;
    }
}

void POPSession::connectIfNeeded(ErrorCode * pError)
{
    if (mState == STATE_DISCONNECTED) {
        connect(pError);
    }
    else {
        * pError = ErrorNone;
    }
}

void POPSession::connect(ErrorCode * pError)
{
    int r;

    setup();
    
    switch (mConnectionType) {
        case ConnectionTypeStartTLS:
        MCLog("connect %s %u", MCUTF8(hostname()), (unsigned int) port());
        r = mailpop3_socket_connect(mPop, MCUTF8(hostname()), port());
        if (r != MAILPOP3_NO_ERROR) {
            * pError = ErrorConnection;
            return;
        }

        MCLog("start TLS");
        r = mailpop3_socket_starttls(mPop);
        if (r != MAILPOP3_NO_ERROR) {
            * pError = ErrorStartTLSNotAvailable;
            return;
        }
        MCLog("done");
        if (!checkCertificate()) {
            * pError = ErrorCertificate;
            return;
        }
        break;

        case ConnectionTypeTLS:
        MCLog("connect %s %u", MCUTF8(hostname()), (unsigned int) port());
        r = mailpop3_ssl_connect(mPop, MCUTF8(hostname()), port());
        if (r != MAILPOP3_NO_ERROR) {
            * pError = ErrorConnection;
            return;
        }
        if (!checkCertificate()) {
            * pError = ErrorCertificate;
            return;
        }
        break;

        default:
        r = mailpop3_socket_connect(mPop, MCUTF8(hostname()), port());
        if (r != MAILPOP3_NO_ERROR) {
            * pError = ErrorConnection;
            return;
        }
        break;
    }

    mailstream_low * low;
    String * identifierString;
    char * identifier;

    low = mailstream_get_low(mPop->pop3_stream);
    if (mUsername != NULL) {
        identifierString = String::stringWithUTF8Format("%s@%s:%u", MCUTF8(mUsername), MCUTF8(mHostname), mPort);
    }
    else {
        identifierString = String::stringWithUTF8Format("%s:%u", MCUTF8(mUsername), mPort);
    }
    identifier = strdup(identifierString->UTF8Characters());
    mailstream_low_set_identifier(low, identifier);
    mState = STATE_CONNECTED;
    * pError = ErrorNone;
}

void POPSession::disconnect()
{
    if (mPop == NULL)
        return;
    
    mailpop3_quit(mPop);
    mState = STATE_DISCONNECTED;
    unsetup();
}

void POPSession::loginIfNeeded(ErrorCode * pError)
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

void POPSession::login(ErrorCode * pError)
{
    int r;
    const char * utf8username;
    const char * utf8password;

    utf8username = MCUTF8(username());
    utf8password = MCUTF8(password());
    if (utf8username == NULL) {
        utf8username = "";
    }
    if (utf8password == NULL) {
        utf8password = "";
    }

    switch (authType()) {
        case 0:
        default:
        r = mailpop3_user(mPop, utf8username);
        if (r == MAILPOP3_ERROR_STREAM) {
            * pError = ErrorConnection;
            return;
        }
        else if (r != MAILPOP3_NO_ERROR) {
            * pError = ErrorAuthentication;
            return;
        }
            
        r = mailpop3_pass(mPop, utf8password);
        break;
            
        case AuthTypeSASLCRAMMD5:
        r = mailpop3_auth(mPop, "CRAM-MD5",
            MCUTF8(hostname()),
            NULL,
            NULL,
            utf8username, utf8username,
            utf8password, NULL);
        break;
            
        case AuthTypeSASLPlain:
        r = mailpop3_auth(mPop, "PLAIN",
            MCUTF8(hostname()),
            NULL,
            NULL,
            utf8username, utf8username,
            utf8password, NULL);
        break;
            
        case AuthTypeSASLGSSAPI:
            // needs to be tested
        r = mailpop3_auth(mPop, "GSSAPI",
            MCUTF8(hostname()),
            NULL,
            NULL,
            utf8username, utf8username,
            utf8password, NULL /* realm */);
        break;
            
        case AuthTypeSASLDIGESTMD5:
        r = mailpop3_auth(mPop, "DIGEST-MD5",
            MCUTF8(hostname()),
            NULL,
            NULL,
            utf8username, utf8username,
            utf8password, NULL);
        break;
            
        case AuthTypeSASLLogin:
        r = mailpop3_auth(mPop, "LOGIN",
            MCUTF8(hostname()),
            NULL,
            NULL,
            utf8username, utf8username,
            utf8password, NULL);
        break;
            
        case AuthTypeSASLSRP:
        r = mailpop3_auth(mPop, "SRP",
            MCUTF8(hostname()),
            NULL,
            NULL,
            utf8username, utf8username,
            utf8password, NULL);
        break;
            
        case AuthTypeSASLNTLM:
        r = mailpop3_auth(mPop, "NTLM",
            MCUTF8(hostname()),
            NULL,
            NULL,
            utf8username, utf8username,
            utf8password, NULL /* realm */);
        break;
            
        case AuthTypeSASLKerberosV4:
        r = mailpop3_auth(mPop, "KERBEROS_V4",
            MCUTF8(hostname()),
            NULL,
            NULL,
            utf8username, utf8username,
            utf8password, NULL /* realm */);
        break;
    }
    if (r == MAILPOP3_ERROR_STREAM) {
        * pError = ErrorConnection;
        return;
    }
    else if (r != MAILPOP3_NO_ERROR) {
        * pError = ErrorAuthentication;
        return;
    }
    
    mState = STATE_LOGGEDIN;
    * pError = ErrorNone;
}

Array * POPSession::fetchMessages(ErrorCode * pError)
{
    int r;
    carray * msg_list;
    
    loginIfNeeded(pError);
    if (* pError != ErrorNone) {
        return NULL;
    }
    
    r = mailpop3_list(mPop, &msg_list);
    if (r == MAILPOP3_ERROR_STREAM) {
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r != MAILPOP3_NO_ERROR) {
        * pError = ErrorFetchMessageList;
        return NULL;
    }
    
    Array * result = Array::array();
    for(unsigned int i = 0 ; i < carray_count(msg_list) ; i ++) {
        struct mailpop3_msg_info * msg_info;
        String * uid;
        
        msg_info = (struct mailpop3_msg_info *) carray_get(msg_list, i);
        if (msg_info->msg_uidl == NULL)
            continue;
        
        uid = String::stringWithUTF8Characters(msg_info->msg_uidl);
        
        POPMessageInfo * info = new POPMessageInfo();
        info->setUid(uid);
        info->setSize(msg_info->msg_size);
        info->setIndex(msg_info->msg_index);
        result->addObject(info);
        info->release();
    }
    
    * pError = ErrorNone;
    mState = STATE_LISTED;
    
    return result;
}

void POPSession::listIfNeeded(ErrorCode * pError)
{
    if (mState == STATE_LISTED) {
        * pError = ErrorNone;
        return;
    }
    
    fetchMessages(pError);
}

MessageHeader * POPSession::fetchHeader(unsigned int index, ErrorCode * pError)
{
    int r;
    char * content;
    size_t content_len;
    
    listIfNeeded(pError);
    if (* pError != ErrorNone) {
        return NULL;
    }
    
    r = mailpop3_top(mPop, index, 0, &content, &content_len);
    if (r == MAILPOP3_ERROR_STREAM) {
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r != MAILPOP3_NO_ERROR) {
        * pError = ErrorFetch;
        return NULL;
    }
    
    Data * data;
    data = new Data(content, (unsigned int) content_len);
    MessageHeader * result = new MessageHeader();
    result->importHeadersData(data);
    result->autorelease();
    data->release();
    
    mailpop3_top_free(content);
    * pError = ErrorNone;
    
    return result;
}

MessageHeader * POPSession::fetchHeader(POPMessageInfo * msg, ErrorCode * pError)
{
    return fetchHeader(msg->index(), pError);
}

Data * POPSession::fetchMessage(unsigned int index, POPProgressCallback * callback, ErrorCode * pError)
{
    int r;
    char * content;
    size_t content_len;
    
    listIfNeeded(pError);
    if (* pError != ErrorNone) {
        return NULL;
    }
    
    mProgressCallback = callback;
    
    r = mailpop3_retr(mPop, index, &content, &content_len);
    mProgressCallback = NULL;
    if (r == MAILPOP3_ERROR_STREAM) {
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r != MAILPOP3_NO_ERROR) {
        * pError = ErrorFetch;
        return NULL;
    }
    
    Data * result;
    result = Data::dataWithBytes(content, (unsigned int) content_len);
    mailpop3_retr_free(content);
    * pError = ErrorNone;
    
    return result;
}

Data * POPSession::fetchMessage(POPMessageInfo * msg, POPProgressCallback * callback, ErrorCode * pError)
{
    return fetchMessage(msg->index(), callback, pError);
}

void POPSession::deleteMessage(unsigned int index, ErrorCode * pError)
{
    int r;
    
    listIfNeeded(pError);
    if (* pError != ErrorNone) {
        return;
    }
    
    r = mailpop3_dele(mPop, index);
    if (r == MAILPOP3_ERROR_STREAM) {
        * pError = ErrorConnection;
        return;
    }
    else if (r != MAILPOP3_NO_ERROR) {
        * pError = ErrorDeleteMessage;
        return;
    }
    
    * pError = ErrorNone;
}

void POPSession::deleteMessage(POPMessageInfo * msg, ErrorCode * pError)
{
    deleteMessage(msg->index(), pError);
}

void POPSession::checkAccount(ErrorCode * pError)
{
    loginIfNeeded(pError);
}

void POPSession::noop(ErrorCode * pError)
{
    int r;
    
    if (mPop == NULL)
        return;
    
    MCLog("connect");
    loginIfNeeded(pError);
    if (* pError != ErrorNone) {
        return;
    }
    if (mPop->pop3_stream != NULL) {
        r = mailpop3_noop(mPop);
        if ((r == MAILPOP3_ERROR_STREAM) || (r == MAILPOP3_ERROR_BAD_STATE)) {
            * pError = ErrorConnection;
        }
    }
}

void POPSession::lockConnectionLogger()
{
    pthread_mutex_lock(&mConnectionLoggerLock);
}

void POPSession::unlockConnectionLogger()
{
    pthread_mutex_unlock(&mConnectionLoggerLock);
}

void POPSession::setConnectionLogger(ConnectionLogger * logger)
{
    lockConnectionLogger();
    mConnectionLogger = logger;
    unlockConnectionLogger();
}

ConnectionLogger * POPSession::connectionLogger()
{
    ConnectionLogger * result;

    lockConnectionLogger();
    result = connectionLoggerNoLock();
    unlockConnectionLogger();

    return result;
}

ConnectionLogger * POPSession::connectionLoggerNoLock()
{
    return mConnectionLogger;
}
