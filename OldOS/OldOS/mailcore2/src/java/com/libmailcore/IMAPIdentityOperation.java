package com.libmailcore;

/** Operation to notify the identity of the client and get the identity of the server. */
public class IMAPIdentityOperation extends IMAPOperation {
    public native IMAPIdentity serverIdentity();
}
