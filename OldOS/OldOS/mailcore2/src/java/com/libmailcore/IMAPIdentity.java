package com.libmailcore;

import java.util.List;

/** Identity of an IMAP client or an IMAP server. */
public class IMAPIdentity extends NativeObject {
    public IMAPIdentity()
    {
        setupNative();
    }

    /** Sets the vendor. */
    public native void setVendor(String vendor);
    /** Returns the vendor. */
    public native String vendor();
    
    /** Sets the name of the software. */
    public native void setName(String name);
    /** Returns the name of the software. */
    public native String name();
    
    /** Sets the version of the software. */
    public native void setVersion(String version);
    /** Returns the version of the software. */
    public native String version();

    /** Clear infos. */
    public native void removeAllInfos();
    
    /** Returns all infos names. */
    public native List<String> allInfoKeys();
    /** Returns a value for a name of an info. */
    public native String infoForKey(String key);
    /** Sets a value of an info. */
    public native void setInfoForKey(String key, String value);
    
    private native void setupNative();
}
