package com.libmailcore;

/** Flags of a message.
    @see com.libmailcore.IMAPMessage#flags() */
public class MessageFlag {
    final public static int MessageFlagNone          = 0;
    final public static int MessageFlagSeen          = 1 << 0;
    final public static int MessageFlagAnswered      = 1 << 1;
    final public static int MessageFlagFlagged       = 1 << 2;
    final public static int MessageFlagDeleted       = 1 << 3;
    final public static int MessageFlagDraft         = 1 << 4;
    final public static int MessageFlagMDNSent       = 1 << 5;
    final public static int MessageFlagForwarded     = 1 << 6;
    final public static int MessageFlagSubmitPending = 1 << 7;
    final public static int MessageFlagSubmitted     = 1 << 8;
    final public static int MessageFlagMaskAll = MessageFlagSeen | MessageFlagAnswered | MessageFlagFlagged |
        MessageFlagDeleted | MessageFlagDraft | MessageFlagMDNSent | MessageFlagForwarded |
            MessageFlagSubmitPending | MessageFlagSubmitted;
}
