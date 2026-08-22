package com.libmailcore;

public class NNTPSession extends NativeObject {
    public NNTPSession()
    {
        setupNative();
    }
    
    protected void finalize() throws Throwable
    {
        finalizeNative();
        super.finalize();
    }
    
    /** Sets the NNTP server hostname. */
    public native void setHostname(String hostname);
    /** Returns the NNTP server hostname. */
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

    /** Returns an operation to fetch the list of numbers of all articles of a newsgroup. */
    public native NNTPFetchAllArticlesOperation fetchAllArticlesOperation(String group);
    /** Returns an operation to fetch the headers of a given article. */
    public native NNTPFetchHeaderOperation fetchHeaderOperation(String group, int idx);
    /** Returns an operation to fetch the content of a given article. */
    public native NNTPFetchArticleOperation fetchArticleOperation(String group, int idx);
    /** Returns an operation to fetch the content of a given articl using the Message-ID. */
    public native NNTPFetchArticleOperation fetchArticleByMessageIDOperation(String messageID);
    /** Returns an operation to fetch the summary headers of set of articles of a newsgroup. */
    public native NNTPFetchOverviewOperation fetchOverviewOperationWithIndexes(String group, IndexSet indexes);
    /** Returns an operation to fetch the server date. */
    public native NNTPFetchServerTimeOperation fetchServerDateOperation();
    /** Returns an operation to fetch the list of all newsgroups. */
    public native NNTPListNewsgroupsOperation listAllNewsgroupsOperation();
    /** Returns an operation to fetch the ist of default newsgroups. */
    public native NNTPListNewsgroupsOperation listDefaultNewsgroupsOperation();
    /** Returns an operation to disconnect. */
    public native NNTPOperation disconnectOperation();
    /** Returns an operation to check credentials. */
    public native NNTPOperation checkAccountOperation();
    
    private native void setupNative();
    private native void finalizeNative();
    
    private ConnectionLogger connectionLogger;
    private OperationQueueListener operationQueueListener;
    
    private native void setupNativeOperationQueueListener();
    private native void setupNativeConnectionLogger();
}
