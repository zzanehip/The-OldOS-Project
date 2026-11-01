package com.libmailcore;

import java.util.List;

/** RFC 822 Message builder. */
public class MessageBuilder extends AbstractMessage {
    /** Constructor. */
    public MessageBuilder()
    {
        setupNative();
    }

    /** Sets HTML body. */
    public native void setHTMLBody(String htmlBody);
    /** Returns HTML body. */
    public native String htmlBody();
    
    /** Sets plain/text body. */
    public native void setTextBody(String textBody);
    /** Returns plain/text body. */
    public native String textBody();
    
    /** Sets the list of attachments. */
    public native void setAttachments(List<Attachment> attachments);
    /** Returns the list of attachments. */
    public native List<AbstractPart> attachments();
    /** Adds an attachment. */
    public native void addAttachment(Attachment attachment);
    
    /** Sets the list of related attachments (for example, images included in the HTML body). */
    public native void setRelatedAttachments(List<Attachment> attachments);
    /** Returns the list of related attachments. */
    public native List<Attachment> relatedAttachments();
    /** Adds a related attachment. */
    public native void addRelatedAttachment(Attachment attachment);
    
    /** Set the prefix to use when generating the boundary separator. */
    public native void setBoundaryPrefix(String boundaryPrefix);
    /** Returns the prefix to use when generating the boundary separator. */
    public native String boundaryPrefix();
    
    /** Returns RFC 822 data. */
    public native byte[] data();
    /** Returns RFC 822 data that can be used safely for encryption/signature. */
    public native byte[] dataForEncryption();
    
    /** Renders the message to HTML. */
    public native String htmlRendering(HTMLRendererTemplateCallback callback);
    /** Renders the body to HTML. */
    public native String htmlBodyRendering();
    
    /** Renders the message to plain text. */
    public native String plainTextRendering();
    /** Render the body to plain text. If stripWhitespace is true, all end of line and extra blank
        space will be removed. */
    public native String plainTextBodyRendering(boolean stripWhitespace);
    
    /** Returns the RFC 822 message signed using PGP given the signature. The signature
        needs to be computed using an external component. It will make to sure generate
        the message format to conform to OpenPGP standard. */
    public native byte[] openPGPSignedMessageDataWithSignatureData(byte[] signature);
    /** Returns the RFC 822 message encrypted using PGP given the encrypted data. The encrypted data
        needs to be computed using an external component. It will make to sure generate
        the message format to conform to OpenPGP standard. */
    public native byte[] openPGPEncryptedMessageDataWithEncryptedData(byte[] encryptedData);
    
    private native void setupNative();
}
