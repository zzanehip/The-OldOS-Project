package com.libmailcore;

/** Operation to fetch a message or an attachment from the IMAP server. */
public class IMAPFetchContentOperation extends IMAPOperation {
    protected void finalize() throws Throwable
    {
        finalizeNative();
        super.finalize();
    }
    
    /** Sets the progress listener. */
    public void setProgressListener(IMAPOperationProgressListener aListener)
    {
        listener = aListener;
        setupNativeOperationProgressListener();
    }
    
    /** Returns the progress listener. */
    public IMAPOperationProgressListener progressListener()
    {
        return listener;
    }
    
    /** Content of the message or the attachment. */
    public native byte[] data();
    
    private native void finalizeNative();
    
    private IMAPOperationProgressListener listener;
    private native void setupNativeOperationProgressListener();
    private long nativeOperationProgressListener;
}
