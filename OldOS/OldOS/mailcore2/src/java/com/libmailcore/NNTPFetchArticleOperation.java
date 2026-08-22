package com.libmailcore;

/** Operation to fetch the content of a given article. */
public class NNTPFetchArticleOperation extends NNTPOperation {
    /** Content of the article in RFC 822 format. */
    public native byte[] data();
}
