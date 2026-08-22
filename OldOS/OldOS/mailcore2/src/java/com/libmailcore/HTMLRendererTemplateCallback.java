package com.libmailcore;

import java.util.Map;

/**
    Callbacks to provide templates for message rendering. Default implementations are
    provided in HTMLRendererTemplteCallbackUtils
*/
public interface HTMLRendererTemplateCallback {
    /** Returns true if an attachment should be rendered using the image template. */
    boolean canPreviewPart(AbstractPart part);
    /** Returns true if an attachment should (such as an image) be shown. */
    boolean shouldShowPart(AbstractPart part);
    /** Returns the values used in the header template for a given template. */
    Map<String, Object> templateValuesForHeader(MessageHeader header);
    /** Returns the values used in the attachment template for a given attachment. */
    Map<String, Object> templateValuesForPart(AbstractPart part);
    /** Returns the template for the main header of the message. */
    String templateForMainHeader(MessageHeader header);
    /** Returns the template to render an image. */
    String templateForImage(AbstractPart part);
    /** Returns the template to render a non-image attachment. */
    String templateForAttachment(AbstractPart part);
    /**
        Returns the template to render a message.
        It should include HEADER and a BODY values.
    */
    String templateForMessage(AbstractMessage message);
    /**
        Returns the template to render an embedded message.
        It should include HEADER and a BODY values.
    */
    String templateForEmbeddedMessage(AbstractMessagePart messagePart);
    /** Returns the template for the header of an embedded message. */
    String templateForEmbeddedMessageHeader(MessageHeader header);
    /** Returns the separator between the text of the message and the attachments. */
    String templateForAttachmentSeparator();
    /**
        Clean a HTML string.
        The default implementation fixes broken tags, add missing &lt;html&gt;, &lt;body&gt; tags.
    */
    String cleanHTMLForPart(String html);
    /**
        Filter the HTML when rendering a given part. For example, it could filter out
        dangerous HTML tags or CSS style.
    */
    String filterHTMLForPart(String html);
    /**
        Filter the HTML when rendering a the whole message.
    */
    String filterHTMLForMessage(String html);
}
