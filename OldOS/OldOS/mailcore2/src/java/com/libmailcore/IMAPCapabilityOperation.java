package com.libmailcore;

/** Operation to fetch the capabilities of the IMAP server. */
public class IMAPCapabilityOperation extends IMAPOperation {
    /** The result set will contains values of IMAPCabilityOperation.
        @see com.libmailcore.IMAPCapabilityOperation */
    public native IndexSet capabilities();
}
