package com.libmailcore;

import java.util.List;

/** Abstract message. */
public class AbstractMessage extends NativeObject {
    /** Returns the header of the message. */
    public native MessageHeader header();
    /** Sets the header of the message. */
    public native void setHeader(MessageHeader header);
    
    /**
        Returns the MIME part with the given Content-ID.
        @see com.libmailcore.AbstractPart#contentID()
    */
    public native AbstractPart partForContentID(String contentID);
    /**
        Returns the MIME part with the given uniqueID.
        @see com.libmailcore.AbstractPart#uniqueID()
    */
    public native AbstractPart partForUniqueID(String uniqueID);
    /** Returns the list of attachments, not part of the content of the message. */
    public native List<AbstractPart> attachments();
    /** Returns the list of attachments that are shown inline in the content of the message. */
    public native List<AbstractPart> htmlInlineAttachments();
    /** Returns the list of the text parts required to render the message properly. */
    public native List<AbstractPart> requiredPartsForRendering();
}
