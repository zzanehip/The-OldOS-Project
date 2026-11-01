package com.libmailcore;

/** IMAP embedded message part. */
public class IMAPMessagePart extends AbstractMessagePart {
    /** Sets part ID. */
    public native void setPartID(String partID);
    /** Returns part ID. */
    public native String partID();

    private static final long serialVersionUID = 1L;
}
