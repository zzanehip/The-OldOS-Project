package com.libmailcore;

/** MIME encoding.
    See IMAPPart#encoding() */
public class Encoding {
    /** 7-bit encoding. */
    final public static int Encoding7Bit = 0;
    final public static int Encoding8Bit = 1;
    final public static int EncodingBinary = 2;
    final public static int EncodingBase64 = 3;
    final public static int EncodingQuotedPrintable = 4;
    final public static int EncodingOther = 5;
    final public static int EncodingUUEncode = -1;
}
