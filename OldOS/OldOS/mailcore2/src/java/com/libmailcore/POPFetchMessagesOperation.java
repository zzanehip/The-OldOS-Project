package com.libmailcore;

import java.util.List;

/** Operation to fetch the list of messages. */
public class POPFetchMessagesOperation extends POPOperation {
    public native List<POPMessageInfo> messages();
}
