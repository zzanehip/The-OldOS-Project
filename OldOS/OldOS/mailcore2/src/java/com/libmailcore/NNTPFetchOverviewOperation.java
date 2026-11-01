package com.libmailcore;

import java.util.List;

/** Operation to fetch list of summary headers of a set of articles of a newsgroup. */ 
public class NNTPFetchOverviewOperation extends NNTPOperation {
    public native List<MessageHeader> articles();
}
