package com.libmailcore;

/** Folders info such as message count, uid validity, etc. */
public class IMAPFolderInfo extends NativeObject {
    public IMAPFolderInfo()
    {
        setupNative();
    }
    
    /**
        Returns the message UID that will be likely used if a message is
        added to that folder.
    */
    public native long uidNext();
    /** Sets the next UID value. */
    public native void setUidNext(long uidNext);
    
    /**
        Returns the UID validity of the folder. If that value change for a given folder path,
        it means that the uids of the messages that you may have cached are not valid any more.
    */
    public native long uidValidity();
    /** Sets the UID validity */
    public native void setUidValidity(long uidValidity);
    
    /** Returns the modification sequence value for CONDSTORE and QRESYNC. */
    public native long modSequenceValue();
    /** Sets the modification sequence value. */
    public native void setModSequenceValue(long modSequenceValue);
    
    /** Returns the number of messages. */
    public native int messageCount();
    /** Sets the number of messages. */
    public native void setMessageCount(int messageCount);
    
    /** Returns the UID of the first unseen message. */
    public native long firstUnseenUid();
    /** Sets the UID of the first unseen message. */
    public native void setFirstUnseenUid(long firstUnseenUid);
    
    /** Returns whether adding custom flags to messages is allowed. */
    public native boolean allowsNewPermanentFlags();
    /** Sets whether adding custom flags to messages is allowed. */
    public native void setAllowsNewPermanentFlags(boolean allowsNewPermanentFlags);

    private native void setupNative();
}
