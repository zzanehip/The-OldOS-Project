package com.libmailcore;

/** IMAP folder. */
public class IMAPFolder extends NativeObject {
    public IMAPFolder()
    {
        setupNative();
    }
    
    /** Sets the path of the folder. */
    public native void setPath(String path);
    /** Returns the path of the folder. */
    public native String path();
    
    /** Sets the delimiter of the folder. */
    public native void setDelimiter(char delimiter);
    /** Returns the delimiter of the folder. */
    public native char delimiter();
    
    /**
        Sets the flags of the folder.
        @see com.libmailcore.IMAPFolderFlags
    */
    public native void setFlags(int flags);
    /**
        Returns the flags of the folder.
        @see com.libmailcore.IMAPFolderFlags
    */
    public native int flags();
    
    private native void setupNative();
}
