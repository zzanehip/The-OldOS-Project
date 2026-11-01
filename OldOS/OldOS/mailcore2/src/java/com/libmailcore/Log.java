package com.libmailcore;

/** Logging. */
public class Log {
    /** Set whether debug logs are enabled. */
    static public native void setEnabled(boolean enabled);
    /** Returns whether debug logs are enabled. */
    static public native boolean isEnabled();
}
