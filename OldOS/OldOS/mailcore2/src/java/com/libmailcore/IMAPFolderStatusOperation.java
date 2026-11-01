package com.libmailcore;

/** Operation to fetch a folder status. */
public class IMAPFolderStatusOperation extends IMAPOperation {
    public native IMAPFolderStatus status();
}
