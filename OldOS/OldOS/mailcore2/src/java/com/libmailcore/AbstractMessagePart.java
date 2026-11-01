package com.libmailcore;

/** Abstract embedded message part. */
public class AbstractMessagePart extends AbstractPart {
    /** Header of the message. */
    public native MessageHeader header();
    /** Sets the header of the message. */
    public native void setHeader(MessageHeader header);
    
    /** Returns the main MIME part of the message. */
    public native AbstractPart mainPart();
    /** Sets the main MIME part. */
    public native void setMainPart(AbstractPart part);
}
