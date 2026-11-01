package com.libmailcore;

/** Operation for IMAP IDLE (wait for incoming messages). */
public class IMAPIdleOperation extends IMAPOperation {
    public native void interruptIdle();
}
