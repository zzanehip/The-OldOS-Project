package com.libmailcore;

import java.util.List;

/** Operation to list newsgroups. */
public class NNTPListNewsgroupsOperation extends NNTPOperation {
    public native List<NNTPGroupInfo> groups();
}
