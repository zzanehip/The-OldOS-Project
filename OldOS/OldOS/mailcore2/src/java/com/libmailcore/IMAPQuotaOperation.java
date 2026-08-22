package com.libmailcore;

/** IMAP QUOTA Operation. */
public class IMAPQuotaOperation extends IMAPOperation {
    /** Returns quota usage. */
    public native int usage();
    /** Returns quota limit. */
    public native int limit();
}
