package com.libmailcore;

/** Operation to fetch a message. */
public class POPFetchMessageOperation extends POPOperation {
    /** Content of the message in RFC 822 format. */
    public native byte[] data();
}
