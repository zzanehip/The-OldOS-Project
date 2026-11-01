package com.libmailcore.androidexample;

import com.libmailcore.IMAPMessage;

/**
 * Created by hoa on 1/9/15.
 */
public class MessageAdapter {
    IMAPMessage message;

    public MessageAdapter(IMAPMessage msg) {
        message = msg;
    }

    public String toString() {
        return message.header().from().displayName() + " " + message.header().extractedSubject();
    }
}
