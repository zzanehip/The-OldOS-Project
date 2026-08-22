package com.libmailcore;

/** Store request kind.
     @see com.libmailcore.IMAPSession#storeFlagsByUIDOperation(String folder, IndexSet uids, int kind, int flags) */
public class IMAPStoreFlagsRequestKind {
    public final static int IMAPStoreFlagsRequestKindAdd = 0;
    public final static int IMAPStoreFlagsRequestKindRemove = 1;
    public final static int IMAPStoreFlagsRequestKindSet = 2;
}