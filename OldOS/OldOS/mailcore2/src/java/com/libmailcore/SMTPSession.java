package com.libmailcore;

import java.util.List;

public class SMTPSession extends NativeObject {
    public SMTPSession()
    {
        setupNative();
    }
    
    protected void finalize() throws Throwable
    {
        finalizeNative();
        super.finalize();
    }
    
    /** Sets the SMTP server hostname. */
    public native void setHostname(String hostname);
    /** Returns the SMTP server hostname. */
    public native String hostname();
    
    /** Sets the port. */
    public native void setPort(int port);
    /** Returns the port. */
    public native int port();
    
    /** Sets the username. */
    public native void setUsername(String username);
    /** Returns the username. */
    public native String username();

    /** Sets the password. */
    public native void setPassword(String password);
    /** Returns the password. */
    public native String password();

    /** Sets the OAuth2 token. */
    public native void setOAuth2Token(String token);
    /** Returns the OAuth2 token. */
    public native String OAuth2Token();
    
    /**
        Sets the authentication type.
        @see com.libmailcore.AuthType
    */
    public native void setAuthType(int authType);
    /**
        Returns authentication type.
        @see com.libmailcore.AuthType
    */
    public native int authType();
    
    /**
        Set connection type (clear-text, SSL or STARTTLS).
        @see com.libmailcore.ConnectionType
    */
    public native void setConnectionType(int connectionType);
    /**
        Returns connection type (clear-text, SSL or STARTTLS).
        @see com.libmailcore.ConnectionType
    */
    public native int connectionType();
    
    /** Sets network timeout in seconds. */
    public native void setTimeout(long seconds);
    /** Returns network timeout in seconds. */
    public native long timeout();
    
    /** Sets whether the certificate of the server should be checked. */
    public native void setCheckCertificateEnabled(boolean enabled);
    /** Returns whether the certificate of the server should be checked. */
    public native boolean isCheckCertificateEnabled();

    /** Sets whether it should use the IP address while using EHLO. */
    public native void setUseHeloIPEnabled(boolean enabled);
    /** Returns whether it should use the IP address while using EHLO. */
    public native boolean useHeloIPEnabled();

    /** Sets the connection logger. */
    public void setConnectionLogger(ConnectionLogger logger)
    {
        connectionLogger = logger;
        setupNativeConnectionLogger();
    }
    
    /** Returns the connection logger. */
    public ConnectionLogger connectionLogger()
    {
        return connectionLogger;
    }

    /** Sets the IMAP operations queue listener. */
    public void setOperationQueueListener(OperationQueueListener listener)
    {
        operationQueueListener = listener;
        setupNativeOperationQueueListener();
    }
    
    /** Returns the IMAP operations queue listener. */
    public OperationQueueListener operationQueueListener()
    {
        return operationQueueListener;
    }
    
    /** Returns whether the operation queue is running. */
    public native boolean isOperationQueueRunning();
    /** Cancels all queued operations. */
    public native void cancelAllOperations();

    /** Returns an operation to authenticate. */
    public native SMTPOperation loginOperation();
    /** Returns an operation to send a message. The recipient is detected in the data of the message. */
    public native SMTPOperation sendMessageOperation(byte[] messageData);
    /** Returns an operation to send a message. */
    public native SMTPOperation sendMessageOperation(Address from, List<Address> recipients, byte[] messageData);
    /** Returns an operation to check whether the credentials of the account are correct. */
    public native SMTPOperation checkAccountOperation(Address from);
    /** Returns a SMTP NOOP operation. */
    public native SMTPOperation noopOperation();

    private native void setupNative();
    private native void finalizeNative();
    
    private ConnectionLogger connectionLogger;
    private OperationQueueListener operationQueueListener;
    
    private native void setupNativeOperationQueueListener();
    private native void setupNativeConnectionLogger();
}
