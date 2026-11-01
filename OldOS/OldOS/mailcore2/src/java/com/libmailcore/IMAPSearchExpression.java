package com.libmailcore;

import java.util.Date;

public class IMAPSearchExpression extends NativeObject {
    /** Returns search expression to return all emails. */
    public static native IMAPSearchExpression searchAll();
    /** Returns search expression to return emails matching the From header. */
    public static native IMAPSearchExpression searchFrom(String value);
    /** Returns search expression to return emails matching the To header. */
    public static native IMAPSearchExpression searchTo(String value);
    /** Returns search expression to return emails matching the Cc header. */
    public static native IMAPSearchExpression searchCc(String value);
    /** Returns search expression to return emails matching the Bcc header. */
    public static native IMAPSearchExpression searchBcc(String value);
    /** Returns search expression to return emails matching any recipient header. */
    public static native IMAPSearchExpression searchRecipient(String value);
    /** Returns search expression to return emails matching the Subject header. */
    public static native IMAPSearchExpression searchSubject(String value);
    /** Returns search expression to return emails matching the content. */
    public static native IMAPSearchExpression searchContent(String value);
    /** Returns search expression to return emails matching the body. */
    public static native IMAPSearchExpression searchBody(String value);
    /** Returns search expression to return emails matching a given header. */
    public static native IMAPSearchExpression searchHeader(String header, String value);
    /** Returns search expression to return emails matching a set of UIDs. */
    public static native IMAPSearchExpression searchUIDs(IndexSet uids);
    /** Returns search expression to return read emails. */
    public static native IMAPSearchExpression searchRead();
    /** Returns search expression to return unread emails. */
    public static native IMAPSearchExpression searchUnread();
    /** Returns search expression to return flagged emails. */
    public static native IMAPSearchExpression searchFlagged();
    /** Returns search expression to return unflagged emails. */
    public static native IMAPSearchExpression searchUnflagged();
    /** Returns search expression to return answered emails. */
    public static native IMAPSearchExpression searchAnswered();
    /** Returns search expression to return unanswered emails. */
    public static native IMAPSearchExpression searchUnanswered();
    /** Returns search expression to return drafts. */
    public static native IMAPSearchExpression searchDraft();
    /** Returns search expression to return undrafts. */
    public static native IMAPSearchExpression searchUndraft();
    /** Returns search expression to return emails marked as deleted. */
    public static native IMAPSearchExpression searchDeleted();
    /** Returns search expression to return emails marked as spam. */
    public static native IMAPSearchExpression searchSpam();
    /** Returns search expression to return emails older than a specific date. */
    public static native IMAPSearchExpression searchBeforeDate(Date date);
    /** Returns search expression to return emails that matches a specific date. */
    public static native IMAPSearchExpression searchOnDate(Date date);
    /** Returns search expression to return emails more recent that a specific date. */
    public static native IMAPSearchExpression searchSinceDate(Date date);
    /** Returns search expression to return emails with received date older than a specific date. */
    public static native IMAPSearchExpression searchBeforeReceivedDate(Date date);
    /** Returns search expression to return emails with received date that matches a specific date. */
    public static native IMAPSearchExpression searchOnReceivedDate(Date date);
    /** Returns search expression to return emails with received date more recent than a specific date. */
    public static native IMAPSearchExpression searchSinceReceivedDate(Date date);
    /** Returns search expression to return emails larger than a given size. */
    public static native IMAPSearchExpression searchSizeLarger(long size);
    /** Returns search expression to return emails smaller than a given size. */
    public static native IMAPSearchExpression searchSizeSmaller(long size);
    /** Returns search expression to return emails with a specific thread identifier. */
    public static native IMAPSearchExpression searchGmailThreadID(long number);
    /** Returns search expression to return emails with a specific message identifier. */
    public static native IMAPSearchExpression searchGmailMessageID(long number);
    /** Returns search expression to return emails that match a Gmail search expression. */
    public static native IMAPSearchExpression searchGmailRaw(String expr);
    /** Returns search expression to return emails that match both expressions. */
    public static native IMAPSearchExpression searchAnd(IMAPSearchExpression left, IMAPSearchExpression right);
    /** Returns search expression to return emails that match one of the expressions. */
    public static native IMAPSearchExpression searchOr(IMAPSearchExpression left, IMAPSearchExpression right);
    /** Returns search expression to return emails that don't match a given expression. */
    public static native IMAPSearchExpression searchNot(IMAPSearchExpression notExpr);
}
