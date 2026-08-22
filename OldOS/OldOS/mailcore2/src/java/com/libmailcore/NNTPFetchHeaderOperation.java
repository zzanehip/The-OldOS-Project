package com.libmailcore;

/** Operation to fetch header of a given article. */
public class NNTPFetchHeaderOperation extends NNTPOperation {
    /** Parsed header of the article. */
    public native MessageHeader header();
}
