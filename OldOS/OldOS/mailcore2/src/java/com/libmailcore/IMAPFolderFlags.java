package com.libmailcore;

/** Flags of a folder.
    @see com.libmailcore.IMAPFolder#flags() */
public class IMAPFolderFlags {
    public final static int IMAPFolderFlagNone = 0;
    public final static int IMAPFolderFlagMarked      = 1 << 0;
    public final static int IMAPFolderFlagUnmarked    = 1 << 1;
    /** The folder can't be selected and can't hold messages. */
    public final static int IMAPFolderFlagNoSelect    = 1 << 2;
    /** The folder has no children. */
    public final static int IMAPFolderFlagNoInferiors = 1 << 3;
    /** The folder is INBOX. */
    public final static int IMAPFolderFlagInbox       = 1 << 4;
    /** The folder is the sent folder. */
    public final static int IMAPFolderFlagSentMail    = 1 << 5;
    /** The folder is the starred folder. */
    public final static int IMAPFolderFlagStarred     = 1 << 6;
    /** The folder is the folder containg all mails. */
    public final static int IMAPFolderFlagAllMail     = 1 << 7;
    /** The folder is the trash folder. */
    public final static int IMAPFolderFlagTrash       = 1 << 8;
    /** The folder is the drafts folder. */
    public final static int IMAPFolderFlagDrafts      = 1 << 9;
    /** The folder is the spam folder. */
    public final static int IMAPFolderFlagSpam        = 1 << 10;
    /** The folder is the important folder. */
    public final static int IMAPFolderFlagImportant   = 1 << 11;
    /** The folder is the archive folder. */
    public final static int IMAPFolderFlagArchive     = 1 << 12;
    /**
        Same as IMAPFolderFlagAllMail.
        @see com.libmailcore.IMAPFolderFlags#IMAPFolderFlagAllMail
    */
    public final static int IMAPFolderFlagAll = IMAPFolderFlagAllMail;
    /**
        Same as IMAPFolderFlagSpam.
        @see com.libmailcore.IMAPFolderFlags#IMAPFolderFlagSpam
    */
    public final static int IMAPFolderFlagJunk = IMAPFolderFlagSpam;
    /**
        Same as IMAPFolderFlagStarred.
        @see com.libmailcore.IMAPFolderFlags#IMAPFolderFlagStarred
    */
    public final static int IMAPFolderFlagFlagged = IMAPFolderFlagStarred;
    /** Mask for the types of folder. */
    public final static int IMAPFolderFlagFolderTypeMask = IMAPFolderFlagInbox | IMAPFolderFlagSentMail | IMAPFolderFlagStarred | IMAPFolderFlagAllMail |
        IMAPFolderFlagTrash| IMAPFolderFlagDrafts | IMAPFolderFlagSpam | IMAPFolderFlagImportant | IMAPFolderFlagArchive;
}
