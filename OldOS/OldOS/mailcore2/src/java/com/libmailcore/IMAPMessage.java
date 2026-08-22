package com.libmailcore;

import java.util.List;

/** IMAP messages. */
public class IMAPMessage extends AbstractMessage {
     /** Constuctor. */
    public IMAPMessage() {
        setupNative();
    }
    /** IMAP sequence number. */
    public native long sequenceNumber();
    /** Sets the IMAP sequence number. */
    public native void setSequenceNumber(long sequenceNumber);
    
    /** UID of the message. */
    public native long uid();
    /** Sets the UID of the message. */
    public native void setUid(long uid);
    
    /** Size of the message. */
    public native long size();
    /** Sets the size of the message. */
    public native void setSize(long size);
    
    /**
        Sets flags of the message.
        @see com.libmailcore.MessageFlag
    */
    public native void setFlags(int flags);
    /**
        Flags of the message.
        @see com.libmailcore.MessageFlag
    */
    public native int flags();
    
    /**
        Set original message flags.
        @see com.libmailcore.MessageFlag
    */
    public native void setOriginalFlags(int flags);
    /**
        Original message flags.
        @see com.libmailcore.MessageFlag
    */
    public native int originalFlags();
    
    /**
        Sets custom flags.
    */
    public native void setCustomFlags(List<String> customFlags);
    /**
        Returns custom flags.
    */
    public native List<String> customFlags();
    
    /** Returns the modification sequence value. */
    public native long modSeqValue();
    /** Sets the modification sequence value. */
    public native void setModSeqValue(long uid);
    
    /** Sets the main part of the message. */
    public native void setMainPart(AbstractPart mainPart);
    /** Returns the main part of the message. */
    public native AbstractPart mainPart();
    
    /** Sets the labels of the message in case that's a Gmail server. */
    public native void setGmailLabels(List<String> labels);
    /** Returns the labels of the message in case that's a Gmail server. */
    public native List<String> gmailLabels();
    
    /** Sets the message identifier on Gmail server. */
    public native void setGmailMessageID(long msgID);
    /** Returns the message identifier on Gmail server. */
    public native long gmailMessageID();
            
    /** Sets the message thread identifier on Gmail server. */
    public native void setGmailThreadID(long threadID);
    /** Returns the message thread identifier on Gmail server. */
    public native long gmailThreadID();
    
    /**
        Returns the MIME part with the given partID.
        @see com.libmailcore.IMAPPart#partID()
        @see com.libmailcore.IMAPMessagePart#partID()
        @see com.libmailcore.IMAPMultipart#partID()
    */
    public native AbstractPart partForPartID(String partID);
    
    /**
        Returns the HTML rendering of the message.
        @param folder is the folder containing the message.
        @param dataCallback callbacks for the IMAP data.
        @param htmlCallback callbacks for the HTML template.
    */
    public native String htmlRendering(String folder,
                                   HTMLRendererIMAPCallback dataCallback,
                                   HTMLRendererTemplateCallback htmlCallback);

    /**
        Returns the HTML rendering of the message.
        @param folder is the folder containing the message.
        @param dataCallback callbacks for the IMAP data.
    */
    public String htmlRendering(String folder,
                                HTMLRendererIMAPCallback dataCallback)
    {
        return htmlRendering(folder, dataCallback, null);
    }

    private static final long serialVersionUID = 1L;
    
    private native void setupNative();
}
