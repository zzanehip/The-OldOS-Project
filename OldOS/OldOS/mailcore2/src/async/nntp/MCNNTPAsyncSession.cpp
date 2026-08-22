//
//  MCNNTPAsyncSession.cpp
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCNNTPAsyncSession.h"

#include "MCNNTP.h"
#include "MCNNTPFetchHeaderOperation.h"
#include "MCNNTPFetchArticleOperation.h"
#include "MCNNTPFetchAllArticlesOperation.h"
#include "MCNNTPListNewsgroupsOperation.h"
#include "MCNNTPFetchOverviewOperation.h"
#include "MCNNTPCheckAccountOperation.h"
#include "MCNNTPFetchServerTimeOperation.h"
#include "MCNNTPPostOperation.h"
#include "MCNNTPDisconnectOperation.h"
#include "MCOperationQueueCallback.h"
#include "MCConnectionLogger.h"

using namespace mailcore;

namespace mailcore {
    class NNTPOperationQueueCallback  : public Object, public OperationQueueCallback {
    public:
        NNTPOperationQueueCallback(NNTPAsyncSession * session) {
            mSession = session;
        }
        
        virtual ~NNTPOperationQueueCallback() {
        }
        
        virtual void queueStartRunning() {
            mSession->retain();
            if (mSession->operationQueueCallback() != NULL) {
                mSession->operationQueueCallback()->queueStartRunning();
            }
        }
        
        virtual void queueStoppedRunning() {
            if (mSession->operationQueueCallback() != NULL) {
                mSession->operationQueueCallback()->queueStoppedRunning();
            }
            mSession->release();
        }
        
    private:
        NNTPAsyncSession * mSession;
    };
    
    class NNTPConnectionLogger : public Object, public ConnectionLogger {
    public:
        NNTPConnectionLogger(NNTPAsyncSession * session) {
            mSession = session;
        }
        
        virtual ~NNTPConnectionLogger() {
        }
        
        virtual void log(void * sender, ConnectionLogType logType, Data * buffer)
        {
            mSession->logConnection(logType, buffer);
        }
        
    private:
        NNTPAsyncSession * mSession;
    };
    
}

NNTPAsyncSession::NNTPAsyncSession()
{
    mSession = new NNTPSession();
    mQueue = new OperationQueue();
    mQueueCallback = new NNTPOperationQueueCallback(this);
    mQueue->setCallback(mQueueCallback);
    mConnectionLogger = NULL;
    pthread_mutex_init(&mConnectionLoggerLock, NULL);
    mInternalLogger = new NNTPConnectionLogger(this);
    mSession->setConnectionLogger(mInternalLogger);
    mOperationQueueCallback = NULL;
}

NNTPAsyncSession::~NNTPAsyncSession()
{
    MC_SAFE_RELEASE(mInternalLogger);
    pthread_mutex_destroy(&mConnectionLoggerLock);
    MC_SAFE_RELEASE(mQueueCallback);
    MC_SAFE_RELEASE(mSession);
    MC_SAFE_RELEASE(mQueue);
}

void NNTPAsyncSession::setHostname(String * hostname)
{
    mSession->setHostname(hostname);
}

String * NNTPAsyncSession::hostname()
{
    return mSession->hostname();
}

void NNTPAsyncSession::setPort(unsigned int port)
{
    mSession->setPort(port);
}

unsigned int NNTPAsyncSession::port()
{
    return mSession->port();
}

void NNTPAsyncSession::setUsername(String * username)
{
    mSession->setUsername(username);
}

String * NNTPAsyncSession::username()
{
    return mSession->username();
}

void NNTPAsyncSession::setPassword(String * password)
{
    mSession->setPassword(password);
}

String * NNTPAsyncSession::password()
{
    return mSession->password();
}

void NNTPAsyncSession::setConnectionType(ConnectionType connectionType)
{
    mSession->setConnectionType(connectionType);
}

ConnectionType NNTPAsyncSession::connectionType()
{
    return mSession->connectionType();
}

void NNTPAsyncSession::setTimeout(time_t timeout)
{
    mSession->setTimeout(timeout);
}

time_t NNTPAsyncSession::timeout()
{
    return mSession->timeout();
}

void NNTPAsyncSession::setCheckCertificateEnabled(bool enabled)
{
    mSession->setCheckCertificateEnabled(enabled);
}

bool NNTPAsyncSession::isCheckCertificateEnabled()
{
    return mSession->isCheckCertificateEnabled();
}

NNTPFetchAllArticlesOperation * NNTPAsyncSession::fetchAllArticlesOperation(String * group)
{
    NNTPFetchAllArticlesOperation * op = new NNTPFetchAllArticlesOperation();
    op->setSession(this);
    op->setGroupName(group);
    op->autorelease();
    return op;
}

NNTPFetchHeaderOperation * NNTPAsyncSession::fetchHeaderOperation(String * groupName, unsigned int index)
{
    NNTPFetchHeaderOperation * op = new NNTPFetchHeaderOperation();
    op->setSession(this);
    op->setGroupName(groupName);
    op->setMessageIndex(index);
    op->autorelease();
    return op;
}

NNTPFetchArticleOperation * NNTPAsyncSession::fetchArticleOperation(String * groupName, unsigned int index)
{
    NNTPFetchArticleOperation * op = new NNTPFetchArticleOperation();
    op->setSession(this);
    op->setGroupName(groupName);
    op->setMessageIndex(index);
    op->autorelease();
    return op;
}

NNTPFetchArticleOperation * NNTPAsyncSession::fetchArticleByMessageIDOperation(String *messageID)
{
    NNTPFetchArticleOperation * op = new NNTPFetchArticleOperation();
    op->setSession(this);
    op->setMessageID(messageID);
    op->autorelease();
    return op;
}

NNTPFetchOverviewOperation * NNTPAsyncSession::fetchOverviewOperationWithIndexes(String * groupName, IndexSet * indexes)
{
    NNTPFetchOverviewOperation * op = new NNTPFetchOverviewOperation();
    op->setSession(this);
    op->setGroupName(groupName);
    op->setIndexes(indexes);
    op->autorelease();
    return op;
}

NNTPFetchServerTimeOperation * NNTPAsyncSession::fetchServerDateOperation()
{
    NNTPFetchServerTimeOperation * op = new NNTPFetchServerTimeOperation();
    op->setSession(this);
    op->autorelease();
    return op;
}

NNTPListNewsgroupsOperation * NNTPAsyncSession::listAllNewsgroupsOperation()
{
    NNTPListNewsgroupsOperation * op = new NNTPListNewsgroupsOperation();
    op->setSession(this);
    op->setListsSubscribed(false);
    op->autorelease();
    return op;
}

NNTPListNewsgroupsOperation * NNTPAsyncSession::listDefaultNewsgroupsOperation()
{
    NNTPListNewsgroupsOperation * op = new NNTPListNewsgroupsOperation();
    op->setSession(this);
    op->setListsSubscribed(true);
    op->autorelease();
    return op;
}

NNTPPostOperation * NNTPAsyncSession::postMessageOperation(Data * messageData)
{
    NNTPPostOperation * op = new NNTPPostOperation();
    op->setSession(this);
    op->setMessageData(messageData);
    op->autorelease();
    return op;
}

NNTPPostOperation * NNTPAsyncSession::postMessageOperation(String * filename)
{
    NNTPPostOperation * op = new NNTPPostOperation();
    op->setSession(this);
    op->setMessageFilepath(filename);
    op->autorelease();
    return op;
}

NNTPOperation * NNTPAsyncSession::disconnectOperation()
{
    NNTPDisconnectOperation * op = new NNTPDisconnectOperation();
    op->setSession(this);
    op->autorelease();
    return op;
}

NNTPOperation * NNTPAsyncSession::checkAccountOperation()
{
    NNTPCheckAccountOperation * op = new NNTPCheckAccountOperation();
    op->setSession(this);
    op->autorelease();
    return op;
}

NNTPSession * NNTPAsyncSession::session()
{
    return mSession;
}

void NNTPAsyncSession::runOperation(NNTPOperation * operation)
{
    mQueue->addOperation(operation);
}

void NNTPAsyncSession::setConnectionLogger(ConnectionLogger * logger)
{
    pthread_mutex_lock(&mConnectionLoggerLock);
    mConnectionLogger = logger;
    pthread_mutex_unlock(&mConnectionLoggerLock);
    if (logger != NULL) {
        mSession->setConnectionLogger(mInternalLogger);
    }
    else {
        mSession->setConnectionLogger(NULL);
    }
}

ConnectionLogger * NNTPAsyncSession::connectionLogger()
{
    ConnectionLogger * result;
    
    pthread_mutex_lock(&mConnectionLoggerLock);
    result = mConnectionLogger;
    pthread_mutex_unlock(&mConnectionLoggerLock);
    
    return result;
}

void NNTPAsyncSession::logConnection(ConnectionLogType logType, Data * buffer)
{
    pthread_mutex_lock(&mConnectionLoggerLock);
    if (mConnectionLogger != NULL) {
        mConnectionLogger->log(this, logType, buffer);
    }
    pthread_mutex_unlock(&mConnectionLoggerLock);
}

#if __APPLE__
void NNTPAsyncSession::setDispatchQueue(dispatch_queue_t dispatchQueue)
{
    mQueue->setDispatchQueue(dispatchQueue);
}

dispatch_queue_t NNTPAsyncSession::dispatchQueue()
{
    return mQueue->dispatchQueue();
}
#endif

void NNTPAsyncSession::setOperationQueueCallback(OperationQueueCallback * callback)
{
    mOperationQueueCallback = callback;
}

OperationQueueCallback * NNTPAsyncSession::operationQueueCallback()
{
    return mOperationQueueCallback;
}

bool NNTPAsyncSession::isOperationQueueRunning()
{
    return mQueue->count() > 0;
}

void NNTPAsyncSession::cancelAllOperations()
{
    mQueue->cancelAllOperations();
}
