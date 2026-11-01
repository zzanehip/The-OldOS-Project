package com.libmailcore;

import java.util.Map;

/** Operation to fetch the namespace. */
public class IMAPFetchNamespaceOperation extends IMAPOperation {
    public native Map<String,IMAPNamespace> namespaces();
}
