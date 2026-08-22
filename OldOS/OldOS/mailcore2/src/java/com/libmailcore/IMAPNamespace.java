package com.libmailcore;

import java.util.List;

/** IMAP Namespace */
public class IMAPNamespace extends NativeObject {
    /** Returns the prefix of the main namespace item. */
    public native String mainPrefix();
    /** Returns the delimiter of the main namespace item. */
    public native char mainDelimiter();
    
    /** Returns the list of prefixes. */
    public native List<String> prefixes();
    
    /**
     Returns the folder path for the given list of path components in the context
     of the main item of the namespace.
    */
    public native String pathForComponents(List<String> components);
    /**
     Returns the folder path for the given list of path components and a prefix.
     It will use the best item matching the prefix to compute the path.
    */
    public native String pathForComponentsAndPrefix(List<String> components, String prefix);
    
    /** Returns the components given a folder path. */
    public native List<String> componentsFromPath(String path);
    
    /** Returns true if the namespace contains the given folder path. */
    public native boolean containsFolderPath(String path);
    
    /** Returns a namespace (with a single namespace item) with a prefix and a delimiter. */
    public static native IMAPNamespace namespaceWithPrefix(String prefix, char delimiter);
}
