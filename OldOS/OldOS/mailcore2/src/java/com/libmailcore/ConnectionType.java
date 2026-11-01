package com.libmailcore;

/** Connection type. */
public class ConnectionType {
    /** Clear-text connection. */
    final public static int ConnectionTypeClear = 1 << 0;
    /** Connection starts in clear-text and is switched to SSL when it starts sending sensitive data. */
    final public static int ConnectionTypeStartTLS = 1 << 1;
    /** SSL connection. */
    final public static int ConnectionTypeTLS = 1 << 2;
}
