//
//  MCPopAsyncSession.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/16/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCPOPAsyncSession.h"

#include "MCPOP.h"
#include "MCPOPFetchHeaderOperation.h"
#include "MCPOPFetchMessageOperation.h"
#include "MCPOPDeleteMessagesOperation.h"
#include "MCPOPFetchMessagesOperation.h"
#include "MCPOPCheckAccountOperation.h"
#include "MCPOPNoopOperation.h"
#include "MCOperationQueueCallback.h"
#include "MCConnectionLogger.h"

using namespace mailcore;

namespace mailcore {
    class POPOperationQueueCallback  : public Object, public OperationQueueCallback {
    public:
        POPOperationQueueCallback(POPAsyncSession * session) {
            mSession = session;
        }
        
        virtual ~POPOperationQueueCallback() {
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
        POPAsyncSession * mSession;
    };
    
    class POPConnectionLogger : public Object, public ConnectionLogger {
    public:
        POPConnectionLogger(POPAsyncSession * session) {
            mSession = session;
        }
        
        virtual ~POPConnectionLogger() {
        }
        
        virtual void log(void * sender, ConnectionLogType logType, Data * buffer)
        {
            mSession->logConnection(logType, buffer);
        }
        
    private:
        POPAsyncSession * mSession;
    };
    
}

POPAsyncSession::POPAsyncSession()
{
    mSession = new POPSession();
    mQueue = new OperationQueue();
    mQueueCallback = new POPOperationQueueCallback(this);
    mQueue->setCallback(mQueueCallback);
    mConnectionLogger = NULL;
    pthread_mutex_init(&mConnectionLoggerLock, NULL);
    mInternalLogger = new POPConnectionLogger(this);
    mSession->setConnectionLogger(mInternalLogger);
    mOperationQueueCallback = NULL;
}

POPAsyncSession::~POPAsyncSession()
{
    MC_SAFE_RELEASE(mInternalLogger);
    pthread_mutex_destroy(&mConnectionLoggerLock);
    MC_SAFE_RELEASE(mQueueCallback);
    MC_SAFE_RELEASE(mSession);
    MC_SAFE_RELEASE(mQueue);
}

void POPAsyncSession::setHostname(String * hostname)
{
    mSession->setHostname(hostname);
}

String * POPAsyncSession::hostname()
{
    return mSession->hostname();
}

void POPAsyncSession::setPort(unsigned int port)
{
    mSession->setPort(port);
}

unsigned int POPAsyncSession::port()
{
    return mSession->port();
}

void POPAsyncSession::setUsername(String * username)
{
    mSession->setUsername(username);
}

String * POPAsyncSession::username()
{
    return mSession->username();
}

void POPAsyncSession::setPassword(String * password)
{
    mSession->setPassword(password);
}

String * POPAsyncSession::password()
{
    return mSession->password();
}

void POPAsyncSession::setAuthType(AuthType authType)
{
    mSession->setAuthType(authType);
}

AuthType POPAsyncSession::authType()
{
    return mSession->authType();
}

void POPAsyncSession::setConnectionType(ConnectionType connectionType)
{
    mSession->setConnectionType(connectionType);
}

ConnectionType POPAsyncSession::connectionType()
{
    return mSession->connectionType();
}

void POPAsyncSession::setTimeout(time_t timeout)
{
    mSession->setTimeout(timeout);
}

time_t POPAsyncSession::timeout()
{
    return mSession->timeout();
}

void POPAsyncSession::setCheckCertificateEnabled(bool enabled)
{
    mSession->setCheckCertificateEnabled(enabled);
}

bool POPAsyncSession::isCheckCertificateEnabled()
{
    return mSession->isCheckCertificateEnabled();
}

POPFetchMessagesOperation * POPAsyncSession::fetchMessagesOperation()
{
    POPFetchMessagesOperation * op = new POPFetchMessagesOperation();
    op->setSession(this);
    op->autorelease();
    return op;
}

POPFetchHeaderOperation * POPAsyncSession::fetchHeaderOperation(unsigned int index)
{
    POPFetchHeaderOperation * op = new POPFetchHeaderOperation();
    op->setSession(this);
    op->setMessageIndex(index);
    op->autorelease();
    return op;
}

POPFetchMessageOperation * POPAsyncSession::fetchMessageOperation(unsigned int index)
{
    POPFetchMessageOperation * op = new POPFetchMessageOperation();
    op->setSession(this);
    op->setMessageIndex(index);
    op->autorelease();
    return op;
}

POPOperation * POPAsyncSession::deleteMessagesOperation(IndexSet * indexes)
{
    POPDeleteMessagesOperation * op = new POPDeleteMessagesOperation();
    op->setSession(this);
    op->setMessageIndexes(indexes);
    op->autorelease();
    return op;
}

POPOperation * POPAsyncSession::disconnectOperation()
{
    return deleteMessagesOperation(IndexSet::indexSet());
}

POPOperation * POPAsyncSession::checkAccountOperation()
{
    POPCheckAccountOperation * op = new POPCheckAccountOperation();
    op->setSession(this);
    op->autorelease();
    return op;
}

POPOperation * POPAsyncSession::noopOperation()
{
    POPNoopOperation * op = new POPNoopOperation();
    op->setSession(this);
    op->autorelease();
    return op;
}

POPSession * POPAsyncSession::session()
{
    return mSession;
}

void POPAsyncSession::runOperation(POPOperation * operation)
{
    mQueue->addOperation(operation);
}

void POPAsyncSession::setConnectionLogger(ConnectionLogger * logger)
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

ConnectionLogger * POPAsyncSession::connectionLogger()
{
    ConnectionLogger * result;
    
    pthread_mutex_lock(&mConnectionLoggerLock);
    result = mConnectionLogger;
    pthread_mutex_unlock(&mConnectionLoggerLock);
    
    return result;
}

void POPAsyncSession::logConnection(ConnectionLogType logType, Data * buffer)
{
    pthread_mutex_lock(&mConnectionLoggerLock);
    if (mConnectionLogger != NULL) {
        mConnectionLogger->log(this, logType, buffer);
    }
    pthread_mutex_unlock(&mConnectionLoggerLock);
}

#if __APPLE__
void POPAsyncSession::setDispatchQueue(dispatch_queue_t dispatchQueue)
{
    mQueue->setDispatchQueue(dispatchQueue);
}

dispatch_queue_t POPAsyncSession::dispatchQueue()
{
    return mQueue->dispatchQueue();
}
#endif

void POPAsyncSession::setOperationQueueCallback(OperationQueueCallback * callback)
{
    mOperationQueueCallback = callback;
}

OperationQueueCallback * POPAsyncSession::operationQueueCallback()
{
    return mOperationQueueCallback;
}

bool POPAsyncSession::isOperationQueueRunning()
{
    return mQueue->count() > 0;
}

void POPAsyncSession::cancelAllOperations()
{
    mQueue->cancelAllOperations();
}
