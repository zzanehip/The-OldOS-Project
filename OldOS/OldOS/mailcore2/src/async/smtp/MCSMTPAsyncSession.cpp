#include "MCSMTPAsyncSession.h"

#include "MCSMTPSession.h"
#include "MCSMTPLoginOperation.h"
#include "MCSMTPSendWithDataOperation.h"
#include "MCSMTPCheckAccountOperation.h"
#include "MCSMTPDisconnectOperation.h"
#include "MCSMTPNoopOperation.h"
#include "MCSMTPOperation.h"
#include "MCOperationQueueCallback.h"

using namespace mailcore;

namespace mailcore {
    
    class SMTPOperationQueueCallback  : public Object, public OperationQueueCallback {
    public:
        SMTPOperationQueueCallback(SMTPAsyncSession * session) {
            mSession = session;
        }
        
        virtual ~SMTPOperationQueueCallback() {
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
            mSession->tryAutomaticDisconnect();
            mSession->release();
        }
        
    private:
        SMTPAsyncSession * mSession;
    };
    
    class SMTPConnectionLogger : public Object, public ConnectionLogger {
    public:
        SMTPConnectionLogger(SMTPAsyncSession * session) {
            mSession = session;
        }
        
        virtual ~SMTPConnectionLogger() {
        }
        
        virtual void log(void * sender, ConnectionLogType logType, Data * buffer)
        {
            mSession->logConnection(logType, buffer);
        }
        
    private:
        SMTPAsyncSession * mSession;
    };
    
}

SMTPAsyncSession::SMTPAsyncSession()
{
    mSession = new SMTPSession();
    mQueue = new OperationQueue();
    mQueueCallback = new SMTPOperationQueueCallback(this);
    mQueue->setCallback(mQueueCallback);
    mConnectionLogger = NULL;
    pthread_mutex_init(&mConnectionLoggerLock, NULL);
    mInternalLogger = new SMTPConnectionLogger(this);
    mSession->setConnectionLogger(mInternalLogger);
    mOperationQueueCallback = NULL;
}

SMTPAsyncSession::~SMTPAsyncSession()
{
    MC_SAFE_RELEASE(mInternalLogger);
    pthread_mutex_destroy(&mConnectionLoggerLock);
    cancelDelayedPerformMethod((Object::Method) &SMTPAsyncSession::tryAutomaticDisconnectAfterDelay, NULL);
    MC_SAFE_RELEASE(mQueueCallback);
    MC_SAFE_RELEASE(mQueue);
    MC_SAFE_RELEASE(mSession);
}

void SMTPAsyncSession::setHostname(String * hostname)
{
    mSession->setHostname(hostname);
}

String * SMTPAsyncSession::hostname()
{
    return mSession->hostname();
}

void SMTPAsyncSession::setPort(unsigned int port)
{
    mSession->setPort(port);
}

unsigned int SMTPAsyncSession::port()
{
    return mSession->port();
}

void SMTPAsyncSession::setUsername(String * username)
{
    return mSession->setUsername(username);
}

String * SMTPAsyncSession::username()
{
    return mSession->username();
}

void SMTPAsyncSession::setPassword(String * password)
{
    mSession->setPassword(password);
}

String * SMTPAsyncSession::password()
{
    return mSession->password();
}

void SMTPAsyncSession::setOAuth2Token(String * token)
{
    mSession->setOAuth2Token(token);
}

String * SMTPAsyncSession::OAuth2Token()
{
    return mSession->OAuth2Token();
}

void SMTPAsyncSession::setAuthType(AuthType authType)
{
    mSession->setAuthType(authType);
}

AuthType SMTPAsyncSession::authType()
{
    return mSession->authType();
}

void SMTPAsyncSession::setConnectionType(ConnectionType connectionType)
{
    mSession->setConnectionType(connectionType);
}

ConnectionType SMTPAsyncSession::connectionType()
{
    return mSession->connectionType();
}

void SMTPAsyncSession::setTimeout(time_t timeout)
{
    return mSession->setTimeout(timeout);
}

time_t SMTPAsyncSession::timeout()
{
    return mSession->timeout();
}

void SMTPAsyncSession::setCheckCertificateEnabled(bool enabled)
{
    return mSession->setCheckCertificateEnabled(enabled);
}

bool SMTPAsyncSession::isCheckCertificateEnabled()
{
    return mSession->isCheckCertificateEnabled();
}

void SMTPAsyncSession::setUseHeloIPEnabled(bool enabled)
{
    mSession->setUseHeloIPEnabled(enabled);
}

bool SMTPAsyncSession::useHeloIPEnabled()
{
    return mSession->useHeloIPEnabled();
}

void SMTPAsyncSession::runOperation(SMTPOperation * operation)
{
    cancelDelayedPerformMethod((Object::Method) &SMTPAsyncSession::tryAutomaticDisconnectAfterDelay, NULL);
    mQueue->addOperation(operation);
}

SMTPSession * SMTPAsyncSession::session()
{
    return mSession;
}

void SMTPAsyncSession::tryAutomaticDisconnect()
{
    // It's safe since no thread is running when this function is called.
    if (mSession->isDisconnected()) {
        return;
    }
    
    cancelDelayedPerformMethod((Object::Method) &SMTPAsyncSession::tryAutomaticDisconnectAfterDelay, NULL);
    performMethodAfterDelay((Object::Method) &SMTPAsyncSession::tryAutomaticDisconnectAfterDelay, NULL, 30);
}

void SMTPAsyncSession::tryAutomaticDisconnectAfterDelay(void * context)
{
    SMTPDisconnectOperation * op = new SMTPDisconnectOperation();
    op->setSession(this);
    op->autorelease();
    op->start();
}

SMTPOperation * SMTPAsyncSession::loginOperation()
{
    SMTPLoginOperation * op = new SMTPLoginOperation();
    op->setSession(this);
    return (SMTPOperation *) op->autorelease();
}

SMTPOperation * SMTPAsyncSession::sendMessageOperation(Data * messageData)
{
    SMTPSendWithDataOperation * op = new SMTPSendWithDataOperation();
    op->setSession(this);
    op->setMessageData(messageData);
    return (SMTPOperation *) op->autorelease();
}

SMTPOperation * SMTPAsyncSession::sendMessageOperation(Address * from, Array * recipients,
                                                       Data * messageData)
{
    SMTPSendWithDataOperation * op = new SMTPSendWithDataOperation();
    op->setSession(this);
    op->setMessageData(messageData);
    op->setFrom(from);
    op->setRecipients(recipients);
    return (SMTPOperation *) op->autorelease();
}

SMTPOperation * SMTPAsyncSession::sendMessageOperation(Address * from, Array * recipients,
                                                       String * filename)
{
    SMTPSendWithDataOperation * op = new SMTPSendWithDataOperation();
    op->setSession(this);
    op->setMessageFilepath(filename);
    op->setFrom(from);
    op->setRecipients(recipients);
    return (SMTPOperation *) op->autorelease();
}

SMTPOperation * SMTPAsyncSession::checkAccountOperation(Address * from)
{
    SMTPCheckAccountOperation * op = new SMTPCheckAccountOperation();
    op->setFrom(from);
    op->setSession(this);
    return (SMTPOperation *) op->autorelease();
}

SMTPOperation * SMTPAsyncSession::noopOperation()
{
    SMTPNoopOperation * op = new SMTPNoopOperation();
    op->setSession(this);
    return (SMTPOperation *) op->autorelease();
}

SMTPOperation * SMTPAsyncSession::disconnectOperation()
{
    SMTPDisconnectOperation * op = new SMTPDisconnectOperation();
    op->setSession(this);
    return (SMTPOperation *) op->autorelease();
}

void SMTPAsyncSession::setConnectionLogger(ConnectionLogger * logger)
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

ConnectionLogger * SMTPAsyncSession::connectionLogger()
{
    ConnectionLogger * result;
    
    pthread_mutex_lock(&mConnectionLoggerLock);
    result = mConnectionLogger;
    pthread_mutex_unlock(&mConnectionLoggerLock);
    
    return result;
}

void SMTPAsyncSession::logConnection(ConnectionLogType logType, Data * buffer)
{
    pthread_mutex_lock(&mConnectionLoggerLock);
    if (mConnectionLogger != NULL) {
        mConnectionLogger->log(this, logType, buffer);
    }
    pthread_mutex_unlock(&mConnectionLoggerLock);
}

#if __APPLE__
void SMTPAsyncSession::setDispatchQueue(dispatch_queue_t dispatchQueue)
{
    mQueue->setDispatchQueue(dispatchQueue);
}

dispatch_queue_t SMTPAsyncSession::dispatchQueue()
{
    return mQueue->dispatchQueue();
}
#endif

void SMTPAsyncSession::setOperationQueueCallback(OperationQueueCallback * callback)
{
    mOperationQueueCallback = callback;
}

OperationQueueCallback * SMTPAsyncSession::operationQueueCallback()
{
    return mOperationQueueCallback;
}

bool SMTPAsyncSession::isOperationQueueRunning()
{
    return mQueue->count() > 0;
}

void SMTPAsyncSession::cancelAllOperations()
{
    mQueue->cancelAllOperations();
}
