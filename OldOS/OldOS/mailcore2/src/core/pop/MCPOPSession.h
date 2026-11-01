#ifndef MAILCORE_MCPOPSESSION_H

#define MAILCORE_MCPOPSESSION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {
    
    class POPMessageInfo;
    class POPProgressCallback;
    class MessageHeader;
    
    class MAILCORE_EXPORT POPSession : public Object {
    public:
        POPSession();
        virtual ~POPSession();
        
        virtual void setHostname(String * hostname);
        virtual String * hostname();
        
        virtual void setPort(unsigned int port);
        virtual unsigned int port();
        
        virtual void setUsername(String * username);
        virtual String * username();
        
        virtual void setPassword(String * password);
        virtual String * password();
        
        virtual void setAuthType(AuthType authType);
        virtual AuthType authType();
        
        virtual void setConnectionType(ConnectionType connectionType);
        virtual ConnectionType connectionType();
        
        virtual void setTimeout(time_t timeout);
        virtual time_t timeout();
        
        virtual void setCheckCertificateEnabled(bool enabled);
        virtual bool isCheckCertificateEnabled();
        
        virtual void connect(ErrorCode * pError);
        virtual void disconnect();
        
        virtual void login(ErrorCode * pError);
        
        virtual void checkAccount(ErrorCode * pError);
        
        virtual void noop(ErrorCode * pError);
        
        Array * /* POPMessageInfo */ fetchMessages(ErrorCode * pError);
        
        MessageHeader * fetchHeader(unsigned int index, ErrorCode * pError);
        MessageHeader * fetchHeader(POPMessageInfo * msg, ErrorCode * pError);
        
        Data * fetchMessage(unsigned int index, POPProgressCallback * callback, ErrorCode * pError);
        Data * fetchMessage(POPMessageInfo * msg, POPProgressCallback * callback, ErrorCode * pError);
        
        void deleteMessage(unsigned int index, ErrorCode * pError);
        void deleteMessage(POPMessageInfo * msg, ErrorCode * pError);
        
        virtual void setConnectionLogger(ConnectionLogger * logger);
        virtual ConnectionLogger * connectionLogger();

    public: // private
        virtual void lockConnectionLogger();
        virtual void unlockConnectionLogger();
        virtual ConnectionLogger * connectionLoggerNoLock();

    private:
        String * mHostname;
        unsigned int mPort;
        String * mUsername;
        String * mPassword;
        AuthType mAuthType;
        ConnectionType mConnectionType;
        bool mCheckCertificateEnabled;
        time_t mTimeout;
        
        mailpop3 * mPop;
        POPCapability mCapabilities;
        POPProgressCallback * mProgressCallback;
        int mState;
        
        ConnectionLogger * mConnectionLogger;
        pthread_mutex_t mConnectionLoggerLock;
        
        void init();
        void bodyProgress(unsigned int current, unsigned int maximum);
        bool checkCertificate();
        static void body_progress(size_t current, size_t maximum, void * context);
        void setup();
        void unsetup();
        void connectIfNeeded(ErrorCode * pError);
        void loginIfNeeded(ErrorCode * pError);
        void listIfNeeded(ErrorCode * pError);
    };

}

#endif

#endif
