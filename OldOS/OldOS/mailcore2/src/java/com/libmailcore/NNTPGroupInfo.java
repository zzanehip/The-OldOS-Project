package com.libmailcore;

/** Newsgroup infos. */
public class NNTPGroupInfo extends NativeObject {
    /** Constructor. */
    public NNTPGroupInfo()
    {
        setupNative();
    }
    
    /** Sets the name of the newsgroup. */
    public native void setName(String name);
    /** Returns the name of the newsgroup. */
    public native String name();
    
    /** Sets the number of messages in the newsgroup. */
    public native void setMessageCount(long count);
    /** Returns the number of messages in the newsgroup. */
    public native long messageCount();
    
    private native void setupNative();
}
