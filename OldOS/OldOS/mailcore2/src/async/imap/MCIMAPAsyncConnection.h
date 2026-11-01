#ifndef MAILCORE_MCIMAPASYNCCONNECTION_H

#define MAILCORE_MCIMAPASYNCCONNECTION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {
    
    class IMAPOperation;
    class IMAPFetchFoldersOperation;
    class IMAPAppendMessageOperation;
    class IMAPCopyMessagesOperation;
    class IMAPFetchMessagesOperation;
    class IMAPFetchContentOperation;
    class IMAPFetchContentToFileOperation;
    class IMAPFetchParsedContentOperation;
    class IMAPIdleOperation;
    class IMAPFolderInfoOperation;
    class IMAPFolderStatusOperation;
    class IMAPSession;
    class IMAPNamespace;
    class IMAPSearchOperation;
    class IMAPSearchExpression;
    class IMAPFetchNamespaceOperation;
    class IMAPIdentityOperation;
    class IMAPCapabilityOperation;
    class IMAPQuotaOperation;
    class IMAPOperationQueueCallback;
    class IMAPAsyncSession;
    class IMAPConnectionLogger;
    class IMAPMessageRenderingOperation;
    class IMAPMessage;
    class IMAPIdentity;
    
    class MAILCORE_EXPORT IMAPAsyncConnection : public Object {
    public:
        IMAPAsyncConnection();
        virtual ~IMAPAsyncConnection();
        
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
        
        virtual void setVoIPEnabled(bool enabled);
        virtual bool isVoIPEnabled();
        
        virtual void setAutomaticConfigurationEnabled(bool enabled);
        virtual bool isAutomaticConfigurationEnabled();
        
        // Needs to be run before starting a connection.
        virtual void setDefaultNamespace(IMAPNamespace * ns);
        virtual IMAPNamespace * defaultNamespace();
        
        virtual void setClientIdentity(IMAPIdentity * identity);
        virtual IMAPIdentity * clientIdentity();
        
        virtual void setConnectionLogger(ConnectionLogger * logger);
        virtual ConnectionLogger * connectionLogger();
        
#ifdef __APPLE__
        virtual void setDispatchQueue(dispatch_queue_t dispatchQueue);
        virtual dispatch_queue_t dispatchQueue();
#endif
        
        virtual IMAPOperation * disconnectOperation();

    private:
        IMAPSession * mSession;
        OperationQueue * mQueue;
        IMAPNamespace * mDefaultNamespace;
        IMAPIdentity * mClientIdentity;
        String * mLastFolder;
        IMAPOperationQueueCallback * mQueueCallback;
        IMAPAsyncSession * mOwner;
        ConnectionLogger * mConnectionLogger;
        IMAPConnectionLogger * mInternalLogger;
        pthread_mutex_t mConnectionLoggerLock;
        bool mAutomaticConfigurationEnabled;
        bool mQueueRunning;
        bool mScheduledAutomaticDisconnect;
        
        virtual void tryAutomaticDisconnectAfterDelay(void * context);

    public: // private
        virtual void runOperation(IMAPOperation * operation);
        virtual IMAPSession * session();
        
        virtual void cancelAllOperations();
        virtual unsigned int operationsCount();
        
        virtual void setLastFolder(String * folder);
        virtual String * lastFolder();
        
        virtual void tryAutomaticDisconnect();
        virtual void queueStartRunning();
        virtual void queueStoppedRunning();
        
        virtual void setOwner(IMAPAsyncSession * owner);
        virtual IMAPAsyncSession * owner();

        virtual void logConnection(ConnectionLogType logType, Data * buffer);
        
        virtual bool isQueueRunning();
        virtual void setQueueRunning(bool running);
    };
    
}

#endif

#endif
