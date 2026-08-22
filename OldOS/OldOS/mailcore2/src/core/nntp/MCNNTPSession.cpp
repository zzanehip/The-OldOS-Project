//
//  MCNNTPSession.cpp
//  mailcore2
//
//  Created by Robert Widmann on 3/6/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCWin32.h" // should be included first.

#include "MCNNTPSession.h"

#include <string.h>
#include <libetpan/libetpan.h>

#include "MCNNTPGroupInfo.h"
#include "MCMessageHeader.h"
#include "MCNNTPProgressCallback.h"
#include "MCConnectionLoggerUtils.h"
#include "MCCertificateUtils.h"
#include "MCLibetpan.h"

#define NNTP_DEFAULT_PORT  119
#define NNTPS_DEFAULT_PORT 563

using namespace mailcore;

static int xover_resp_to_fields(struct newsnntp_xover_resp_item * item, struct mailimf_fields ** result);

enum {
    STATE_DISCONNECTED,
    STATE_CONNECTED,
    STATE_LOGGEDIN,
    STATE_LISTED,
    STATE_SELECTED,
};

void NNTPSession::init()
{
    mHostname = NULL;
    mPort = NNTP_DEFAULT_PORT;
    mUsername = NULL;
    mPassword = NULL;
    mConnectionType = ConnectionTypeClear;
    mCheckCertificateEnabled = true;
    mTimeout = 30;
    
    mNNTP = NULL;
    mProgressCallback = NULL;
    mState = STATE_DISCONNECTED;
    mConnectionLogger = NULL;
    pthread_mutex_init(&mConnectionLoggerLock, NULL);
}

NNTPSession::NNTPSession()
{
    init();
}

NNTPSession::~NNTPSession()
{
    pthread_mutex_destroy(&mConnectionLoggerLock);
    MC_SAFE_RELEASE(mHostname);
    MC_SAFE_RELEASE(mUsername);
    MC_SAFE_RELEASE(mPassword);
}

void NNTPSession::setHostname(String * hostname)
{
    MC_SAFE_REPLACE_COPY(String, mHostname, hostname);
}

String * NNTPSession::hostname()
{
    return mHostname;
}

void NNTPSession::setPort(unsigned int port)
{
    mPort = port;
}

unsigned int NNTPSession::port()
{
    return mPort;
}

void NNTPSession::setUsername(String * username)
{
    MC_SAFE_REPLACE_COPY(String, mUsername, username);
}

String * NNTPSession::username()
{
    return mUsername;
}

void NNTPSession::setPassword(String * password)
{
    MC_SAFE_REPLACE_COPY(String, mPassword, password);
}

String * NNTPSession::password()
{
    return mPassword;
}

void NNTPSession::setConnectionType(ConnectionType connectionType)
{
    mConnectionType = connectionType;
}

ConnectionType NNTPSession::connectionType()
{
    return mConnectionType;
}

void NNTPSession::setTimeout(time_t timeout)
{
    mTimeout = timeout;
}

time_t NNTPSession::timeout()
{
    return mTimeout;
}

void NNTPSession::setCheckCertificateEnabled(bool enabled)
{
    mCheckCertificateEnabled = enabled;
}

bool NNTPSession::isCheckCertificateEnabled()
{
    return mCheckCertificateEnabled;
}

bool NNTPSession::checkCertificate()
{
    if (!isCheckCertificateEnabled())
        return true;
    return mailcore::checkCertificate(mNNTP->nntp_stream, hostname());
}

void NNTPSession::body_progress(size_t current, size_t maximum, void * context)
{
    NNTPSession * session;
    
    session = (NNTPSession *) context;
    session->bodyProgress((unsigned int) current, (unsigned int) maximum);
}

void NNTPSession::bodyProgress(unsigned int current, unsigned int maximum)
{
    if (mProgressCallback != NULL) {
        mProgressCallback->bodyProgress(this, current, maximum);
    }
}

static void logger(newsnntp * nntp, int log_type, const char * buffer, size_t size, void * context)
{
    NNTPSession * session = (NNTPSession *) context;
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


void NNTPSession::setup()
{
    mNNTP = newsnntp_new(0, NULL);
    newsnntp_set_logger(mNNTP, logger, this);
}

void NNTPSession::unsetup()
{
    if (mNNTP != NULL) {
        if (mNNTP->nntp_stream != NULL) {
            mailstream_close(mNNTP->nntp_stream);
            mNNTP->nntp_stream = NULL;
        }
        newsnntp_free(mNNTP);
        mNNTP = NULL;
    }
}

void NNTPSession::loginIfNeeded(ErrorCode * pError)
{
    connectIfNeeded(pError);
    if (* pError != ErrorNone) {
        return;
    }
    
    if (mState == STATE_CONNECTED) {
        login(pError);
    }
    else {
        * pError = ErrorNone;
    }
}

void NNTPSession::readerIfNeeded(ErrorCode * pError)
{
    connectIfNeeded(pError);
    if (* pError != ErrorNone)
        return;
    
    if (mState == STATE_CONNECTED) {
        newsnntp_mode_reader(mNNTP);
    }
    else {
        * pError = ErrorNone;
    }
}

void NNTPSession::login(ErrorCode * pError)
{
    int r;

    if (mUsername != NULL) {
        r = newsnntp_authinfo_username(mNNTP, mUsername->UTF8Characters());
        if (r == NEWSNNTP_ERROR_STREAM) {
            * pError = ErrorConnection;
            return;
        }
        else if (r != NEWSNNTP_NO_ERROR) {
            * pError = ErrorAuthentication;
            return;
        }
    }
    if (mPassword != NULL) {
        r = newsnntp_authinfo_password(mNNTP, mPassword->UTF8Characters());
        if (r == NEWSNNTP_ERROR_STREAM) {
            * pError = ErrorConnection;
            return;
        }
        else if (r != NEWSNNTP_NO_ERROR) {
            * pError = ErrorAuthentication;
            return;
        }
    }

    mState = STATE_LOGGEDIN;
    * pError = ErrorNone;
}

void NNTPSession::connect(ErrorCode * pError)
{
    int r;
    
    setup();
    
    switch (mConnectionType) {
        case ConnectionTypeStartTLS:
            MCLog("connect %s %u", MCUTF8(hostname()), (unsigned int) port());
            r = newsnntp_socket_connect(mNNTP, MCUTF8(hostname()), port());
            if (r != NEWSNNTP_NO_ERROR) {
                * pError = ErrorConnection;
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
            r = newsnntp_ssl_connect(mNNTP, MCUTF8(hostname()), port());
            if (r != NEWSNNTP_NO_ERROR) {
                * pError = ErrorConnection;
                return;
            }
            if (!checkCertificate()) {
                * pError = ErrorCertificate;
                return;
            }
            break;
            
        default:
            r = newsnntp_socket_connect(mNNTP, MCUTF8(hostname()), port());
            if (r != NEWSNNTP_NO_ERROR) {
                * pError = ErrorConnection;
                return;
            }
            break;
    }
    
    mailstream_low * low;
    String * identifierString;
    char * identifier;
    
    low = mailstream_get_low(mNNTP->nntp_stream);
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

void NNTPSession::connectIfNeeded(ErrorCode * pError)
{
    if (mState == STATE_DISCONNECTED) {
        connect(pError);
    }
    else {
        * pError = ErrorNone;
    }
}

void NNTPSession::disconnect()
{
    if (mNNTP == NULL)
        return;
    
    newsnntp_quit(mNNTP);
    mState = STATE_DISCONNECTED;
    unsetup();
}

void NNTPSession::checkAccount(ErrorCode * pError)
{
    loginIfNeeded(pError);
}

Array * NNTPSession::listAllNewsgroups(ErrorCode * pError)
{
    int r;
    clist * grp_list;
    
    loginIfNeeded(pError);
    if (* pError != ErrorNone) {
        return NULL;
    }
    
    r = newsnntp_list(mNNTP, &grp_list);
    if (r == NEWSNNTP_ERROR_STREAM) {
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r != NEWSNNTP_NO_ERROR) {
        * pError = ErrorFetchMessageList;
        return NULL;
    }
    
    Array * result = Array::array();
    clistiter * iter;
    for(iter = clist_begin(grp_list) ;iter != NULL ; iter = clist_next(iter)) {
        struct newsnntp_group_info * grp_info;
        String * name;
        
        grp_info = (struct newsnntp_group_info *) clist_content(iter);
        
        name = String::stringWithUTF8Characters(grp_info->grp_name);
        
        NNTPGroupInfo * info = new NNTPGroupInfo();
        info->setName(name);
        result->addObject(info);
        info->release();
    }
    
    newsnntp_list_free(grp_list);
    * pError = ErrorNone;
    mState = STATE_LISTED;
    
    return result;
}

Array * NNTPSession::listDefaultNewsgroups(ErrorCode * pError)
{
    int r;
    clist * subd_groups;
    
    MCLog("fetch subscribed");
    loginIfNeeded(pError);
    if (* pError != ErrorNone) {
        return NULL;
    }
    
    r = newsnntp_list_subscriptions(mNNTP, &subd_groups);
    MCLog("fetch subscribed %u", r);
    
    Array * result = Array::array();
    clistiter * iter;
    for(iter = clist_begin(subd_groups) ;iter != NULL ; iter = clist_next(iter)) {
        struct newsnntp_group_info * grp_info;
        String * name;
        
        grp_info = (struct newsnntp_group_info *) clist_content(iter);
        
        name = String::stringWithUTF8Characters(grp_info->grp_name);
        name->retain();
        
        NNTPGroupInfo * info = new NNTPGroupInfo();
        info->setName(name);
        result->addObject(info);
        info->release();
    }
    newsnntp_list_subscriptions_free(subd_groups);
    * pError = ErrorNone;
    
    return result;
}


MessageHeader * NNTPSession::fetchHeader(String *groupName, unsigned int index, ErrorCode * pError) 
{
    int r;
    char * content;
    size_t content_len;
    
    MCLog("fetch header at index %u", index);
    
    selectGroup(groupName, pError);
    if (* pError != ErrorNone) {
        return NULL;
    }
    
    r = newsnntp_head(mNNTP, index, &content, &content_len);
    if (r != NEWSNNTP_NO_ERROR) {
        * pError = ErrorFetchMessageList;
        return NULL;
    }
    
    Data * data;
    data = new Data(content, (unsigned int) content_len);
    MessageHeader * result = new MessageHeader();
    result->importHeadersData(data);
    result->autorelease();
    data->release();
    
    newsnntp_head_free(content);
    * pError = ErrorNone;
    
    return result;
}

Data * NNTPSession::fetchArticle(String *groupName, unsigned int index, NNTPProgressCallback * callback, ErrorCode * pError) 
{
    int r;
    char * content;
    size_t content_len;
    
    MCLog("fetch article at index %u", index);
    
    selectGroup(groupName, pError);
    if (* pError != ErrorNone) {
        return NULL;
    }
    
    r = newsnntp_article(mNNTP, index, &content, &content_len);
    if (r == NEWSNNTP_ERROR_STREAM) {
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r != NEWSNNTP_NO_ERROR) {
        * pError = ErrorFetchMessageList;
        return NULL;
    }
    
    Data * result;
    result = Data::dataWithBytes(content, (unsigned int) content_len);
    newsnntp_article_free(content);
    * pError = ErrorNone;
    
    return result;
}

Data * NNTPSession::fetchArticleByMessageID(String * messageID, ErrorCode * pError)
{
    int r;
    char * msgID;
    char * content;
    size_t content_len;
    
    MCLog("fetch article at message-id %s", messageID->UTF8Characters());
    
    msgID = strdup(messageID->UTF8Characters());
    
    r = newsnntp_article_by_message_id(mNNTP, msgID, &content, &content_len);
    free(msgID);
    if (r == NEWSNNTP_ERROR_STREAM) {
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r != NEWSNNTP_NO_ERROR) {
        * pError = ErrorFetchMessageList;
        return NULL;
    }
    
    Data * result;
    result = Data::dataWithBytes(content, (unsigned int) content_len);
    newsnntp_article_free(content);
    * pError = ErrorNone;
    
    return result;
}

time_t NNTPSession::fetchServerDate(ErrorCode * pError) {
    int r;
    struct tm time;
    time_t result;
    
    loginIfNeeded(pError);
    if (* pError != ErrorNone) {
        return (time_t) -1;
    }
    
    r = newsnntp_date(mNNTP, &time);
    
    if (r == NEWSNNTP_ERROR_STREAM) {
        * pError = ErrorConnection;
        return (time_t) -1;
    }
    else if (r != NEWSNNTP_NO_ERROR) {
        * pError = ErrorServerDate;
        return (time_t) -1;
    }
    
    result = mkgmtime(&time);
    * pError = ErrorNone;
    
    return result;
}

IndexSet * NNTPSession::fetchAllArticles(String * groupName, ErrorCode * pError) 
{
    int r;
    clist * msg_list;
    
    selectGroup(groupName, pError);
    if (* pError != ErrorNone) {
        return NULL;
    }
    
    r = newsnntp_listgroup(mNNTP, groupName->UTF8Characters(), &msg_list);
    if (r == NEWSNNTP_ERROR_STREAM) {
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r != NEWSNNTP_NO_ERROR) {
        * pError = ErrorFetchMessageList;
        return NULL;
    }
    
    IndexSet * result = new IndexSet();
    clistiter * iter;
    for(iter = clist_begin(msg_list) ;iter != NULL ; iter = clist_next(iter)) {
        uint32_t *msg_info;
        
        msg_info = (uint32_t *) clist_content(iter);
        if (!msg_info) {
            continue;
        }
        
        result->addIndex(*msg_info);
    }
    
    newsnntp_listgroup_free(msg_list);
    * pError = ErrorNone;
    mState = STATE_LISTED;
    
    return result;
}

Array * NNTPSession::fetchOverArticlesInRange(Range range, String * groupName, ErrorCode * pError)
{
    int r;
    clist * msg_list;
    
    selectGroup(groupName, pError);
    if (* pError != ErrorNone) {
        return NULL;
    }
    r = newsnntp_xover_range(mNNTP, (uint32_t) range.location, (uint32_t) (range.location + range.length), &msg_list);
    if (r == NEWSNNTP_ERROR_STREAM) {
        * pError = ErrorConnection;
        return NULL;
    }
    else if (r != NEWSNNTP_NO_ERROR) {
        * pError = ErrorFetchMessageList;
        return NULL;
    }
    
    Array * result = Array::array();
    clistiter * iter;
    for(iter = clist_begin(msg_list) ;iter != NULL ; iter = clist_next(iter)) {
        struct newsnntp_xover_resp_item * item;
        struct mailimf_fields * fields = NULL;
        
        item = (struct newsnntp_xover_resp_item *) clist_content(iter);
        if (!item) {
            continue;
        }
        
        r = xover_resp_to_fields(item, &fields);
        if (r == MAIL_NO_ERROR) {
            MessageHeader * header = new MessageHeader();
            header->importIMFFields(fields);
            result->addObject(header);
            header->release();
        }
    }
    
    newsnntp_xover_resp_list_free(msg_list);
    * pError = ErrorNone;
    
    return result;
}

// Taken from nntp/nntpdriver.c
static int xover_resp_to_fields(struct newsnntp_xover_resp_item * item, struct mailimf_fields ** result)
{
    size_t cur_token;
    clist * list;
    struct mailimf_fields * fields;
    int r;

    list = clist_new();
    if (list == NULL) {
        r = MAIL_ERROR_MEMORY;
        goto err;
    }

    if (item->ovr_subject != NULL) {
        char * subject_str;
        struct mailimf_subject * subject;
        struct mailimf_field * field;

        subject_str = strdup(item->ovr_subject);
        if (subject_str == NULL) {
            r = MAIL_ERROR_MEMORY;
            goto free_list;
        }

        subject = mailimf_subject_new(subject_str);
        if (subject == NULL) {
            free(subject_str);
            r = MAIL_ERROR_MEMORY;
            goto free_list;
        }

        field = mailimf_field_new(MAILIMF_FIELD_SUBJECT,
                                  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                  NULL, NULL, NULL,
                                  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                  NULL, subject, NULL, NULL, NULL);
        if (field == NULL) {
            mailimf_subject_free(subject);
            r = MAIL_ERROR_MEMORY;
            goto free_list;
        }

        r = clist_append(list, field);
        if (r < 0) {
            mailimf_field_free(field);
            r = MAIL_ERROR_MEMORY;
            goto free_list;
        }
    }

    if (item->ovr_author != NULL) {
        struct mailimf_mailbox_list * mb_list;
        struct mailimf_from * from;
        struct mailimf_field * field;

        cur_token = 0;
        r = mailimf_mailbox_list_parse(item->ovr_author, strlen(item->ovr_author),
                                       &cur_token, &mb_list);
        switch (r) {
            case MAILIMF_NO_ERROR:
                from = mailimf_from_new(mb_list);
                if (from == NULL) {
                    mailimf_mailbox_list_free(mb_list);
                    r = MAIL_ERROR_MEMORY;
                    goto free_list;
                }

                field = mailimf_field_new(MAILIMF_FIELD_FROM,
                                          NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                          NULL, NULL, from,
                                          NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                          NULL, NULL, NULL, NULL, NULL);
                if (field == NULL) {
                    mailimf_from_free(from);
                    r = MAIL_ERROR_MEMORY;
                    goto free_list;
                }

                r = clist_append(list, field);
                if (r < 0) {
                    mailimf_field_free(field);
                    r = MAIL_ERROR_MEMORY;
                    goto free_list;
                }
                break;

            case MAILIMF_ERROR_PARSE:
                break;

            default:
                goto free_list;
        }
    }

    if (item->ovr_date != NULL) {
        struct mailimf_date_time * date_time;
        struct mailimf_orig_date * orig_date;
        struct mailimf_field * field;

        cur_token = 0;
        r = mailimf_date_time_parse(item->ovr_date, strlen(item->ovr_date),
                                    &cur_token, &date_time);
        switch (r) {
            case MAILIMF_NO_ERROR:
                orig_date = mailimf_orig_date_new(date_time);
                if (orig_date == NULL) {
                    mailimf_date_time_free(date_time);
                    r = MAIL_ERROR_MEMORY;
                    goto free_list;
                }

                field = mailimf_field_new(MAILIMF_FIELD_ORIG_DATE,
                                          NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                          NULL, orig_date, NULL,
                                          NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                          NULL, NULL, NULL, NULL, NULL);
                if (field == NULL) {
                    mailimf_orig_date_free(orig_date);
                    r = MAIL_ERROR_MEMORY;
                    goto free_list;
                }

                r = clist_append(list, field);
                if (r < 0) {
                    mailimf_field_free(field);
                    r = MAIL_ERROR_MEMORY;
                    goto free_list;
                }
                break;

            case MAILIMF_ERROR_PARSE:
                break;

            default:
                goto free_list;
        }
    }

    if (item->ovr_message_id != NULL)  {
        char * msgid_str;
        struct mailimf_message_id * msgid;
        struct mailimf_field * field;

        cur_token = 0;
        r = mailimf_msg_id_parse(item->ovr_message_id, strlen(item->ovr_message_id),
                                 &cur_token, &msgid_str);

        switch (r) {
            case MAILIMF_NO_ERROR:
                msgid = mailimf_message_id_new(msgid_str);
                if (msgid == NULL) {
                    mailimf_msg_id_free(msgid_str);
                    r = MAIL_ERROR_MEMORY;
                    goto free_list;
                }

                field = mailimf_field_new(MAILIMF_FIELD_MESSAGE_ID,
                                          NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                          NULL, NULL, NULL,
                                          NULL, NULL, NULL, NULL, NULL, msgid, NULL,
                                          NULL, NULL, NULL, NULL, NULL);

                r = clist_append(list, field);
                if (r < 0) {
                    mailimf_field_free(field);
                    r = MAIL_ERROR_MEMORY;
                    goto free_list;
                }
                break;

            case MAILIMF_ERROR_PARSE:
                break;

            default:
                goto free_list;
        }
    }

    if (item->ovr_references != NULL) {
        clist * msgid_list;
        struct mailimf_references * references;
        struct mailimf_field * field;

        cur_token = 0;

        r = mailimf_msg_id_list_parse(item->ovr_references, strlen(item->ovr_references),
                                      &cur_token, &msgid_list);

        switch (r) {
            case MAILIMF_NO_ERROR:
                references = mailimf_references_new(msgid_list);
                if (references == NULL) {
                    clist_foreach(msgid_list,
                                  (clist_func) mailimf_msg_id_free, NULL);
                    clist_free(msgid_list);
                    r = MAIL_ERROR_MEMORY;
                    goto free_list;
                }

                field = mailimf_field_new(MAILIMF_FIELD_REFERENCES,
                                          NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                          NULL, NULL, NULL,
                                          NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                          references, NULL, NULL, NULL, NULL);

                r = clist_append(list, field);
                if (r < 0) {
                    mailimf_field_free(field);
                    r = MAIL_ERROR_MEMORY;
                    goto free_list;
                }
                break;

            case MAILIMF_ERROR_PARSE:
                break;

            default:
                goto free_list;
        }
    }

    fields = mailimf_fields_new(list);
    if (fields == NULL) {
        r = MAIL_ERROR_MEMORY;
        goto free_list;
    }

    * result = fields;

    return MAIL_NO_ERROR;

free_list:
    clist_foreach(list, (clist_func) mailimf_field_free, NULL);
    clist_free(list);
err:
    return r;
}

void NNTPSession::postMessage(Data * messageData, NNTPProgressCallback * callback, ErrorCode * pError)
{
    int r;
    
    messageData = dataWithFilteredBcc(messageData);
    
    mProgressCallback = callback;
    bodyProgress(0, messageData->length());
    
    MCLog("setup");
    
    MCLog("connect");
    loginIfNeeded(pError);
    if (* pError != ErrorNone) {
        goto err;
    }
    
    MCLog("send");
    r = newsnntp_post(mNNTP, messageData->bytes(), messageData->length());
    
    String * response;
    
    response = NULL;
    if (mNNTP->nntp_response != NULL) {
        response = String::stringWithUTF8Characters(mNNTP->nntp_response);
    }
    
    if (r == NEWSNNTP_ERROR_STREAM) {
        * pError = ErrorConnection;
        goto err;
    }
    else if (r != NEWSNNTP_NO_ERROR) {
        * pError = ErrorSendMessage;
        goto err;
    }
    
    bodyProgress(messageData->length(), messageData->length());
    * pError = ErrorNone;
    
err:
    mProgressCallback = NULL;
}

void NNTPSession::postMessage(String * messagePath, NNTPProgressCallback * callback, ErrorCode * pError)
{
    Data * messageData = Data::dataWithContentsOfFile(messagePath);
    if (!messageData) {
        * pError = ErrorFile;
        return;
    }
    
    return postMessage(messageData, callback, pError);
}

static void mmapStringDeallocator(char * bytes, unsigned int length) {
    mmap_string_unref(bytes);
}

Data * NNTPSession::dataWithFilteredBcc(Data * data)
{
    int r;
    size_t idx;
    struct mailimf_message * msg;
    
    idx = 0;
    r = mailimf_message_parse(data->bytes(), data->length(), &idx, &msg);
    if (r != MAILIMF_NO_ERROR) {
        return Data::data();
    }
    
    struct mailimf_fields * fields = msg->msg_fields;
    int col = 0;
    
    int hasRecipient = 0;
    bool bccWasActuallyRemoved = false;
    for(clistiter * cur = clist_begin(fields->fld_list) ; cur != NULL ; cur = clist_next(cur)) {
        struct mailimf_field * field = (struct mailimf_field *) clist_content(cur);
        if (field->fld_type == MAILIMF_FIELD_BCC) {
            mailimf_field_free(field);
            clist_delete(fields->fld_list, cur);
            bccWasActuallyRemoved = true;
            break;
        }
        else if ((field->fld_type == MAILIMF_FIELD_TO) || (field->fld_type == MAILIMF_FIELD_CC)) {
            hasRecipient = 1;
        }
    }
    if (!hasRecipient) {
        struct mailimf_address_list * imfTo;
        imfTo = mailimf_address_list_new_empty();
        mailimf_address_list_add_parse(imfTo, (char *) "Undisclosed recipients:;");
        struct mailimf_to * toField = mailimf_to_new(imfTo);
        struct mailimf_field * field = mailimf_field_new(MAILIMF_FIELD_TO, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, toField, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
        mailimf_fields_add(fields, field);
    }
    
    Data * result;
    if (!hasRecipient || bccWasActuallyRemoved) {
        MMAPString * str = mmap_string_new("");
        mailimf_fields_write_mem(str, &col, fields);
        mmap_string_append(str, "\n");
        mmap_string_append_len(str, msg->msg_body->bd_text, msg->msg_body->bd_size);
        
        mmap_string_ref(str);
        
        result = Data::data();
        result->takeBytesOwnership(str->str, (unsigned int) str->len, mmapStringDeallocator);
    }
    else {
        // filter Bcc and modify To: only if necessary.
        result = data;
    }
    
    mailimf_message_free(msg);
    
    return result;
}

void NNTPSession::selectGroup(String * folder, ErrorCode * pError) 
{
    int r;
    struct newsnntp_group_info * info;
    
    loginIfNeeded(pError);
    if (* pError != ErrorNone) {
        return;
    }
    
    readerIfNeeded(pError);
    if (* pError != ErrorNone) {
        return;
    }
    
    r = newsnntp_group(mNNTP, folder->UTF8Characters(), &info);
    if (r == NEWSNNTP_ERROR_STREAM) {
        * pError = ErrorConnection;
        MCLog("select error : %s %i", MCUTF8DESC(this), * pError);
        return;
    }
    else if (r == NEWSNNTP_ERROR_NO_SUCH_NEWS_GROUP) {
        * pError = ErrorNonExistantFolder;
        return;
    }
    else if (r == MAILIMAP_ERROR_PARSE) {
        * pError = ErrorParse;
        return;
    }
    
    mState = STATE_SELECTED;
    * pError = ErrorNone;
    MCLog("select ok");
}

void NNTPSession::lockConnectionLogger()
{
    pthread_mutex_lock(&mConnectionLoggerLock);
}

void NNTPSession::unlockConnectionLogger()
{
    pthread_mutex_unlock(&mConnectionLoggerLock);
}

void NNTPSession::setConnectionLogger(ConnectionLogger * logger)
{
    lockConnectionLogger();
    mConnectionLogger = logger;
    unlockConnectionLogger();
}

ConnectionLogger * NNTPSession::connectionLogger()
{
    ConnectionLogger * result;

    lockConnectionLogger();
    result = connectionLoggerNoLock();
    unlockConnectionLogger();

    return result;
}

ConnectionLogger * NNTPSession::connectionLoggerNoLock()
{
    return mConnectionLogger;
}

