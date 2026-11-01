package com.libmailcore;

import java.util.List;

public class IMAPNamespaceItem extends NativeObject {
    
    /** Sets prefix. */
    public native void setPrefix(String prefix);
    /** Returns prefix. */
    public native String prefix();

    /** Sets delimiter. */
    public native void setDelimiter(char delimiter);
    /** Returns delimiter. */
    public native char delimiter();

    /** Returns the folder path for the given list of path components. */
    public native String pathForComponents(List<String> components);
    /** Returns the components given a folder path. */
    public native List<String> componentsForPath(String path);

    /** Returns true if the namespace contains the given folder path. */
    public native boolean containsFolder(String folder);
}
