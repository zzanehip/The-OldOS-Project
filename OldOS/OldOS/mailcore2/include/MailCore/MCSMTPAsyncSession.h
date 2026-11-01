#ifndef MAILCORE_MCSMTPASYNCSESSION_H

#define MAILCORE_MCSMTPASYNCSESSION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MessageBuilder;
    class SMTPOperation;
    class SMTPSession;
    class Address;
    class SMTPOperationQueueCallback;
    class SMTPConnectionLogger;
    
    class MAILCORE_EXPORT SMTPAsyncSession : public Object {
    public:
        SMTPAsyncSession();
        virtual ~SMTPAsyncSession();
        
        virtual void setHostname(String * hostname);
        virtual String * hostname();
        
        virtual void setPort(unsigned int port);
        virtual unsigned int port();
        
        virtual void setUsername(String * username);
        virtual String * username();
        
        virtual void setPassword(String * password);
        virtual String * password();
        
        virtual void setOAuth2Token(String * token);
        virtual String * OAuth2Token();
        
        virtual void setAuthType(AuthType authType);
        virtual AuthType authType();
        
        virtual void setConnectionType(ConnectionType connectionType);
        virtual ConnectionType connectionType();
        
        virtual void setTimeout(time_t timeout);
        virtual time_t timeout();
        
        virtual void setCheckCertificateEnabled(bool enabled);
        virtual bool isCheckCertificateEnabled();
        
        virtual void setUseHeloIPEnabled(bool enabled);
        virtual bool useHeloIPEnabled();
        
        virtual void setConnectionLogger(ConnectionLogger * logger);
        virtual ConnectionLogger * connectionLogger();
        
#ifdef __APPLE__
        virtual void setDispatchQueue(dispatch_queue_t dispatchQueue);
        virtual dispatch_queue_t dispatchQueue();
#endif

        virtual void setOperationQueueCallback(OperationQueueCallback * callback);
        virtual OperationQueueCallback * operationQueueCallback();
        virtual bool isOperationQueueRunning();
        virtual void cancelAllOperations();

        virtual SMTPOperation * loginOperation();
        virtual SMTPOperation * sendMessageOperation(Data * messageData);
        virtual SMTPOperation * sendMessageOperation(Address * from, Array * recipients,
                                                     Data * messageData);
        virtual SMTPOperation * sendMessageOperation(Address * from, Array * recipients,
                                                     String * filename);
        virtual SMTPOperation * checkAccountOperation(Address * from);
        
        virtual SMTPOperation * noopOperation();
        
        virtual SMTPOperation * disconnectOperation();

    public: // private
        virtual void runOperation(SMTPOperation * operation);
        virtual SMTPSession * session();
        virtual void tryAutomaticDisconnect();
        virtual void logConnection(ConnectionLogType logType, Data * buffer);
        
    private:
        SMTPSession * mSession;
        OperationQueue * mQueue;
        SMTPOperationQueueCallback * mQueueCallback;
        ConnectionLogger * mConnectionLogger;
        pthread_mutex_t mConnectionLoggerLock;
        SMTPConnectionLogger * mInternalLogger;
        OperationQueueCallback * mOperationQueueCallback;
        
        virtual void tryAutomaticDisconnectAfterDelay(void * context);
    };
	
}

#endif

#endif
