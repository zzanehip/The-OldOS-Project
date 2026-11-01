package com.libmailcore;

public class MailException extends Exception {
    /**
        Error code.
        @see com.libmailcore.ErrorCode
    */
    public int errorCode()
    {
        return errorCode;
    }
    
    /** Constructor of an exception with the given code and message. */
    public MailException(String message, int anErrorCode)
    {
        super(message);
        errorCode = anErrorCode;
    }
    
    /** Constructor of an exception with the given code. It will generate a message based on the code. */
    public MailException(int anErrorCode)
    {
        super(messageForErrorCode(anErrorCode));
        errorCode = anErrorCode;
    }
    
    private static native String messageForErrorCode(int errorCode);
    
    private int errorCode;
}