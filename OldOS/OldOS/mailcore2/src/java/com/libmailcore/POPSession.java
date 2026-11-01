package com.libmailcore;

public class POPSession extends NativeObject {
    public POPSession()
    {
        setupNative();
    }
    
    protected void finalize() throws Throwable
    {
        finalizeNative();
        super.finalize();
    }
    
    /** Sets the POP server hostname. */
    public native void setHostname(String hostname);
    /** Returns the POP server hostname. */
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

    /** Returns an operation to fetch the list of messages. */
    public native POPFetchMessagesOperation fetchMessagesOperation();
    /** Returns an operation to fetch headers of a given message. */
    public native POPFetchHeaderOperation fetchHeaderOperation(int index);
    /** Returns an operation to fetch the content of a given message. */
    public native POPFetchMessageOperation fetchMessageOperation(int index);
    /** Returns an operation to delete messages. */
    public native POPOperation deleteMessagesOperation(IndexSet indexes);
    /** Returns an operation to disconnect. */
    public native POPOperation disconnectOperation();
    /** Returns an operation to check credentials. */
    public native POPOperation checkAccountOperation();
    /** Returns a POP NOOP operation. */
    public native POPOperation noopOperation();

    private native void setupNative();
    private native void finalizeNative();
    
    private ConnectionLogger connectionLogger;
    private OperationQueueListener operationQueueListener;
    
    private native void setupNativeOperationQueueListener();
    private native void setupNativeConnectionLogger();
}
