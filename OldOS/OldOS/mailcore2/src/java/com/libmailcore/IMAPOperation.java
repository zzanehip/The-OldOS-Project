package com.libmailcore;

/** IMAP Operation. */
public class IMAPOperation extends Operation {
    /**
        Returns error once the operation finished running. It will return null if the operation
        successfully ran.
    */
    public MailException exception() {
        if (errorCode() == ErrorCode.ErrorNone) {
            return null;
        }
        return new MailException(errorCode());
    }

    private native int errorCode();
    
    /**
        Calls the method succeeded() of the callback if the operation succeeded or failed()
        if the operation failed.
        @see com.libmailcore.OperationCallback
    */
    protected void callCallback()
    {
        if (callback != null) {
            if (errorCode() == ErrorCode.ErrorNone) {
                callback.succeeded();
            }
            else {
                callback.failed(exception());
            }
        }
    }
}
