package com.libmailcore;

/** Folder status. */
public class IMAPFolderStatus extends NativeObject {
    public IMAPFolderStatus()
    {
        setupNative();
    }
    
    /** Sets the number of unseen messages. */
    public native void setUnseenCount(long unseen);
    /** Returns the number of unseen messages. */
    public native long unseenCount();
    
    /** Sets the number of messages in the folder. */
    public native void setMessageCount(long messages);
    /** Returns the number of messages in the folder. */
    public native long messageCount();
    
    /** Sets the number of recent messages. */
    public native void setRecentCount(long recent);
    /** Returns the number of recent messages. */
    public native long recentCount();
    
    /** Sets the netx uid value. */
    public native void setUidNext(long uidNext);
    /**
        Returns the message UID that will be likely used if a message is
        added to that folder.
    */
    public native long uidNext();
    
    /** Sets the UID validity */
    public native void setUidValidity(long uidValidity);
    /**
        Returns the UID validity of the folder. If that value change for a given folder path,
        it means that the uids of the messages that you may have cached are not valid any more.
    */
    public native long uidValidity();
    
    /** Sets the highest modification sequence value of the messages in the folder. */
    public native void setHighestModSeqValue(long highestModSeqValue);
    /** Returns the highest modification sequence value of the messages in the folder. */
    public native long highestModSeqValue();
    
    private native void setupNative();
}
