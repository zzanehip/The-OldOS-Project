package com.libmailcore;

/** IMAP Search operation. */
public class IMAPSearchOperation extends IMAPOperation {
    /** Returns UIDs matching the search query. */
    public native IndexSet uids();
}