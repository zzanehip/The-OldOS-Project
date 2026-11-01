package com.libmailcore;

import java.util.Date;

/** Operation to append an message using IMAP. */
public class IMAPAppendMessageOperation extends IMAPOperation {
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

    /** Sets the received date of the message to append. */
    public native void setDate(Date date);
    /** Returns the received date of the message to append. */
    public native Date date();
    
    /**
        Returns the UID of the created message. It will have a correct value once
        the operation finished.
    */
    public native long createdUID();

    private native void finalizeNative();

    private IMAPOperationProgressListener listener;
    private native void setupNativeOperationProgressListener();
    private long nativeOperationProgressListener;
}
