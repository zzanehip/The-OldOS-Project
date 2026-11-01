package com.libmailcore;

/** Operation to fetch all numbers of all the articles of a newsgroup. */
public class NNTPFetchAllArticlesOperation extends NNTPOperation {
    /** numbers of all the articles. */
    public native IndexSet articles();
}
