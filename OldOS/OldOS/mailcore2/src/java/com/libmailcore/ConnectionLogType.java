package com.libmailcore;

/** Logs type for the connection logger.
    @see com.libmailcore.ConnectionLogger#log(long connectionID, int type, byte[] data) */
public class ConnectionLogType {
    /** Received data. */
    final public static int ConnectionLogTypeReceived = 0;
    /** Sent data. */
    final public static int ConnectionLogTypeSent = 1;
    /** Sent private data (such as a password). */
    final public static int ConnectionLogTypeSentPrivate = 2;
    /** Error when parsing. */
    final public static int ConnectionLogTypeErrorParse = 3;
    /** Error while receiving. */
    final public static int ConnectionLogTypeErrorReceived = 4;
    /** Error while sending. */
    final public static int ConnectionLogTypeErrorSent = 5;
}
