package com.libmailcore;

import java.util.Date;

/** Operation to fetch the server time. */
public class NNTPFetchServerTimeOperation extends NNTPOperation {
    public native Date time();
}
