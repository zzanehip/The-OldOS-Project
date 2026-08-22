package com.libmailcore;

import java.util.AbstractList;

/** Abstract MIME part. */
public class AbstractPart extends NativeObject {
    /**
        Returns the type of the part.
        @see com.libmailcore.PartType
    */
    public native int partType();
    /**
        Sets the type of the part.
        @see com.libmailcore.PartType
    */
    public native void setPartType(int partType);
    
    /** Returns filename of the attachment. */
    public native String filename();
    /** Sets the filename of the attachment. */
    public native void setFilename(String filename);
    
    /** Returns the mime type of the attachment. */
    public native String mimeType();
    /** Sets the charset encoding of the attachment. */
    public native void setMimeType(String mimeType);
    
    /** Returns the charset encoding of the attachment. */
    public native String charset();
    /** Sets the charset encoding of the attachment. */
    public native void setCharset(String charset);
    
    /**
        Returns the uniqueID of the attachment.
        The uniqueID is an identifier unique in the scope of the message.
    */
    public native String uniqueID();
    /** Sets the unique identifier of the attachment. */
    public native void setUniqueID(String uniqueID);
    
    /** Returns the Content-ID of the attachment. */
    public native String contentID();
    /** Sets the Content-ID of the attachment. */
    public native void setContentID(String contentID);
    
    /** Returns the Content-Location of the attachment. */
    public native String contentLocation();
    /** Sets the Content-Location of the attachment. */
    public native void setContentLocation(String contentLocation);
    
    /** Returns the Content-Description of the attachment. */
    public native String contentDescription();
    /** Sets the Content-Description of the attachment. */
    public native void setContentDescription(String contentDescription);
    
    /** Returns the hint about whether the attachment should be shown inline. */
    public native boolean isInlineAttachment();
    /** Sets the hint about whether the attachment should be shown inline. */
    public native void setInlineAttachment(boolean inlineAttachment);
    
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
    
    /** Sets a Content-Type parameter. */
    public native void setContentTypeParameter(String name, String value);
    /** Returns a Content-Type parameter for a given name. */
    public native String contentTypeParameterValueForName(String name);
    /** Returns the list of all parameters names of Content-Type. */
    public native AbstractList<String> allContentTypeParametersNames();
}
