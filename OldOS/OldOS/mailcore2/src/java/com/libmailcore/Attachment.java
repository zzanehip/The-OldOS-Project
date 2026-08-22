package com.libmailcore;

/** Attachment when parsing or building a RFC 822 message. */
public class Attachment extends AbstractPart {
    /** Returns the MIME type for the given filename. */
    public static native String mimeTypeForFilename(String filename);
    
    /** Returns an attachment with the content of the given file. */
    public native static Attachment attachmentWithContentsOfFile(String filename);
    /** Returns an attachment with the given data and the given filename. */
    public native static Attachment attachmentWithData(String filename, byte[] data);
    /** Returns an HTML text part with the given HTML. */
    public native static Attachment attachmentWithHTMLString(String htmlString);
    /** Returns RFC 822 message part with the given message data. the message data is encoded with RFC 822. */
    public native static Attachment attachmentWithRFC822Message(byte[] messageData);
    /** Returns a text part with the given text. */
    public native static Attachment attachmentWithText(String text);
    
    /** Returns the data. */
    public native byte[] data();
    /** Sets the data. */
    public native void setData(byte[] data);
    
    /**
        Returns the content of the attachment decoded using the charset encoding.
        @see com.libmailcore.AbstractPart#charset()
    */
    public native String decodedString();
}