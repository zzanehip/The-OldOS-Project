package com.libmailcore;

/** Error codes.
    @see com.libmailcore.MailException#errorCode() */
public class ErrorCode {
    /** No error occurred.*/
    public final static int ErrorNone = 0; // 0
    /**
        An error related to the connection occurred.
        It could not connect or it's been disconnected.
    */
    public final static int ErrorConnection = 1;
    /** TLS/SSL connection was not available.*/
    public final static int ErrorTLSNotAvailable = 2;
    /** The protocol could not be parsed.*/
    public final static int ErrorParse = 3;
    /** Certificate was not valid.*/
    public final static int ErrorCertificate = 4;
    /** An authentication error occurred.*/
    public final static int ErrorAuthentication = 5;
    /** Specific to Gmail: IMAP not enabled.*/
    public final static int ErrorGmailIMAPNotEnabled = 6;
    /** Specific to Gmail: Exceeded bandwidth limit.*/
    public final static int ErrorGmailExceededBandwidthLimit = 7;
    /** Specific to Gmail: Too many simultaneous connections.*/
    public final static int ErrorGmailTooManySimultaneousConnections = 8;
    /** Specific to Mobile Me: Moved to iCloud.*/
    public final static int ErrorMobileMeMoved = 9;
    /** Specific to Yahoo: not available.*/
    public final static int ErrorYahooUnavailable = 10; // 10
    /** Non existant folder, select failed.*/
    public final static int ErrorNonExistantFolder = 11;
    /** IMAP: Error occurred while renaming a folder.*/
    public final static int ErrorRename = 12;
    /** IMAP: Error occurred while deleting a folder.*/
    public final static int ErrorDelete = 13;
    /** IMAP: Error occurred while creating a folder.*/
    public final static int ErrorCreate = 14;
    /** IMAP: Error occurred while subscribing/unsubcribing to a folder.*/
    public final static int ErrorSubscribe = 15;
    /** IMAP: Error occurred while adding a message to a folder.*/
    public final static int ErrorAppend = 16;
    /** IMAP: Error occurred while copying a message.*/
    public final static int ErrorCopy = 17;
    /** IMAP: Error occurred while expunging.*/
    public final static int ErrorExpunge = 18;
    /** IMAP: Error occurred while fetching messages.*/
    public final static int ErrorFetch = 19;
    /** IMAP: Error occurred while IDLing.*/
    public final static int ErrorIdle = 20; // 20
    /** IMAP: Error occurred while sending/getting identity.*/
    public final static int ErrorIdentity = 21;
    /** IMAP: Error occurred while getting namespace.*/
    public final static int ErrorNamespace = 22;
    /** IMAP: Error occurred while storing flags.*/
    public final static int ErrorStore = 23;
    /** IMAP: Error wile getting capabilities.*/
    public final static int ErrorCapability = 24;
    /** STARTTLS is not available.*/
    public final static int ErrorStartTLSNotAvailable = 25;
    /** SMTP: Illegal attachment: certain kind of attachment cannot be sent.*/
    public final static int ErrorSendMessageIllegalAttachment = 26;
    /** SMTP: Storage limit: message is probably too big.*/
    public final static int ErrorStorageLimit = 27;
    /** SMTP: Sending message is not allowed.*/
    public final static int ErrorSendMessageNotAllowed = 28;
    /** SMTP: Specific to hotmail. Needs to connect to webmail.*/
    public final static int ErrorNeedsConnectToWebmail = 29;
    /** SMTP: Error while sending message.*/
    public final static int ErrorSendMessage = 30; // 30
    /** SMTP: Authentication required.*/
    public final static int ErrorAuthenticationRequired = 31;
    /** POP: Error occurred while fetching message list.*/
    public final static int ErrorFetchMessageList = 32;
    /** POP: Error occurred while deleting message.*/
    public final static int ErrorDeleteMessage = 33;
    /** SMTP: Error while checking account.*/
    public final static int ErrorInvalidAccount = 34;
    /** Error when accessing/reading/writing file.*/
    public final static int ErrorFile = 35;
    /** IMAP: Error when trying to enable compression.*/
    public final static int ErrorCompression = 36;
    /** SMTP: Error when no sender has been specified.*/
    public final static int ErrorNoSender = 37;
    /** SMTP: Error when no recipient has been specified.*/
    public final static int ErrorNoRecipient = 38;
    /** IMAP: Error when a noop operation fails.*/
    public final static int ErrorNoop = 39;
    /**
        IMAP: Error when the password has been entered but second factor
        authentication is enabled: an application specific password is required.
    */
    public final static int ErrorGmailApplicationSpecificPasswordRequired = 40; // 40
    /** NNTP: error when requesting date */
    public final static int ErrorServerDate = 41;
}
