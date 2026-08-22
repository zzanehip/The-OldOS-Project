package com.libmailcore;

import java.util.List;

/** Operation to fetch the list of messages in a folder. */
public class IMAPFetchMessagesOperation extends IMAPOperation {
    protected void finalize() throws Throwable
    {
        finalizeNative();
        super.finalize();
    }
    
    /** Sets progress listener. */
    public void setProgressListener(IMAPOperationItemProgressListener aListener) {
        listener = aListener;
        setupNativeOperationProgressListener();
    }
    
    /** Returns the progress listener. */
    public IMAPOperationItemProgressListener progressListener() {
        return listener;
    }
    
    /** Sets the list of extra headers to fetch. They must be set before starting the operation. */
    public native void setExtraHeaders(List<String> extraHeaders);
    /** Returns the list of extra headers to fetch. */
    public native List<String> extraHeaders();
    
    /** Returns the list of messages. */
    public native List<IMAPMessage> messages();
    /** Returns the list of UIDs of the deleted messages on an IMAP server that supports QRESYNC. */
    public native IndexSet vanishedMessages();
    
    private native void finalizeNative();
    
    private IMAPOperationItemProgressListener listener;
    private native void setupNativeOperationProgressListener();
    private long nativeOperationProgressListener;
}
