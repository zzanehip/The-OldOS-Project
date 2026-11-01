package com.libmailcore;

import java.util.List;

/** IMAP session. */
public class IMAPSession extends NativeObject {
    /** Constructor for the IMAPSession. */
    public IMAPSession()
    {
        setupNative();
    }
    
    protected void finalize() throws Throwable
    {
        finalizeNative();
        super.finalize();
    }
    
    /** Sets the IMAP server hostname. */
    public native void setHostname(String hostname);
    /** Returns the IMAP server hostname. */
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
    
    /** Sets the default namespace. */
    public native void setDefaultNamespace(IMAPNamespace ns);
    /** Returns the default namespace. */
    public native IMAPNamespace defaultNamespace();
    
    /** Set whether the IMAP session can access folders using several IMAP connections. */
    public native void setAllowsFolderConcurrentAccessEnabled(boolean enabled);
    /** Returns whether the IMAP session can access folders using several IMAP connections. */
    public native boolean allowsFolderConcurrentAccessEnabled();
    
    /** Sets the maximum number of IMAP connections to use. */
    public native void setMaximumConnections(int maxConnections);
    /** Returns the maximum number of IMAP connections to use. */
    public native int maximumConnections();
    
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
    
    /** Returns server identity. */
    public native IMAPIdentity serverIdentity();
    /** Returns client identity. It can be modified before establishing connection. */
    public native IMAPIdentity clientIdentity();
    
    /** Returns the Gmail user display name. */
    public native String gmailUserDisplayName();
    
    /** Returns an operation to request the folder info. */
    public native IMAPFolderInfoOperation folderInfoOperation(String folder);
    /** Returns an operation to request the folder status. */
    public native IMAPFolderStatusOperation folderStatusOperation(String folder);
    
    /** Returns an operation to request the list of subscribed folders. */
    public native IMAPFetchFoldersOperation fetchSubscribedFoldersOperation();
    /** Returns an operation to request the list of all folders. */
    public native IMAPFetchFoldersOperation fetchAllFoldersOperation();
    
    /** Returns an operation to rename a folder. */
    public native IMAPOperation renameFolderOperation(String folder, String otherName);
    /** Returns an operation to delete a folder. */
    public native IMAPOperation deleteFolderOperation(String folder);
    /** Returns an operation to create a folder. */
    public native IMAPOperation createFolderOperation(String folder);
    
    /** Returns an operation to subscribe a folder. */
    public native IMAPOperation subscribeFolderOperation(String folder);
    /** Returns an operation to unsubscribe a folder. */
    public native IMAPOperation unsubscribeFolderOperation(String folder);
    
    /** Returns an operation to append a message to a folder. */
    public native IMAPAppendMessageOperation appendMessageOperation(String folder, byte[] messageData, int messageFlags, List<String> customFlags);
    /** Returns an operation to append a message to a folder. */
    public IMAPAppendMessageOperation appendMessageOperation(String folder, byte[] messageData, int messageFlags)
    {
        return appendMessageOperation(folder, messageData, messageFlags, null);
    }
    
    /** Returns an operation to copy messages to a folder. */
    public native IMAPCopyMessagesOperation copyMessagesOperation(String folder, IndexSet uids, String destFolder);
    
    /** Returns an operation to move messages to a folder. */
    public native IMAPMoveMessagesOperation moveMessagesOperation(String folder, IndexSet uids, String destFolder);
    
    /** Returns an operation to expunge messages after they've been marked as deleted. */
    public native IMAPOperation expungeOperation(String folder);
    
    /** Returns an operation to fetch a list of messages by UID. */
    public native IMAPFetchMessagesOperation fetchMessagesByUIDOperation(String folder, int requestKind, IndexSet indexes);
    /** Returns an operation to fetch a list of messages by sequence number. */
    public native  IMAPFetchMessagesOperation fetchMessagesByNumberOperation(String folder, int requestKind, IndexSet indexes);
    /** Returns an operation to sync a list of messages. */
    public native  IMAPFetchMessagesOperation syncMessagesByUIDOperation(String folder, int requestKind, IndexSet indexes, long modSeq);
    
    /** Returns an operation to fetch a message content by UID. */
    public native IMAPFetchContentOperation fetchMessageByUIDOperation(String folder, long uid, boolean urgent);
    /** Returns an operation to fetch a message content by UID. */
    public IMAPFetchContentOperation fetchMessageByUIDOperation(String folder, long uid)
    {
        return fetchMessageByUIDOperation(folder, uid, false);
    }
    
    /** Returns an operation to fetch an attachment content using the UID of a message. */
    public native IMAPFetchContentOperation fetchMessageAttachmentByUIDOperation(String folder, long uid, String partID,
                                                                                 int encoding, boolean urgent);
    /** Returns an operation to fetch an attachment content using the UID of a message. */
    public IMAPFetchContentOperation fetchMessageAttachmentByUIDOperation(String folder, long uid, String partID,
                                                                          int encoding)
    {
        return fetchMessageAttachmentByUIDOperation(folder, uid, partID, encoding, false);
    }
    
    /** Returns an operation to fetch a message content by sequence number. */
    public native IMAPFetchContentOperation fetchMessageByNumberOperation(String folder, long number, boolean urgent);
    /** Returns an operation to fetch a message content by sequence number. */
    public IMAPFetchContentOperation fetchMessageByNumberOperation(String folder, long number)
    {
        return fetchMessageByNumberOperation(folder, number, false);
    }
    
    /** Returns an operation to fetch an attachment content using the sequence number of a message. */
    public native IMAPFetchContentOperation fetchMessageAttachmentByNumberOperation(String folder, long number, String partID,
                                                                                    int encoding, boolean urgent);
    /** Returns an operation to fetch an attachment content using the sequence number of a message. */
    public IMAPFetchContentOperation fetchMessageAttachmentByNumberOperation(String folder, long number, String partID,
                                                                                    int encoding)
    {
        return fetchMessageAttachmentByNumberOperation(folder, number, partID, encoding, false);
    }
    
    /** Returns an operation to fetch a message content by UID and parse it. */
    public native IMAPFetchParsedContentOperation fetchParsedMessageByUIDOperation(String folder, long uid, boolean urgent);
    /** Returns an operation to fetch a message content by UID and parse it. */
    public IMAPFetchParsedContentOperation fetchParsedMessageByUIDOperation(String folder, long uid)
    {
        return fetchParsedMessageByUIDOperation(folder, uid, false);
    }
    
    /** Returns an operation to fetch a message content by sequence number and parse it. */
    public native IMAPFetchParsedContentOperation fetchParsedMessageByNumberOperation(String folder, long number, boolean urgent);
    /** Returns an operation to fetch a message content by sequence number and parse it. */
    public IMAPFetchParsedContentOperation fetchParsedMessageByNumberOperation(String folder, long number)
    {
        return fetchParsedMessageByNumberOperation(folder, number, false);
    }

    /** Returns an operation to store flags to a set of messages designated by UIDs. */
    public native IMAPOperation storeFlagsByUIDOperation(String folder, IndexSet uids, int kind, int flags, List<String> customFlags);
    /** Returns an operation to store flags to a set of messages designated by UIDs. */
    public IMAPOperation storeFlagsByUIDOperation(String folder, IndexSet uids, int kind, int flags)
    {
        return storeFlagsByUIDOperation(folder, uids, kind, flags, null);
    }
    /** Returns an operation to store flags to a set of messages designated by sequence numbers. */
    public native IMAPOperation storeFlagsByNumberOperation(String folder, IndexSet numbers, int kind, int flags, List<String> customFlags);
    /** Returns an operation to store flags to a set of messages designated by sequence numbers. */
    public IMAPOperation storeFlagsByNumberOperation(String folder, IndexSet numbers, int kind, int flags)
    {
        return storeFlagsByNumberOperation(folder, numbers, kind, flags, null);
    }
    /** Returns an operation to store labels to a set of messages designated by UIDs. */
    public native IMAPOperation storeLabelsByUIDOperation(String folder, IndexSet uids, int kind, List<String> labels);
    /** Returns an operation to store labels to a set of messages designated by sequence numbers. */
    public native IMAPOperation storeLabelsByNumberOperation(String folder, IndexSet numbers, int kind, List<String> labels);
    
    /** Returns a simple search operation. */
    public native IMAPSearchOperation searchOperation(String folder, int kind, String searchString);
    /** Returns a search operation using an expression. */
    public native IMAPSearchOperation searchOperation(String folder, IMAPSearchExpression expression);
    
    /** Returns an IDLE operation (wait for a new message). */
    public native IMAPIdleOperation idleOperation(String folder, long lastKnownUID);
    
    /** Returns an operation to fetch the namespace. */
    public native IMAPFetchNamespaceOperation fetchNamespaceOperation();
    
    /** Returns an operation to send to the server the identity of the client and to get the identity of
        the server. */
    public native IMAPIdentityOperation identityOperation(IMAPIdentity identity);
    
    /** Returns an operation to connect to the server. */
    public native IMAPOperation connectOperation();
    /** Returns an operation to check whether the credentials of the account are correct. */
    public native IMAPOperation checkAccountOperation();
    /** Returns an operation to disconnect from the server. */
    public native IMAPOperation disconnectOperation();
    
    /** Returns an operation to fetch the capabilities. */
    public native IMAPCapabilityOperation capabilityOperation();
    /** Returns an operation to fetch the quota information. */
    public native IMAPQuotaOperation quotaOperation();
    
    /** Returns an IMAP NOOP operation. */
    public native IMAPOperation noopOperation();
    
    /** Returns an operation to render a message as HTML. */
    public native IMAPMessageRenderingOperation htmlRenderingOperation(IMAPMessage message, String folder);
    /** Returns an operation to render the body of a message as HTML. */
    public native IMAPMessageRenderingOperation htmlBodyRenderingOperation(IMAPMessage message, String folder);
    /** Returns an operation to render a message as text. */
    public native IMAPMessageRenderingOperation plainTextRenderingOperation(IMAPMessage message, String folder);
    /** Returns an operation to render the body of a message as text. */
    public native IMAPMessageRenderingOperation plainTextBodyRenderingOperation(IMAPMessage message, String folder, boolean stripWhitespace);
    
    private native void setupNative();
    private native void finalizeNative();
    
    private ConnectionLogger connectionLogger;
    private OperationQueueListener operationQueueListener;
    
    private native void setupNativeOperationQueueListener();
    private native void setupNativeConnectionLogger();
}