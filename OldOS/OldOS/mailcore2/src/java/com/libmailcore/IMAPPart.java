package com.libmailcore;

/** IMAP part. */
public class IMAPPart extends AbstractPart {
    /** Sets part ID. */
    public native void setPartID(String partID);
    /** Returns part ID. */
    public native String partID();
    
    /** Sets encoded size of the part. */
    public native void setSize(long size);
    /** Returns encoded size of the part. */
    public native long size();
    
    /** Returns decoded size. */
    public native long decodedSize();
    
    /**
        Sets encoding used (base64, quoted-printable, etc).
        @see com.libmailcore.Encoding
    */
    public native void setEncoding(int encoding);
    /**
        Returns encoding used (base64, quoted-printable, etc.)
        @see com.libmailcore.Encoding
    */
    public native int encoding();

    private static final long serialVersionUID = 1L;
}
