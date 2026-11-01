package com.libmailcore;

/** Progress listener for IMAP operations working with items such as IMAPFetchMessagesOperation. */
public interface IMAPOperationItemProgressListener {
    /** Called when a progress has been notified. */
    void itemProgress(long current, long maximum);
}
