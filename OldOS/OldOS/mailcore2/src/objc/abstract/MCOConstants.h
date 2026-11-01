#ifndef MAILCORE_MCOCONSTANTS_H

#define MAILCORE_MCOCONSTANTS_H

/** It's the connection type.*/
typedef NS_OPTIONS(NSInteger, MCOConnectionType) {
    /** Clear-text connection for the protocol.*/
    MCOConnectionTypeClear             = 1 << 0,
    /** Clear-text connection at the beginning, then switch to encrypted connection using TLS/SSL*/
    /** on the same TCP connection.*/
    MCOConnectionTypeStartTLS          = 1 << 1,
    /** Encrypted connection using TLS/SSL.*/
    MCOConnectionTypeTLS               = 1 << 2,
};

/** It's the authentication type.*/
typedef NS_OPTIONS(NSInteger, MCOAuthType) {
    /** Default authentication scheme of the protocol.*/
    MCOAuthTypeSASLNone          = 0,
    /** CRAM-MD5 authentication RFC 2195.*/
    MCOAuthTypeSASLCRAMMD5       = 1 << 0,
    /** PLAIN authentication RFC 4616.*/
    MCOAuthTypeSASLPlain         = 1 << 1,
    /** GSSAPI authentication.*/
    MCOAuthTypeSASLGSSAPI        = 1 << 2,
    /** DIGEST-MD5 authentication RFC 2831.*/
    MCOAuthTypeSASLDIGESTMD5     = 1 << 3,
    /** LOGIN authentication http://tools.ietf.org/id/draft-murchison-sasl-login-00.txt*/
    MCOAuthTypeSASLLogin         = 1 << 4,
    /** Secure Remote Password Authentication http://tools.ietf.org/html/draft-burdis-cat-srp-sasl-08*/
    MCOAuthTypeSASLSRP           = 1 << 5,
    /** NTLM authentication.*/
    MCOAuthTypeSASLNTLM          = 1 << 6,
    /** Kerberos 4 authentication.*/
    MCOAuthTypeSASLKerberosV4    = 1 << 7,
    /** OAuth2 authentication.*/
    MCOAuthTypeXOAuth2           = 1 << 8,
    /** OAuth2 authentication on outlook.com.*/
    MCOAuthTypeXOAuth2Outlook    = 1 << 9,
};

/** It's the IMAP flags of the folder.*/
typedef NS_OPTIONS(NSInteger, MCOIMAPFolderFlag) {
    MCOIMAPFolderFlagNone        = 0,
    /** \Marked*/
    MCOIMAPFolderFlagMarked      = 1 << 0,
    /** \Unmarked*/
    MCOIMAPFolderFlagUnmarked    = 1 << 1,
    /** \NoSelect: When a folder can't be selected.*/
    MCOIMAPFolderFlagNoSelect    = 1 << 2,
    /** \NoInferiors: When the folder has no children.*/
    MCOIMAPFolderFlagNoInferiors = 1 << 3,
    /** \Inbox: When the folder is the inbox.*/
    MCOIMAPFolderFlagInbox       = 1 << 4,
    /** \Sent: When the folder is the sent folder.*/
    MCOIMAPFolderFlagSentMail    = 1 << 5,
    /** \Starred: When the folder is the starred folder*/
    MCOIMAPFolderFlagStarred     = 1 << 6,
    /** \AllMail: When the folder is all mail.*/
    MCOIMAPFolderFlagAllMail     = 1 << 7,
    /** \Trash: When the folder is the trash.*/
    MCOIMAPFolderFlagTrash       = 1 << 8,
    /** \Drafts: When the folder is the drafts folder.*/
    MCOIMAPFolderFlagDrafts      = 1 << 9,
    /** \Spam: When the folder is the spam folder.*/
    MCOIMAPFolderFlagSpam        = 1 << 10,
    /** \Important: When the folder is the important folder.*/
    MCOIMAPFolderFlagImportant   = 1 << 11,
    /** \Archive: When the folder is archive.*/
    MCOIMAPFolderFlagArchive     = 1 << 12,
    /** \All: When the folder contains all mails, similar to \AllMail.*/
    MCOIMAPFolderFlagAll         = MCOIMAPFolderFlagAllMail,
    /** \Junk: When the folder is the spam folder.*/
    MCOIMAPFolderFlagJunk        = MCOIMAPFolderFlagSpam,
    /** \Flagged: When the folder contains all the flagged emails.*/
    MCOIMAPFolderFlagFlagged     = MCOIMAPFolderFlagStarred,
    /** Mask to identify the folder */
    MCOIMAPFolderFlagFolderTypeMask = MCOIMAPFolderFlagInbox | MCOIMAPFolderFlagSentMail | MCOIMAPFolderFlagStarred | MCOIMAPFolderFlagAllMail |
      MCOIMAPFolderFlagTrash| MCOIMAPFolderFlagDrafts | MCOIMAPFolderFlagSpam | MCOIMAPFolderFlagImportant | MCOIMAPFolderFlagArchive,
};

/** It's the flags of a message.*/
typedef NS_OPTIONS(NSInteger, MCOMessageFlag) {
    MCOMessageFlagNone          = 0,
    /** Seen/Read flag.*/
    MCOMessageFlagSeen          = 1 << 0,
    /** Replied/Answered flag.*/
    MCOMessageFlagAnswered      = 1 << 1,
    /** Flagged/Starred flag.*/
    MCOMessageFlagFlagged       = 1 << 2,
    /** Deleted flag.*/
    MCOMessageFlagDeleted       = 1 << 3,
    /** Draft flag.*/
    MCOMessageFlagDraft         = 1 << 4,
    /** $MDNSent flag.*/
    MCOMessageFlagMDNSent       = 1 << 5,
    /** $Forwarded flag.*/
    MCOMessageFlagForwarded     = 1 << 6,
    /** $SubmitPending flag.*/
    MCOMessageFlagSubmitPending = 1 << 7,
    /** $Submitted flag.*/
    MCOMessageFlagSubmitted     = 1 << 8,
};

/** It's the encoding of a part.*/
typedef NS_ENUM(NSInteger, MCOEncoding) {
    /** 7bit encoding.*/
    MCOEncoding7Bit = 0,            /** should match MAILIMAP_BODY_FLD_ENC_7BIT*/
    /** 8bit encoding.*/
    MCOEncoding8Bit = 1,            /** should match MAILIMAP_BODY_FLD_ENC_8BIT*/
    /** binary encoding.*/
    MCOEncodingBinary = 2,          /** should match MAILIMAP_BODY_FLD_ENC_BINARY*/
    /** base64 encoding.*/
    MCOEncodingBase64 = 3,          /** should match MAILIMAP_BODY_FLD_ENC_BASE64*/
    /** quoted-printable encoding.*/
    MCOEncodingQuotedPrintable = 4, /** should match MAILIMAP_BODY_FLD_ENC_QUOTED_PRINTABLE*/
    /** other encoding.*/
    MCOEncodingOther = 5,           /** should match MAILIMAP_BODY_FLD_ENC_OTHER*/
    
    /** Negative values should be used for encoding not supported by libetpan.*/
    
    /** UUEncode encoding.*/
    MCOEncodingUUEncode = -1
};

/** It's the information to fetch for a given message in the IMAP FETCH request.*/
typedef NS_OPTIONS(NSInteger, MCOIMAPMessagesRequestKind) {
    /** UID of the message.*/
    MCOIMAPMessagesRequestKindUid            = 0, /** This is the default and it's always fetched*/
    /** Flags of the message.*/
    MCOIMAPMessagesRequestKindFlags          = 1 << 0,
    /** Headers of the message (parsed by the server).*/
    MCOIMAPMessagesRequestKindHeaders        = 1 << 1,
    /** MIME structure of the message.*/
    MCOIMAPMessagesRequestKindStructure      = 1 << 2,
    /** Received date.*/
    MCOIMAPMessagesRequestKindInternalDate   = 1 << 3,
    /** Headers through headers data.*/
    MCOIMAPMessagesRequestKindFullHeaders    = 1 << 4,
    /** Subject of the message.*/
    MCOIMAPMessagesRequestKindHeaderSubject  = 1 << 5,
    /** Gmail Labels.*/
    MCOIMAPMessagesRequestKindGmailLabels    = 1 << 6,
	/** Gmail Message ID.*/
    MCOIMAPMessagesRequestKindGmailMessageID = 1 << 7,
    /** Gmail Thread ID.*/
    MCOIMAPMessagesRequestKindGmailThreadID  = 1 << 8,
    /** Extra Headers.*/
    MCOIMAPMessagesRequestKindExtraHeaders   = 1 << 9,
    /* Request size of message */
    MCOIMAPMessagesRequestKindSize           = 1 << 10,
    /* Unlike Full headers this will fetch all the non-parsed headers */
    MCOIMAPMessagesRequestKindAllHeaders           = 1 << 11,

};

/** It defines the behavior of the STORE flags request.*/
typedef NS_ENUM(NSInteger, MCOIMAPStoreFlagsRequestKind) {
    /** Add the given flags.*/
    MCOIMAPStoreFlagsRequestKindAdd,
    /** Remove the given flags.*/
    MCOIMAPStoreFlagsRequestKindRemove,
    /** Set the given flags.*/
    MCOIMAPStoreFlagsRequestKindSet,
};

/** It's the search type.*/
typedef NS_ENUM(NSInteger, MCOIMAPSearchKind) {
    /** Search All */
    MCOIMAPSearchKindAll,
    /** No search.*/
    MCOIMAPSearchKindNone,
    /** Match sender.*/
    MCOIMAPSearchKindFrom,
    /** Match to */
    MCOIMAPSearchKindTo,
    /** Match CC: */
    MCOIMAPSearchKindCc,
    /** Match BCC: */
    MCOIMAPSearchKindBcc,
    /** Match recipient.*/
    MCOIMAPSearchKindRecipient,
    /** Match subject.*/
    MCOIMAPSearchKindSubject,
    /** Match content of the message, including the headers.*/
    MCOIMAPSearchKindContent,
    /** Match content of the message, excluding the headers.*/
    MCOIMAPSearchKindBody,
    /** Match uids */
    MCOIMAPSearchKindUids,
    /** Match numbers */
    MCOIMAPSearchKindNumbers,
    /** Match headers of the message.*/
    MCOIMAPSearchKindHeader,
    /** Match messages that are read.*/
    MCOIMAPSearchKindRead,
    /** Match messages that are not read.*/
    MCOIMAPSearchKindUnread,
    /** Match messages that are flagged.*/
    MCOIMAPSearchKindFlagged,
    /** Match messages that are not flagged.*/
    MCOIMAPSearchKindUnflagged,
    /** Match messages that are answered.*/
    MCOIMAPSearchKindAnswered,
    /** Match messages that are not answered.*/
    MCOIMAPSearchKindUnanswered,
    /** Match messages that are a drafts.*/
    MCOIMAPSearchKindDraft,
    /** Match messages that are not drafts.*/
    MCOIMAPSearchKindUndraft,
    /** Match messages that are deleted.*/
    MCOIMAPSearchKindDeleted,
    /** Match messages that are spam.*/
    MCOIMAPSearchKindSpam,
    /** Match messages before the given date.*/
    MCOIMAPSearchKindBeforeDate,
    /** Match messages on the given date.*/
    MCOIMAPSearchKindOnDate,
    /** Match messages after the given date.*/
    MCOIMAPSearchKindSinceDate,
    /** Match messages before the given received date.*/
    MCOIMAPSearchKindBeforeReceivedDate,
    /** Match messages on the given received date.*/
    MCOIMAPSearchKindOnReceivedDate,
    /** Match messages after the given received date.*/
    MCOIMAPSearchKindSinceReceivedDate,
    /** Match messages that are larger than the given size in bytes.*/
    MCOIMAPSearchKindSizeLarger,
    /** Match messages that are smaller than the given size in bytes.*/
    MCOIMAPSearchKindSizeSmaller,
    /** Match X-GM-THRID.*/
    MCOIMAPSearchGmailThreadID,
    /** Match X-GM-MSGID.*/
    MCOIMAPSearchGmailMessageID,
    /** Match X-GM-RAW.*/
    MCOIMAPSearchGmailRaw,
    /** Or expresssion.*/
    MCOIMAPSearchKindOr,
    /** And expression.*/
    MCOIMAPSearchKindAnd,
    /** Not expression.*/
    MCOIMAPSearchKindNot,
};

/** Keys for the namespace dictionary.*/
#define MCOIMAPNamespacePersonal @"IMAPNamespacePersonal"
#define MCOIMAPNamespaceOther @"IMAPNamespaceOther"
#define MCOIMAPNamespaceShared @"IMAPNamespaceShared"

/** This is the constants for the IMAP capabilities.*/
/** See corresponding RFC for more information.*/
typedef NS_ENUM(NSInteger, MCOIMAPCapability) {
    /** ACL Capability.*/
    MCOIMAPCapabilityACL,
    /** BINARY Capability.*/
    MCOIMAPCapabilityBinary,
    /** CATENATE Capability.*/
    MCOIMAPCapabilityCatenate,
    /** CHILDREN Capability.*/
    MCOIMAPCapabilityChildren,
    /** COMPRESS Capability.*/
    MCOIMAPCapabilityCompressDeflate,
    /** CONDSTORE Capability.*/
    MCOIMAPCapabilityCondstore,
    /** ENABLE Capability.*/
    MCOIMAPCapabilityEnable,
    /** IDLE Capability.*/
    MCOIMAPCapabilityIdle,
    /** ID Capability.*/
    MCOIMAPCapabilityId,
    /** LITERAL+ Capability.*/
    MCOIMAPCapabilityLiteralPlus,
    /** MOVE Capability */
    MCOIMAPCapabilityMove,
    /** MULTIAPPEND Capability.*/
    MCOIMAPCapabilityMultiAppend,
    /** NAMESPACE Capability.*/
    MCOIMAPCapabilityNamespace,
    /** QRESYNC Capability.*/
    MCOIMAPCapabilityQResync,
    /** QUOTE Capability.*/
    MCOIMAPCapabilityQuota,
    /** SORT Capability.*/
    MCOIMAPCapabilitySort,
    /** STARTTLS Capability.*/
    MCOIMAPCapabilityStartTLS,
    /** THREAD=ORDEREDSUBJECT Capability.*/
    MCOIMAPCapabilityThreadOrderedSubject,
    /** THREAD=REFERENCES Capability.*/
    MCOIMAPCapabilityThreadReferences,
    /** UIDPLUS Capability.*/
    MCOIMAPCapabilityUIDPlus,
    /** UNSELECT Capability.*/
    MCOIMAPCapabilityUnselect,
    /** XLIST Capability.*/
    MCOIMAPCapabilityXList,
    /** AUTH=ANONYMOUS Capability.*/
    MCOIMAPCapabilityAuthAnonymous,
    /** AUTH=CRAM-MD5 Capability.*/
    MCOIMAPCapabilityAuthCRAMMD5,
    /** AUTH=DIGEST-MD5 Capability.*/
    MCOIMAPCapabilityAuthDigestMD5,
    /** AUTH=EXTERNAL Capability.*/
    MCOIMAPCapabilityAuthExternal,
    /** AUTH=GSSAPI Capability.*/
    MCOIMAPCapabilityAuthGSSAPI,
    /** AUTH=KERBEROSV4 Capability.*/
    MCOIMAPCapabilityAuthKerberosV4,
    /** AUTH=LOGIN Capability.*/
    MCOIMAPCapabilityAuthLogin,
    /** AUTH=NTML Capability.*/
    MCOIMAPCapabilityAuthNTLM,
    /** AUTH=OTP Capability.*/
    MCOIMAPCapabilityAuthOTP,
    /** AUTH=PLAIN Capability.*/
    MCOIMAPCapabilityAuthPlain,
    /** AUTH=SKEY Capability.*/
    MCOIMAPCapabilityAuthSKey,
    /** AUTH=SRP Capability.*/
    MCOIMAPCapabilityAuthSRP,
    /** AUTH=XOAUTH2 Capability.*/
    MCOIMAPCapabilityXOAuth2,
    /** X-GM-EXT-1 Capability.*/
    MCOIMAPCapabilityGmail
};

/** Error domain for mailcore.*/
#define MCOErrorDomain @"MCOErrorDomain"

/** Here's the list of errors.*/
typedef NS_ENUM(NSInteger, MCOErrorCode) {
    /** No error occurred.*/
    MCOErrorNone, // 0
    /** An error related to the connection occurred.*/
    /** It could not connect or it's been disconnected.*/
    MCOErrorConnection,
    /** TLS/SSL connection was not available.*/
    MCOErrorTLSNotAvailable,
    /** The protocol could not be parsed.*/
    MCOErrorParse,
    /** Certificate was not valid.*/
    MCOErrorCertificate,
    /** An authentication error occurred.*/
    MCOErrorAuthentication,
    /** Specific to Gmail: IMAP not enabled.*/
    MCOErrorGmailIMAPNotEnabled,
    /** Specific to Gmail: Exceeded bandwidth limit.*/
    MCOErrorGmailExceededBandwidthLimit,
    /** Specific to Gmail: Too many simultaneous connections.*/
    MCOErrorGmailTooManySimultaneousConnections,
    /** Specific to Mobile Me: Moved to iCloud.*/
    MCOErrorMobileMeMoved,
    /** Specific to Yahoo: not available.*/
    MCOErrorYahooUnavailable, // 10
    /** Non existant folder, select failed.*/
    MCOErrorNonExistantFolder,
    /** IMAP: Error occurred while renaming a folder.*/
    MCOErrorRename,
    /** IMAP: Error occurred while deleting a folder.*/
    MCOErrorDelete,
    /** IMAP: Error occurred while creating a folder.*/
    MCOErrorCreate,
    /** IMAP: Error occurred while subscribing/unsubcribing to a folder.*/
    MCOErrorSubscribe,
    /** IMAP: Error occurred while adding a message to a folder.*/
    MCOErrorAppend,
    /** IMAP: Error occurred while copying a message.*/
    MCOErrorCopy,
    /** IMAP: Error occurred while expunging.*/
    MCOErrorExpunge,
    /** IMAP: Error occurred while fetching messages.*/
    MCOErrorFetch,
    /** IMAP: Error occurred while IDLing.*/
    MCOErrorIdle, // 20
    /** IMAP: Error occurred while sending/getting identity.*/
    MCOErrorIdentity,
    /** IMAP: Error occurred while getting namespace.*/
    MCOErrorNamespace,
    /** IMAP: Error occurred while storing flags.*/
    MCOErrorStore,
    /** IMAP: Error wile getting capabilities.*/
    MCOErrorCapability,
    /** STARTTLS is not available.*/
    MCOErrorStartTLSNotAvailable,
    /** SMTP: Illegal attachment: certain kind of attachment cannot be sent.*/
    MCOErrorSendMessageIllegalAttachment,
    /** SMTP: Storage limit: message is probably too big.*/
    MCOErrorStorageLimit,
    /** SMTP: Sending message is not allowed.*/
    MCOErrorSendMessageNotAllowed,
    /** SMTP: Specific to hotmail. Needs to connect to webmail.*/
    MCOErrorNeedsConnectToWebmail,
    /** SMTP: Error while sending message.*/
    MCOErrorSendMessage, // 30
    /** SMTP: Authentication required.*/
    MCOErrorAuthenticationRequired,
    /** POP: Error occurred while fetching message list.*/
    MCOErrorFetchMessageList,
    /** POP: Error occurred while deleting message.*/
    MCOErrorDeleteMessage,
    /** SMTP: Error while checking account.*/
    MCOErrorInvalidAccount,
    /** Error when accessing/reading/writing file.*/
    MCOErrorFile,
    /** IMAP: Error when trying to enable compression.*/
    MCOErrorCompression,
    /** SMTP: Error when no sender has been specified.*/
    MCOErrorNoSender,
    /** SMTP: Error when no recipient has been specified.*/
    MCOErrorNoRecipient,
    /** IMAP: Error when a noop operation fails.*/
    MCOErrorNoop,
    /** IMAP: Error when the password has been entered but second factor
     authentication is enabled: an application specific password is required. */
    MCOErrorGmailApplicationSpecificPasswordRequired, // 40
    /** NNTP: error when requesting date */
    MCOErrorServerDate,
    /** No valid server found */
    MCOErrorNoValidServerFound,
    /** Error while running custom command */
    MCOErrorCustomCommand,
    /** Spam was suspected by server */
    MCOErrorYahooSendMessageSpamSuspected,
    /** Daily limit of sent messages was hit */
    MCOErrorYahooSendMessageDailyLimitExceeded,
    /** You need to login via the web browser first */
    MCOErrorOutlookLoginViaWebBrowser,
    /** Tiscali Simple Mail Error */
    MCOErrorTiscaliSimplePassword,
    /** The count of all errors */
    MCOErrorCodeCount,
};

/** Error userInfo key for SMTP operations response string */
#define MCOSMTPResponseKey @"MCOSMTPResponseKey"
/** Error userInfo key for SMTP operations response code */
#define MCOSMTPResponseCodeKey @"MCOSMTPResponseCodeKey"

/** Here's the list of connection log types.*/
typedef NS_ENUM(NSInteger, MCOConnectionLogType) {
    /** Received data.*/
    MCOConnectionLogTypeReceived,
    /** Sent data.*/
    MCOConnectionLogTypeSent,
    /** Sent private data. It can be a password.*/
    MCOConnectionLogTypeSentPrivate,
    /** Parse error.*/
    MCOConnectionLogTypeErrorParse,
    /** Error while receiving data. The data passed to the log will be nil.*/
    MCOConnectionLogTypeErrorReceived,
    /** Error while sending dataThe data passed to the log will be nil.*/
    MCOConnectionLogTypeErrorSent,
};

/**
 It's a network traffic logger.
 @param connectionID is the identifier of the underlaying network socket.
 @param type is the type of the log.
 @param data is the data related to the log.
 */
typedef void (^MCOConnectionLogger)(void * connectionID, MCOConnectionLogType type, NSData * data);

/**
 It's called when asynchronous operations stop/start running.
 */
typedef void (^MCOOperationQueueRunningChangeBlock)(void);

/** MCOIMAPResponseKey is a key for NSError userInfo dictionary, the value is string with the server response. */
#define MCOIMAPResponseKey @"MCOIMAPResponseKey"
/** MCOIMAPUnparsedResponseDataKey is a key for NSError userInfo dictionary, the value is data with the unparsed server response in case of ParseError. */
#define MCOIMAPUnparsedResponseDataKey @"MCOIMAPUnparsedResponseDataKey"

#endif
