package com.libmailcore;

/** Operation to fetch a message and parse it. */
public class IMAPFetchParsedContentOperation extends IMAPOperation {
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
    
    /** Returns the parsed message. */
    public native MessageParser parser();
    
    private native void finalizeNative();
    
    private IMAPOperationProgressListener listener;
    private native void setupNativeOperationProgressListener();
    private long nativeOperationProgressListener;
}
