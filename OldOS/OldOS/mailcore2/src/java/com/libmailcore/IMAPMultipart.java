package com.libmailcore;

/** IMAP multipart */
public class IMAPMultipart extends AbstractMultipart {
    /** Sets part ID. */
    public native void setPartID(String partID);
    /** Returns part ID. */
    public native String partID();
    private native void setupNative();

    private static final long serialVersionUID = 1L;
}
