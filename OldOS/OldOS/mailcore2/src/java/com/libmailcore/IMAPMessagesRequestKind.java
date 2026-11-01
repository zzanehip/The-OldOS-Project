package com.libmailcore;

/**
    Items to request when fetching the list of messages.
    @see com.libmailcore.IMAPSession#fetchMessagesByUIDOperation(String folder, int requestKind, IndexSet indexes)
    @see com.libmailcore.IMAPSession#fetchMessagesByNumberOperation(String folder, int requestKind, IndexSet indexes)
    @see com.libmailcore.IMAPSession#syncMessagesByUIDOperation(String folder, int requestKind, IndexSet indexes, long modSeq)
*/
public class IMAPMessagesRequestKind {
    /** Requests UID of the messages. */
    public final static int IMAPMessagesRequestKindUid = 0;
    /** Requests the flags of the messages. */
    public final static int IMAPMessagesRequestKindFlags = 1 << 0;
    /** Requests the headers of the messages (ENVELOPE). */
    public final static int IMAPMessagesRequestKindHeaders = 1 << 1;
    /** Requests the MIME Structure of the messages (BODYSTRUCTURE). */
    public final static int IMAPMessagesRequestKindStructure = 1 << 2;
    /** Requests the received date of the messages (INTERNALDATE). */
    public final static int IMAPMessagesRequestKindInternalDate = 1 << 3;
    /** Requests the headers of the messages. They will be parsed by MailCore. */
    public final static int IMAPMessagesRequestKindFullHeaders = 1 << 4;
    /** Requests the header "Subject". */
    public final static int IMAPMessagesRequestKindHeaderSubject = 1 << 5;
    /** Requests the Labels on Gmail server. */
    public final static int IMAPMessagesRequestKindGmailLabels = 1 << 6;
    /** Requests the message identifier on Gmail server. */
    public final static int IMAPMessagesRequestKindGmailMessageID = 1 << 7;
    /** Requests the message thread identifier on Gmail server. */
    public final static int IMAPMessagesRequestKindGmailThreadID = 1 << 8;
    /**
        Requests extra headers.
        @see com.libmailcore.IMAPFetchMessagesOperation#setExtraHeaders
    */
    public final static int IMAPMessagesRequestKindExtraHeaders = 1 << 9;
    /** Requests the size of the messages. */
    public final static int IMAPMessagesRequestKindSize = 1 << 10;
    /** Unlike Full headers this will fetch all the non-parsed headers */
    public final static int IMAPMessagesRequestKindSize = 1 << 11;
}
