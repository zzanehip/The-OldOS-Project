package com.libmailcore;

/** Operation to get info of a folder. The info will be fetched using SELECT. */
public class IMAPFolderInfoOperation extends IMAPOperation {
    /** Info of the folder. */
    public native IMAPFolderInfo info();
}
