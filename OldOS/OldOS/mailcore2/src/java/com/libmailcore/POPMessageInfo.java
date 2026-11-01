package com.libmailcore;

/** Info about a message. */
public class POPMessageInfo extends NativeObject {
    /** Constructor. */
    public POPMessageInfo()
    {
        setupNative();
    }
    
    /** Sets the index of the message. */
    public native void setIndex(int index);
    /** Returns the index of the message, valid during the POP session. */
    public native int index();
    
    /** Sets the size of the message. */
    public native void setSize(long size);
    /** Returns the size of the message. */
    public native long size();
    
    /** Sets the unique identifier of the message. */
    public native void setUid(String uid);
    /** Returns the unique identifier of the message. */
    public native String uid();
    
    private native void setupNative();
}
