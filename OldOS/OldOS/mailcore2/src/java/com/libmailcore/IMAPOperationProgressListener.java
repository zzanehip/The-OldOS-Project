package com.libmailcore;

/** Progress listener for IMAP operations working with stream of data. */
public interface IMAPOperationProgressListener {
    /** Called when a progress has been notified. */
    void bodyProgress(long current, long maximum);
}
