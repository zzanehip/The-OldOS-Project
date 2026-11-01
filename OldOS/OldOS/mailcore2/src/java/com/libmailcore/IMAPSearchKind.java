package com.libmailcore;

/** Search types.
    @see com.libmailcore.IMAPSession#searchOperation(String folder, int kind, String searchString) */
public class IMAPSearchKind {
    public final static int IMAPSearchKindAll = 0;
    public final static int IMAPSearchKindNone = 1;
    public final static int IMAPSearchKindFrom = 2;
    public final static int IMAPSearchKindTo = 3;
    public final static int IMAPSearchKindCc = 4;
    public final static int IMAPSearchKindBcc = 5;
    public final static int IMAPSearchKindRecipient = 6;
    public final static int IMAPSearchKindSubject = 7;
    public final static int IMAPSearchKindContent = 8;
    public final static int IMAPSearchKindBody = 9;
    public final static int IMAPSearchKindUids = 10;
    public final static int IMAPSearchKindHeader = 11;
    public final static int IMAPSearchKindRead = 12;
    public final static int IMAPSearchKindUnread = 13;
    public final static int IMAPSearchKindFlagged = 14;
    public final static int IMAPSearchKindUnflagged = 15;
    public final static int IMAPSearchKindAnswered = 16;
    public final static int IMAPSearchKindUnanswered = 17;
    public final static int IMAPSearchKindDraft = 18;
    public final static int IMAPSearchKindUndraft = 19;
    public final static int IMAPSearchKindDeleted = 20;
    public final static int IMAPSearchKindSpam = 21;
    public final static int IMAPSearchKindBeforeDate = 22;
    public final static int IMAPSearchKindOnDate = 23;
    public final static int IMAPSearchKindSinceDate = 24;
    public final static int IMAPSearchKindBeforeReceivedDate = 25;
    public final static int IMAPSearchKindOnReceivedDate = 26;
    public final static int IMAPSearchKindSinceReceivedDate = 27;
    public final static int IMAPSearchKindSizeLarger = 28;
    public final static int IMAPSearchKindSizeSmaller = 29;
    public final static int IMAPSearchKindGmailThreadID = 30;
    public final static int IMAPSearchKindGmailMessageID = 31;
    public final static int IMAPSearchKindGmailRaw = 32;
    public final static int IMAPSearchKindOr = 33;
    public final static int IMAPSearchKindAnd = 34;
    public final static int IMAPSearchKindNot = 35;
}
