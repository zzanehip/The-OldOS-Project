package com.libmailcore;

/** MIME Part type.
    @see com.libmailcore.AbstractPart#partType() */
public class PartType {
    public final static int PartTypeSingle = 0;
    public final static int PartTypeMessage = 1;
    public final static int PartTypeMultipartMixed = 2;
    public final static int PartTypeMultipartRelated = 3;
    public final static int PartTypeMultipartAlternative = 4;
}
