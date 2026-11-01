package com.libmailcore;

import java.util.List;

/** Operation to fetch the list of folders (or subscribed folders). */
public class IMAPFetchFoldersOperation extends IMAPOperation {
    /** List of folders. */
    public native List<IMAPFolder> folders();
}
