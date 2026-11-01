package com.libmailcore;

import java.util.Map;

/** Operation to move IMAP messages. */
public class IMAPMoveMessagesOperation extends IMAPOperation {
    /**
        Returns a map of the UIDs of the messages in the source folder to the UIDs of
        the messages in the destination folder.
    */
    public native Map<Long,Long> uidMapping();
}
