package com.libmailcore;

/** Callbacks to provide IMAP data for message rendering. */
public interface HTMLRendererIMAPCallback {
    /**
        Called when the data for the given part are needed. The implementation
        should return the data of the part or returns nil if the data is
        not available.
    */
    byte[] dataForIMAPPart(String folder, IMAPPart part);
    /** Called when the given text part should be fetched. */
    void prefetchAttachmentIMAPPart(String folder, IMAPPart part);
    /** Called when the given image should be fetched. */
    void prefetchImageIMAPPart(String folder, IMAPPart part);
}
