package com.libmailcore;

/** RFC 822 message parser. */
public class MessageParser extends AbstractMessage {
    /** Returns a MessageParser that parses the given RFC 822 message data. */
    public static native MessageParser messageParserWithData(byte[] messageData);
    /** Returns a MessageParser that parses the given file containing RFC 822 message data. */
    public static native MessageParser messageParserWithContentsOfFile(String filename);
    
    /** Returns the main part of the message. */
    public native AbstractPart mainPart();
    /** Returns the data of the message. */
    public native byte[] data();
    
    /** Renders the message as HTML. */
    public native String htmlRendering(HTMLRendererTemplateCallback callback);
    public String htmlRendering()
    {
        return htmlRendering(null);
    }
    /** Renders the body of the message as HTML. */
    public native String htmlBodyRendering();
    /** Renders the message as plain text. */
    public native String plainTextRendering();
    /** Renders the body of the message as plain text. */
    public native String plainTextBodyRendering(boolean stripWhitespace);
    
    private native void setupNative(byte[] messageData);
}
