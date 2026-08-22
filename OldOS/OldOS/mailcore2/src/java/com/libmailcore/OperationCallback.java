package com.libmailcore;

/** Callbacks of an operation. */
public interface OperationCallback {
    /** Called when the operation succeeded. */
    void succeeded();
    /** Called when the operation failed. */
    void failed(MailException exception);
}
