package com.libmailcore;

/** Operation to fetch the header of a message. */
public class POPFetchHeaderOperation extends POPOperation {
    /** Parsed header of the message. */
    public native MessageHeader header();
}
