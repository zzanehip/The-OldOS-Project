package com.libmailcore;

/** Authentication type. */
public class AuthType {
    public static int AuthTypeSASLNone          = 0;
    public static int AuthTypeSASLCRAMMD5       = 1 << 0;
    public static int AuthTypeSASLPlain         = 1 << 1;
    public static int AuthTypeSASLGSSAPI        = 1 << 2;
    public static int AuthTypeSASLDIGESTMD5     = 1 << 3;
    public static int AuthTypeSASLLogin         = 1 << 4;
    public static int AuthTypeSASLSRP           = 1 << 5;
    public static int AuthTypeSASLNTLM          = 1 << 6;
    public static int AuthTypeSASLKerberosV4    = 1 << 7;
    public static int AuthTypeXOAuth2           = 1 << 8;
    public static int AuthTypeXOAuth2Outlook    = 1 << 9;
}
