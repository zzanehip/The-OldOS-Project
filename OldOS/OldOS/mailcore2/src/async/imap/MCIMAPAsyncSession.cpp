//
//  MCIMAPAsyncSession.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/17/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPAsyncSession.h"

#include "MCIMAPAsyncConnection.h"
#include "MCIMAPNamespace.h"
#include "MCOperationQueueCallback.h"
#include "MCConnectionLogger.h"
#include "MCIMAPSession.h"
#include "MCIMAPIdentity.h"
#include "MCIMAPMultiDisconnectOperation.h"

#include "MCIMAPFolderInfoOperation.h"
#include "MCIMAPFolderStatusOperation.h"
#include "MCIMAPFetchFoldersOperation.h"
#include "MCIMAPRenameFolderOperation.h"
#include "MCIMAPDeleteFolderOperation.h"
#include "MCIMAPCreateFolderOperation.h"
#include "MCIMAPSubscribeFolderOperation.h"
#include "MCIMAPExpungeOperation.h"
#include "MCIMAPAppendMessageOperation.h"
#include "MCIMAPCopyMessagesOperation.h"
#include "MCIMAPMoveMessagesOperation.h"
#include "MCIMAPFetchMessagesOperation.h"
#include "MCIMAPFetchContentOperation.h"
#include "MCIMAPFetchContentToFileOperation.h"
#include "MCIMAPFetchParsedContentOperation.h"
#include "MCIMAPStoreFlagsOperation.h"
#include "MCIMAPStoreLabelsOperation.h"
#include "MCIMAPSearchOperation.h"
#include "MCIMAPConnectOperation.h"
#include "MCIMAPCheckAccountOperation.h"
#include "MCIMAPFetchNamespaceOperation.h"
#include "MCIMAPIdleOperation.h"
#include "MCIMAPIdentityOperation.h"
#include "MCIMAPCapabilityOperation.h"
#include "MCIMAPQuotaOperation.h"
#include "MCIMAPDisconnectOperation.h"
#include "MCIMAPNoopOperation.h"
#include "MCIMAPMessageRenderingOperation.h"
#include "MCIMAPCustomCommandOperation.h"

#define DEFAULT_MAX_CONNECTIONS 3

using namespace mailcore;

IMAPAsyncSession::IMAPAsyncSession()
{
    mSessions = new Array();
    mMaximumConnections = DEFAULT_MAX_CONNECTIONS;
    mAllowsFolderConcurrentAccessEnabled = true;

    mHostname = NULL;
    mPort = 0;
    mUsername = NULL;
    mPassword = NULL;
    mOAuth2Token = NULL;
    mAuthType = AuthTypeSASLNone;
    mConnectionType = ConnectionTypeClear;
    mCheckCertificateEnabled = true;
    mVoIPEnabled = true;
    mDefaultNamespace = NULL;
    mTimeout = 30.;
    mConnectionLogger = NULL;
    mAutomaticConfigurationDone = false;
    mServerIdentity = new IMAPIdentity();
    mClientIdentity = new IMAPIdentity();
    mOperationQueueCallback = NULL;
#if __APPLE__
    mDispatchQueue = dispatch_get_main_queue();
#endif
    mGmailUserDisplayName = NULL;
    mQueueRunning = false;
    mIdleEnabled = false;
}

IMAPAsyncSession::~IMAPAsyncSession()
{
#if __APPLE__
    if (mDispatchQueue != NULL) {
        dispatch_release(mDispatchQueue);
    }
#endif
    MC_SAFE_RELEASE(mGmailUserDisplayName);
    MC_SAFE_RELEASE(mServerIdentity);
    MC_SAFE_RELEASE(mClientIdentity);
    MC_SAFE_RELEASE(mSessions);
    MC_SAFE_RELEASE(mHostname);
    MC_SAFE_RELEASE(mUsername);
    MC_SAFE_RELEASE(mPassword);
    MC_SAFE_RELEASE(mOAuth2Token);
    MC_SAFE_RELEASE(mDefaultNamespace);
}

void IMAPAsyncSession::setHostname(String * hostname)
{
    MC_SAFE_REPLACE_COPY(String, mHostname, hostname);
}

String * IMAPAsyncSession::hostname()
{
    return mHostname;
}

void IMAPAsyncSession::setPort(unsigned int port)
{
    mPort = port;
}

unsigned int IMAPAsyncSession::port()
{
    return mPort;
}

void IMAPAsyncSession::setUsername(String * username)
{
    MC_SAFE_REPLACE_COPY(String, mUsername, username);
}

String * IMAPAsyncSession::username()
{
    return mUsername;
}

void IMAPAsyncSession::setPassword(String * password)
{
    MC_SAFE_REPLACE_COPY(String, mPassword, password);
}

String * IMAPAsyncSession::password()
{
    return mPassword;
}

void IMAPAsyncSession::setOAuth2Token(String * token)
{
    MC_SAFE_REPLACE_COPY(String, mOAuth2Token, token);
}

String * IMAPAsyncSession::OAuth2Token()
{
    return mOAuth2Token;
}

void IMAPAsyncSession::setAuthType(AuthType authType)
{
    mAuthType = authType;
}

AuthType IMAPAsyncSession::authType()
{
    return mAuthType;
}

void IMAPAsyncSession::setConnectionType(ConnectionType connectionType)
{
    mConnectionType = connectionType;
}

ConnectionType IMAPAsyncSession::connectionType()
{
    return mConnectionType;
}

void IMAPAsyncSession::setTimeout(time_t timeout)
{
    mTimeout = timeout;
}

time_t IMAPAsyncSession::timeout()
{
    return mTimeout;
}

void IMAPAsyncSession::setCheckCertificateEnabled(bool enabled)
{
    mCheckCertificateEnabled = enabled;
}

bool IMAPAsyncSession::isCheckCertificateEnabled()
{
    return mCheckCertificateEnabled;
}

void IMAPAsyncSession::setVoIPEnabled(bool enabled)
{
    mVoIPEnabled = enabled;
}

bool IMAPAsyncSession::isVoIPEnabled()
{
    return mVoIPEnabled;
}

IMAPNamespace * IMAPAsyncSession::defaultNamespace()
{
    return mDefaultNamespace;
}

void IMAPAsyncSession::setDefaultNamespace(IMAPNamespace * ns)
{
    MC_SAFE_REPLACE_RETAIN(IMAPNamespace, mDefaultNamespace, ns);
}

void IMAPAsyncSession::setAllowsFolderConcurrentAccessEnabled(bool enabled)
{
    mAllowsFolderConcurrentAccessEnabled = enabled;
}

bool IMAPAsyncSession::allowsFolderConcurrentAccessEnabled()
{
    return mAllowsFolderConcurrentAccessEnabled;
}

void IMAPAsyncSession::setMaximumConnections(unsigned int maxConnections)
{
    mMaximumConnections = maxConnections;
}

unsigned int IMAPAsyncSession::maximumConnections()
{
    return mMaximumConnections;
}

IMAPIdentity * IMAPAsyncSession::serverIdentity()
{
    return mServerIdentity;
}

IMAPIdentity * IMAPAsyncSession::clientIdentity()
{
    return mClientIdentity;
}

void IMAPAsyncSession::setClientIdentity(IMAPIdentity * clientIdentity)
{
    MC_SAFE_REPLACE_COPY(IMAPIdentity, mClientIdentity, clientIdentity);
}

String * IMAPAsyncSession::gmailUserDisplayName()
{
    return mGmailUserDisplayName;
}

bool IMAPAsyncSession::isIdleEnabled()
{
    return mIdleEnabled;
}

IMAPAsyncConnection * IMAPAsyncSession::session()
{
    IMAPAsyncConnection * session = new IMAPAsyncConnection();
    session->setConnectionLogger(mConnectionLogger);
    session->setOwner(this);
    session->autorelease();

    session->setHostname(mHostname);
    session->setPort(mPort);
    session->setUsername(mUsername);
    session->setPassword(mPassword);
    session->setOAuth2Token(mOAuth2Token);
    session->setAuthType(mAuthType);
    session->setConnectionType(mConnectionType);
    session->setTimeout(mTimeout);
    session->setCheckCertificateEnabled(mCheckCertificateEnabled);
    session->setVoIPEnabled(mVoIPEnabled);
    session->setDefaultNamespace(mDefaultNamespace);
    session->setClientIdentity(mClientIdentity);
#if __APPLE__
    session->setDispatchQueue(mDispatchQueue);
#endif
#if 0 // should be implemented properly
    if (mAutomaticConfigurationDone) {
        session->setAutomaticConfigurationEnabled(false);
    }
#endif

    return session;
}

IMAPAsyncConnection * IMAPAsyncSession::sessionForFolder(String * folder, bool urgent)
{
    if (folder == NULL) {
        return matchingSessionForFolder(NULL);
    }
    else {
        IMAPAsyncConnection * s = NULL;

        // try find session with empty queue, selected to the folder
        s = sessionWithMinQueue(true, folder);
        if (s != NULL && s->operationsCount() == 0) {
            s->setLastFolder(folder);
            return s;
        }

        if (urgent && mAllowsFolderConcurrentAccessEnabled) {
            // in urgent mode try reuse any available session with
            // empty queue or create new one, if maximum connections limit does not reached.
            s = availableSession();
            if (s->operationsCount() == 0) {
                s->setLastFolder(folder);
                return s;
            }
        }

        // otherwise returns session with minimum size of queue among selected to the folder.
        s = matchingSessionForFolder(folder);
        s->setLastFolder(folder);
        return s;
    }
}

IMAPAsyncConnection * IMAPAsyncSession::availableSession()
{
    // try find existant session with empty queue for reusing.
    IMAPAsyncConnection * chosenSession = sessionWithMinQueue(false, NULL);
    if ((chosenSession != NULL) && (chosenSession->operationsCount() == 0)) {
        return chosenSession;
    }

    // create new session, if maximum connections limit does not reached yet.
    if ((mMaximumConnections == 0) || (mSessions->count() < mMaximumConnections)) {
        chosenSession = session();
        mSessions->addObject(chosenSession);
        return chosenSession;
    }

    // otherwise returns existant session with minimum size of queue.
    return chosenSession;
}

IMAPAsyncConnection * IMAPAsyncSession::matchingSessionForFolder(String * folder)
{
    IMAPAsyncConnection * s = NULL;
    if (folder == NULL) {
        // try find session with minimum size of queue among non-selected to the any folder.
        s = sessionWithMinQueue(true, NULL);

        if (s == NULL) {
            // prefer to use INBOX-selected folders for commands does not tight to specific folder.
            s = sessionWithMinQueue(true, MCSTR("INBOX"));
        }
    } else {
        // try find session with minimum size of queue among selected to the folder.
        s = sessionWithMinQueue(true, folder);

        if (s == NULL) {
            // try find session with minimum size of queue among non-selected to any folder ones.
            s = sessionWithMinQueue(true, NULL);
        }
    }

    if (s != NULL) {
        return s;
    }

    // otherwise returns existant session with minumum size of queue or create new one.
    return availableSession();
}

IMAPAsyncConnection * IMAPAsyncSession::sessionWithMinQueue(bool filterByFolder, String * folder)
{
    IMAPAsyncConnection * chosenSession = NULL;
    unsigned int minOperationsCount = 0;

    for (unsigned int i = 0 ; i < mSessions->count() ; i ++) {
        IMAPAsyncConnection * s = (IMAPAsyncConnection *) mSessions->objectAtIndex(i);
        if ((chosenSession == NULL) || (s->operationsCount() < minOperationsCount)) {
            bool matched = true;
            if (filterByFolder) {
                // filter by last selested folder
                matched = ((folder != NULL && s->lastFolder() != NULL && s->lastFolder()->isEqual(folder))
                           || (folder == NULL && s->lastFolder() == NULL));
            }
            if (matched) {
                chosenSession = s;
                minOperationsCount = s->operationsCount();
            }
        }
    }

    return chosenSession;
}

IMAPFolderInfoOperation * IMAPAsyncSession::folderInfoOperation(String * folder)
{
    IMAPFolderInfoOperation * op = new IMAPFolderInfoOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->autorelease();
    return op;
}

IMAPFolderStatusOperation * IMAPAsyncSession::folderStatusOperation(String * folder)
{
    IMAPFolderStatusOperation * op = new IMAPFolderStatusOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->autorelease();
    return op;
}

IMAPFetchFoldersOperation * IMAPAsyncSession::fetchSubscribedFoldersOperation()
{
    IMAPFetchFoldersOperation * op = new IMAPFetchFoldersOperation();
    op->setMainSession(this);
    op->setFetchSubscribedEnabled(true);
    op->autorelease();
    return op;
}

IMAPFetchFoldersOperation * IMAPAsyncSession::fetchAllFoldersOperation()
{
    IMAPFetchFoldersOperation * op = new IMAPFetchFoldersOperation();
    op->setMainSession(this);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::renameFolderOperation(String * folder, String * otherName)
{
    IMAPRenameFolderOperation * op = new IMAPRenameFolderOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setOtherName(otherName);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::deleteFolderOperation(String * folder)
{
    IMAPDeleteFolderOperation * op = new IMAPDeleteFolderOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::createFolderOperation(String * folder)
{
    IMAPCreateFolderOperation * op = new IMAPCreateFolderOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::subscribeFolderOperation(String * folder)
{
    IMAPSubscribeFolderOperation * op = new IMAPSubscribeFolderOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::unsubscribeFolderOperation(String * folder)
{
    IMAPSubscribeFolderOperation * op = new IMAPSubscribeFolderOperation();
    op->setMainSession(this);
    op->setUnsubscribeEnabled(true);
    op->setFolder(folder);
    op->autorelease();
    return op;
}

IMAPAppendMessageOperation * IMAPAsyncSession::appendMessageOperation(String * folder, Data * messageData, MessageFlag flags, Array * customFlags)
{
    IMAPAppendMessageOperation * op = new IMAPAppendMessageOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setMessageData(messageData);
    op->setFlags(flags);
    op->setCustomFlags(customFlags);
    op->autorelease();
    return op;
}

IMAPAppendMessageOperation * IMAPAsyncSession::appendMessageOperation(String * folder, String * messagePath, MessageFlag flags, Array * customFlags)
{
    IMAPAppendMessageOperation * op = new IMAPAppendMessageOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setMessageFilepath(messagePath);
    op->setFlags(flags);
    op->setCustomFlags(customFlags);
    op->autorelease();
    return op;
}

IMAPCopyMessagesOperation * IMAPAsyncSession::copyMessagesOperation(String * folder, IndexSet * uids, String * destFolder)
{
    IMAPCopyMessagesOperation * op = new IMAPCopyMessagesOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setUids(uids);
    op->setDestFolder(destFolder);
    op->autorelease();
    return op;
}

IMAPMoveMessagesOperation * IMAPAsyncSession::moveMessagesOperation(String * folder, IndexSet * uids, String * destFolder)
{
    IMAPMoveMessagesOperation * op = new IMAPMoveMessagesOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setUids(uids);
    op->setDestFolder(destFolder);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::expungeOperation(String * folder)
{
    IMAPExpungeOperation * op = new IMAPExpungeOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->autorelease();
    return op;
}

IMAPFetchMessagesOperation * IMAPAsyncSession::fetchMessagesByUIDOperation(String * folder, IMAPMessagesRequestKind requestKind,
                                                                           IndexSet * uids)
{
    IMAPFetchMessagesOperation * op = new IMAPFetchMessagesOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setKind(requestKind);
    op->setFetchByUidEnabled(true);
    op->setIndexes(uids);
    op->autorelease();
    return op;
}

IMAPFetchMessagesOperation * IMAPAsyncSession::fetchMessagesByNumberOperation(String * folder, IMAPMessagesRequestKind requestKind,
                                                                              IndexSet * numbers)
{
    IMAPFetchMessagesOperation * op = new IMAPFetchMessagesOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setKind(requestKind);
    op->setIndexes(numbers);
    op->autorelease();
    return op;
}

IMAPFetchMessagesOperation * IMAPAsyncSession::syncMessagesByUIDOperation(String * folder, IMAPMessagesRequestKind requestKind,
                                                                          IndexSet * uids, uint64_t modSeq)
{
    IMAPFetchMessagesOperation * op = new IMAPFetchMessagesOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setKind(requestKind);
    op->setFetchByUidEnabled(true);
    op->setIndexes(uids);
    op->setModSequenceValue(modSeq);
    op->autorelease();
    return op;
}

IMAPFetchContentOperation * IMAPAsyncSession::fetchMessageByUIDOperation(String * folder, uint32_t uid, bool urgent)
{
    IMAPFetchContentOperation * op = new IMAPFetchContentOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setUid(uid);
    op->setUrgent(urgent);
    op->autorelease();
    return op;
}

IMAPFetchContentOperation * IMAPAsyncSession::fetchMessageAttachmentByUIDOperation(String * folder, uint32_t uid, String * partID,
                                                                         Encoding encoding, bool urgent)
{
    IMAPFetchContentOperation * op = new IMAPFetchContentOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setUid(uid);
    op->setPartID(partID);
    op->setEncoding(encoding);
    op->setUrgent(urgent);
    op->autorelease();
    return op;
}

IMAPFetchContentToFileOperation * IMAPAsyncSession::fetchMessageAttachmentToFileByUIDOperation(
                                                                                   String * folder, uint32_t uid, String * partID,
                                                                                   Encoding encoding,
                                                                                   String * filename,
                                                                                   bool urgent)
{
    IMAPFetchContentToFileOperation * op = new IMAPFetchContentToFileOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setUid(uid);
    op->setPartID(partID);
    op->setEncoding(encoding);
    op->setFilename(filename);
    op->setUrgent(urgent);
    op->autorelease();
    return op;
}

IMAPFetchContentOperation * IMAPAsyncSession::fetchMessageByNumberOperation(String * folder, uint32_t number, bool urgent)
{
    IMAPFetchContentOperation * op = new IMAPFetchContentOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setNumber(number);
    op->setUrgent(urgent);
    op->autorelease();
    return op;
}

IMAPCustomCommandOperation * IMAPAsyncSession::customCommand(String *command, bool urgent)
{

    IMAPCustomCommandOperation *op = new IMAPCustomCommandOperation();
    op->setMainSession(this);
    op->setCustomCommand(command);
    op->setUrgent(urgent);
    op->autorelease();
    return op;
}

IMAPFetchContentOperation * IMAPAsyncSession::fetchMessageAttachmentByNumberOperation(String * folder, uint32_t number, String * partID,
                                                                                      Encoding encoding, bool urgent)
{
    IMAPFetchContentOperation * op = new IMAPFetchContentOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setNumber(number);
    op->setPartID(partID);
    op->setEncoding(encoding);
    op->setUrgent(urgent);
    op->autorelease();
    return op;
}

IMAPFetchParsedContentOperation * IMAPAsyncSession::fetchParsedMessageByUIDOperation(String * folder, uint32_t uid, bool urgent)
{
    IMAPFetchParsedContentOperation * op = new IMAPFetchParsedContentOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setUid(uid);
    op->setUrgent(urgent);
    op->autorelease();
    return op;
}

IMAPFetchParsedContentOperation * IMAPAsyncSession::fetchParsedMessageByNumberOperation(String * folder, uint32_t number, bool urgent)
{
    IMAPFetchParsedContentOperation * op = new IMAPFetchParsedContentOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setNumber(number);
    op->setUrgent(urgent);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::storeFlagsByUIDOperation(String * folder, IndexSet * uids, IMAPStoreFlagsRequestKind kind, MessageFlag flags, Array * customFlags)
{
    IMAPStoreFlagsOperation * op = new IMAPStoreFlagsOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setUids(uids);
    op->setKind(kind);
    op->setFlags(flags);
    op->setCustomFlags(customFlags);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::storeFlagsByNumberOperation(String * folder, IndexSet * numbers, IMAPStoreFlagsRequestKind kind, MessageFlag flags, Array * customFlags)
{
    IMAPStoreFlagsOperation * op = new IMAPStoreFlagsOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setNumbers(numbers);
    op->setKind(kind);
    op->setFlags(flags);
    op->setCustomFlags(customFlags);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::storeLabelsByUIDOperation(String * folder, IndexSet * uids, IMAPStoreFlagsRequestKind kind, Array * labels)
{
    IMAPStoreLabelsOperation * op = new IMAPStoreLabelsOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setUids(uids);
    op->setKind(kind);
    op->setLabels(labels);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::storeLabelsByNumberOperation(String * folder, IndexSet * numbers, IMAPStoreFlagsRequestKind kind, Array * labels)
{
    IMAPStoreLabelsOperation * op = new IMAPStoreLabelsOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setNumbers(numbers);
    op->setKind(kind);
    op->setLabels(labels);
    op->autorelease();
    return op;
}

IMAPSearchOperation * IMAPAsyncSession::searchOperation(String * folder, IMAPSearchKind kind, String * searchString)
{
    IMAPSearchOperation * op = new IMAPSearchOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setSearchKind(kind);
    op->setSearchString(searchString);
    op->autorelease();
    return op;
}

IMAPSearchOperation * IMAPAsyncSession::searchOperation(String * folder, IMAPSearchExpression * expression)
{
    IMAPSearchOperation * op = new IMAPSearchOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setSearchExpression(expression);
    op->autorelease();
    return op;
}

IMAPIdleOperation * IMAPAsyncSession::idleOperation(String * folder, uint32_t lastKnownUID)
{
    IMAPIdleOperation * op = new IMAPIdleOperation();
    op->setMainSession(this);
    op->setFolder(folder);
    op->setLastKnownUID(lastKnownUID);
    op->autorelease();
    return op;
}

IMAPFetchNamespaceOperation * IMAPAsyncSession::fetchNamespaceOperation()
{
    IMAPFetchNamespaceOperation * op = new IMAPFetchNamespaceOperation();
    op->setMainSession(this);
    op->autorelease();
    return op;
}

IMAPIdentityOperation * IMAPAsyncSession::identityOperation(IMAPIdentity * identity)
{
    IMAPIdentityOperation * op = new IMAPIdentityOperation();
    op->setMainSession(this);
    op->setClientIdentity(identity);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::connectOperation()
{
    IMAPConnectOperation * op = new IMAPConnectOperation();
    op->setMainSession(this);
    op->autorelease();
    return op;
}

IMAPCheckAccountOperation * IMAPAsyncSession::checkAccountOperation()
{
    IMAPCheckAccountOperation * op = new IMAPCheckAccountOperation();
    op->setMainSession(this);
    op->autorelease();
    return op;
}

IMAPCapabilityOperation * IMAPAsyncSession::capabilityOperation()
{
    IMAPCapabilityOperation * op = new IMAPCapabilityOperation();
    op->setMainSession(this);
    op->autorelease();
    return op;
}

IMAPQuotaOperation * IMAPAsyncSession::quotaOperation()
{
    IMAPQuotaOperation * op = new IMAPQuotaOperation();
    op->setMainSession(this);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::noopOperation()
{
    IMAPNoopOperation * op = new IMAPNoopOperation();
    op->setMainSession(this);
    op->autorelease();
    return op;
}

IMAPOperation * IMAPAsyncSession::disconnectOperation()
{
    IMAPMultiDisconnectOperation * op = new IMAPMultiDisconnectOperation();
    op->autorelease();
    for(unsigned int i = 0 ; i < mSessions->count() ; i ++) {
        IMAPAsyncConnection * currentSession = (IMAPAsyncConnection *) mSessions->objectAtIndex(i);
        op->addOperation(currentSession->disconnectOperation());
    }
    return op;
}

void IMAPAsyncSession::setConnectionLogger(ConnectionLogger * logger)
{
    mConnectionLogger = logger;
    for(unsigned int i = 0 ; i < mSessions->count() ; i ++) {
        IMAPAsyncConnection * currentSession = (IMAPAsyncConnection *) mSessions->objectAtIndex(i);
        currentSession->setConnectionLogger(logger);
    }
}

ConnectionLogger * IMAPAsyncSession::connectionLogger()
{
    return mConnectionLogger;
}

IMAPMessageRenderingOperation * IMAPAsyncSession::renderingOperation(IMAPMessage * message,
                                                                     String * folder,
                                                                     IMAPMessageRenderingType type)
{
    IMAPMessageRenderingOperation * op = new IMAPMessageRenderingOperation();
    op->setMainSession(this);
    op->setMessage(message);
    op->setFolder(folder);
    op->setRenderingType(type);
    op->autorelease();
    return op;
}

IMAPMessageRenderingOperation * IMAPAsyncSession::htmlRenderingOperation(IMAPMessage * message,
                                                                         String * folder)
{
    return renderingOperation(message, folder, IMAPMessageRenderingTypeHTML);
}

IMAPMessageRenderingOperation * IMAPAsyncSession::htmlBodyRenderingOperation(IMAPMessage * message,
                                                                             String * folder)
{
    return renderingOperation(message, folder, IMAPMessageRenderingTypeHTMLBody);
}

IMAPMessageRenderingOperation * IMAPAsyncSession::plainTextRenderingOperation(IMAPMessage * message,
                                                                              String * folder)
{
    return renderingOperation(message, folder, IMAPMessageRenderingTypePlainText);
}

IMAPMessageRenderingOperation * IMAPAsyncSession::plainTextBodyRenderingOperation(IMAPMessage * message,
                                                                                  String * folder,
                                                                                  bool stripWhitespace)
{
    return renderingOperation(message, folder,
                              stripWhitespace ? IMAPMessageRenderingTypePlainTextBodyAndStripWhitespace :
                              IMAPMessageRenderingTypePlainTextBody);
}

void IMAPAsyncSession::automaticConfigurationDone(IMAPSession * session)
{
    MC_SAFE_REPLACE_COPY(IMAPIdentity, mServerIdentity, session->serverIdentity());
    MC_SAFE_REPLACE_COPY(String, mGmailUserDisplayName, session->gmailUserDisplayName());
    mIdleEnabled = session->isIdleEnabled();
    setDefaultNamespace(session->defaultNamespace());
    mAutomaticConfigurationDone = true;
}

void IMAPAsyncSession::setOperationQueueCallback(OperationQueueCallback * callback)
{
    mOperationQueueCallback = callback;
}

OperationQueueCallback * IMAPAsyncSession::operationQueueCallback()
{
    return mOperationQueueCallback;
}

bool IMAPAsyncSession::isOperationQueueRunning()
{
    return mQueueRunning;
}

void IMAPAsyncSession::cancelAllOperations()
{
    for(unsigned int i = 0 ; i < mSessions->count() ; i ++) {
        IMAPAsyncConnection * currentSession = (IMAPAsyncConnection *) mSessions->objectAtIndex(i);
        currentSession->cancelAllOperations();
    }
}

void IMAPAsyncSession::operationRunningStateChanged()
{
    bool isRunning = false;
    for(unsigned int i = 0 ; i < mSessions->count() ; i ++) {
        IMAPAsyncConnection * currentSession = (IMAPAsyncConnection *) mSessions->objectAtIndex(i);
        if (currentSession->isQueueRunning()){
            isRunning = true;
            break;
        }
    }
    if (mQueueRunning == isRunning) {
        return;
    }
    mQueueRunning = isRunning;
    if (mOperationQueueCallback != NULL) {
        if (isRunning) {
            mOperationQueueCallback->queueStartRunning();
        }
        else {
            mOperationQueueCallback->queueStoppedRunning();
        }
    }
}

#if __APPLE__
void IMAPAsyncSession::setDispatchQueue(dispatch_queue_t dispatchQueue)
{
    if (mDispatchQueue != NULL) {
        dispatch_release(mDispatchQueue);
    }
    mDispatchQueue = dispatchQueue;
    if (mDispatchQueue != NULL) {
        dispatch_retain(mDispatchQueue);
    }
}

dispatch_queue_t IMAPAsyncSession::dispatchQueue()
{
    return mDispatchQueue;
}
#endif
