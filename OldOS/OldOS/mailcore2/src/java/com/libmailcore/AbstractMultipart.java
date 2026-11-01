package com.libmailcore;

import java.util.List;

/** Abstract MIME multipart. */
public class AbstractMultipart extends AbstractPart {
    /** Returns the parts of the MIME multipart. */
    public native List<AbstractPart> parts();
    /** Sets the parts of the MIME multipart. */
    public native void setParts(List<AbstractPart> parts);
}
