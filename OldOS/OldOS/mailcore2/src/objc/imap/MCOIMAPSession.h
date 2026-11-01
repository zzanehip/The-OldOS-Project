//
//  MCOIMAPSession.h
//  mailcore2
//
//  Created by Matt Ronge on 1/31/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPSESSION_H

#define MAILCORE_MCOIMAPSESSION_H

#import <Foundation/Foundation.h>
#import <MailCore/MCOConstants.h>

@class MCOIMAPFetchFoldersOperation;
@class MCOIMAPOperation;
@class MCOIMAPNamespace;
@class MCOIMAPFolderInfoOperation;
@class MCOIMAPFolderStatusOperation;
@class MCOIMAPAppendMessageOperation;
@class MCOIMAPCopyMessagesOperation;
@class MCOIMAPMoveMessagesOperation;
@class MCOIndexSet;
@class MCOIMAPFetchMessagesOperation;
@class MCOIMAPFetchContentOperation;
@class MCOIMAPFetchContentToFileOperation;
@class MCOIMAPFetchParsedContentOperation;
@class MCOIMAPSearchOperation;
@class MCOIMAPIdleOperation;
@class MCOIMAPFetchNamespaceOperation;
@class MCOIMAPSearchExpression;
@class MCOIMAPIdentityOperation;
@class MCOIMAPCapabilityOperation;
@class MCOIMAPQuotaOperation;
@class MCOIMAPMessageRenderingOperation;
@class MCOIMAPMessage;
@class MCOIMAPIdentity;
@class MCOIMAPCustomCommandOperation;

/**
 This is the main IMAP class from which all operations are created

 After calling a method that returns an operation you must call start: on the instance
 to begin the operation.
*/

@interface MCOIMAPSession : NSObject

/** This is the hostname of the IMAP server to connect to. */
@property (nonatomic, copy) NSString *hostname;

/** This is the port of the IMAP server to connect to. */
@property (nonatomic, assign) unsigned int port;

/** This is the username of the account. */
@property (nonatomic, copy) NSString *username;

/** This is the password of the account. */
@property (nonatomic, copy) NSString *password;

/** This is the OAuth2 token. */
@property (nonatomic, copy) NSString *OAuth2Token;

/**
 This is the authentication type to use to connect.
 `MCOAuthTypeSASLNone` means that it uses the clear-text is used (and is the default).
 @warning *Important*: Over an encrypted connection like TLS, the password will still be secure
*/
@property (nonatomic, assign) MCOAuthType authType;

/**
 This is the encryption type to use.
 See MCOConnectionType for more information.
*/
@property (nonatomic, assign) MCOConnectionType connectionType;

/** This is the timeout of the connection. */
@property (nonatomic, assign) NSTimeInterval timeout;

/** When set to YES, the connection will fail if the certificate is incorrect. */
@property (nonatomic, assign, getter=isCheckCertificateEnabled) BOOL checkCertificateEnabled;

/** When set to YES, VoIP capability will be enabled on the IMAP connection on iOS */
@property (nonatomic, assign, getter=isVoIPEnabled) BOOL voIPEnabled;

/** The default namespace. */
@property (nonatomic, strong) MCOIMAPNamespace * defaultNamespace;

/** The identity of the IMAP client. */
@property (nonatomic, copy) MCOIMAPIdentity * clientIdentity;

/** The identity of the IMAP server. */
@property (nonatomic, strong, readonly) MCOIMAPIdentity * serverIdentity;

/**
 Display name of the Gmail user. It will be nil if it's not a Gmail server.

 ** DEPRECATED **
 This attribute has been broken by Gmail IMAP server. It's not longer available
 as a correct display name.
*/
@property (nonatomic, copy, readonly) NSString * gmailUserDisplayName DEPRECATED_ATTRIBUTE;

@property (nonatomic, assign, readonly, getter=isIdleEnabled) BOOL idleEnabled;

/**
 When set to YES, the session is allowed open to open several connections to the same folder.
 @warning Some older IMAP servers don't like this
*/
@property (nonatomic, assign) BOOL allowsFolderConcurrentAccessEnabled;

/**
 Maximum number of connections to the server allowed.
*/
@property (nonatomic, assign) unsigned int maximumConnections;

/**
 Sets logger callback. The network traffic will be sent to this block.

 [session setConnectionLogger:^(void * connectionID, MCOConnectionLogType type, NSData * data) {
    NSLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
    // ...
 }];
*/
@property (nonatomic, copy) MCOConnectionLogger connectionLogger;

/** This property provides some hints to MCOIMAPSession about where it's called from.
 It will make MCOIMAPSession safe. It will also set all the callbacks of operations to run on this given queue.
 Defaults to the main queue.
 This property should be used only if there's performance issue using MCOIMAPSession in the main thread. */
#if OS_OBJECT_USE_OBJC
@property (nonatomic, retain) dispatch_queue_t dispatchQueue;
#else
@property (nonatomic, assign) dispatch_queue_t dispatchQueue;
#endif

/**
 The value will be YES when asynchronous operations are running, else it will return NO.
*/
@property (nonatomic, assign, readonly, getter=isOperationQueueRunning) BOOL operationQueueRunning;

/**
 Sets operation running callback. It will be called when operations start or stop running.

 [session setOperationQueueRunningChangeBlock:^{
   if ([session isOperationQueueRunning]) {
     ...
   }
   else {
     ...
   }
 }];
*/
@property (nonatomic, copy) MCOOperationQueueRunningChangeBlock operationQueueRunningChangeBlock;

/**
 Cancel all operations
 */
- (void) cancelAllOperations;

/** @name Folder Operations */

/**
 Returns an operation that retrieves folder metadata (like UIDNext)

     MCOIMAPFolderInfoOperation * op = [session folderInfoOperation:@"INBOX"];
     [op start:^(NSError *error, MCOIMAPFolderInfo * info) {
          NSLog(@"UIDNEXT: %lu", (unsigned long) [info uidNext]);
          NSLog(@"UIDVALIDITY: %lu", (unsigned long) [info uidValidity]);
          NSLog(@"HIGHESTMODSEQ: %llu", (unsigned long long) [info modSequenceValue]);
          NSLog(@"messages count: %lu", [info messageCount]);
     }];
*/

- (MCOIMAPFolderInfoOperation *) folderInfoOperation:(NSString *)folder;

/**
 Returns an operation that retrieves folder status (like UIDNext - Unseen -)

    MCOIMAPFolderStatusOperation * op = [session folderStatusOperation:@"INBOX"];
    [op start:^(NSError *error, MCOIMAPFolderStatus * info) {
        NSLog(@"UIDNEXT: %lu", (unsigned long) [info uidNext]);
        NSLog(@"UIDVALIDITY: %lu", (unsigned long) [info uidValidity]);
        NSLog(@"messages count: %lu", [info totalMessages]);
 	}];
 */

- (MCOIMAPFolderStatusOperation *) folderStatusOperation:(NSString *)folder;

/**
 Returns an operation that gets the list of subscribed folders.

    MCOIMAPFetchFoldersOperation * op = [session fetchSubscribedFoldersOperation];
    [op start:^(NSError * __nullable error, NSArray * folders) {
        ...
    }];
 */

- (MCOIMAPFetchFoldersOperation *) fetchSubscribedFoldersOperation;

/**
 Returns an operation that gets all folders

     MCOIMAPFetchFoldersOperation * op = [session fetchAllFoldersOperation];
     [op start:^(NSError * __nullable error, NSArray *folders) {
          ...
     }];
*/
- (MCOIMAPFetchFoldersOperation *) fetchAllFoldersOperation;

/**
 Creates an operation for renaming a folder

     MCOIMAPOperation * op = [session renameFolderOperation:@"my documents" otherName:@"Documents"];
     [op start:^(NSError * __nullable error) {
        ...
     }];

*/
- (MCOIMAPOperation *) renameFolderOperation:(NSString *)folder otherName:(NSString *)otherName;

/**
 Create an operation for deleting a folder

     MCOIMAPOperation * op = [session deleteFolderOperation:@"holidays 2009"];
     [op start:^(NSError * __nullable error) {
          ...
     }]];
*/
- (MCOIMAPOperation *) deleteFolderOperation:(NSString *)folder;

/**
 Returns an operation that creates a new folder

     MCOIMAPOperation * op = [session createFolderOperation:@"holidays 2013"];
     [op start:^(NSError * __nullable error) {
          ...
     }];
*/
- (MCOIMAPOperation *) createFolderOperation:(NSString *)folder;

/**
 Returns an operation to subscribe to a folder.

     MCOIMAPOperation * op = [session createFolderOperation:@"holidays 2013"];
     [op start:^(NSError * __nullable error) {
       if (error != nil)
         return;
       MCOIMAPOperation * op = [session subscribeFolderOperation:@"holidays 2013"];
       ...
     }];
*/
- (MCOIMAPOperation *) subscribeFolderOperation:(NSString *)folder;

/**
 Returns an operation to unsubscribe from a folder.

     MCOIMAPOperation * op = [session unsubscribeFolderOperation:@"holidays 2009"];
     [op start:^(NSError * __nullable error) {
       if (error != nil)
         return;
       MCOIMAPOperation * op = [session deleteFolderOperation:@"holidays 2009"]
       ...
     }];
*/
- (MCOIMAPOperation *) unsubscribeFolderOperation:(NSString *)folder;

/**
 Returns an operation to expunge a folder.

     MCOIMAPOperation * op = [session expungeOperation:@"INBOX"];
     [op start:^(NSError * __nullable error) {
          ...
     }];
*/
- (MCOIMAPOperation *) expungeOperation:(NSString *)folder;

/** @name Message Actions */

/**
 Returns an operation to add a message to a folder.

     MCOIMAPOperation * op = [session appendMessageOperationWithFolder:@"Sent Mail" messageData:rfc822Data flags:MCOMessageFlagNone];
     [op start:^(NSError * __nullable error, uint32_t createdUID) {
       if (error == nil) {
         NSLog(@"created message with UID %lu", (unsigned long) createdUID);
       }
     }];
*/
- (MCOIMAPAppendMessageOperation *)appendMessageOperationWithFolder:(NSString *)folder
                                                        messageData:(NSData *)messageData
                                                              flags:(MCOMessageFlag)flags;

/**
 Returns an operation to add a message with custom flags to a folder.

     MCOIMAPOperation * op = [session appendMessageOperationWithFolder:@"Sent Mail" messageData:rfc822Data flags:MCOMessageFlagNone customFlags:@[@"$CNS-Greeting-On"]];
     [op start:^(NSError * __nullable error, uint32_t createdUID) {
       if (error == nil) {
         NSLog(@"created message with UID %lu", (unsigned long) createdUID);
       }
     }];
 */
- (MCOIMAPAppendMessageOperation *)appendMessageOperationWithFolder:(NSString *)folder
                                                        messageData:(NSData *)messageData
                                                              flags:(MCOMessageFlag)flags
                                                        customFlags:(NSArray<NSString *> *)customFlags;

/**
 Returns an operation to add a message with custom flags to a folder.

     MCOIMAPOperation * op = [session appendMessageOperationWithFolder:@"Sent Mail"
                                                        contentsAtPath:rfc822DataFilename
                                                                 flags:MCOMessageFlagNone
                                                           customFlags:@[@"$CNS-Greeting-On"]];
     [op start:^(NSError * __nullable error, uint32_t createdUID) {
       if (error == nil) {
         NSLog(@"created message with UID %lu", (unsigned long) createdUID);
       }
     }];
 */
- (MCOIMAPAppendMessageOperation *)appendMessageOperationWithFolder:(NSString *)folder
                                                     contentsAtPath:(NSString *)path
                                                              flags:(MCOMessageFlag)flags
                                                        customFlags:(NSArray<NSString *> *)customFlags;

/**
 Returns an operation to copy messages to a folder.

     MCOIMAPCopyMessagesOperation * op = [session copyMessagesOperationWithFolder:@"INBOX"
                                                                             uids:[MCIndexSet indexSetWithIndex:456]
                                                                       destFolder:@"Cocoa"];
     [op start:^(NSError * __nullable error, NSDictionary * uidMapping) {
          NSLog(@"copied to folder with UID mapping %@", uidMapping);
     }];
*/
- (MCOIMAPCopyMessagesOperation *)copyMessagesOperationWithFolder:(NSString *)folder
                                                             uids:(MCOIndexSet *)uids
                                                       destFolder:(NSString *)destFolder NS_RETURNS_NOT_RETAINED;

/**
 Returns an operation to move messages to a folder.

     MCOIMAPMoveMessagesOperation * op = [session moveMessagesOperationWithFolder:@"INBOX"
                                                                             uids:[MCIndexSet indexSetWithIndex:456]
                                                                       destFolder:@"Cocoa"];
     [op start:^(NSError * __nullable error, NSDictionary * uidMapping) {
          NSLog(@"moved to folder with UID mapping %@", uidMapping);
     }];
*/
- (MCOIMAPMoveMessagesOperation *)moveMessagesOperationWithFolder:(NSString *)folder
                                                             uids:(MCOIndexSet *)uids
                                                       destFolder:(NSString *)destFolder NS_RETURNS_NOT_RETAINED;

/**
 Returns an operation to change flags of messages.

 For example: Adds the seen flag to the message with UID 456.

     MCOIMAPOperation * op = [session storeFlagsOperationWithFolder:@"INBOX"
                                                               uids:[MCOIndexSet indexSetWithIndex:456]
                                                               kind:MCOIMAPStoreFlagsRequestKindAdd
                                                              flags:MCOMessageFlagSeen];
     [op start:^(NSError * __nullable error) {
          ...
     }];
*/
- (MCOIMAPOperation *) storeFlagsOperationWithFolder:(NSString *)folder
                                                uids:(MCOIndexSet *)uids
                                                kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               flags:(MCOMessageFlag)flags;

/**
 Returns an operation to change flags of messages, using IMAP sequence number.

 For example: Adds the seen flag to the message with the sequence number number 42.

     MCOIMAPOperation * op = [session storeFlagsOperationWithFolder:@"INBOX"
                                                            numbers:[MCOIndexSet indexSetWithIndex:42]
                                                               kind:MCOIMAPStoreFlagsRequestKindAdd
                                                              flags:MCOMessageFlagSeen];
     [op start:^(NSError * __nullable error) {
          ...
     }];
 */
- (MCOIMAPOperation *) storeFlagsOperationWithFolder:(NSString *)folder
                                             numbers:(MCOIndexSet *)numbers
                                                kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               flags:(MCOMessageFlag)flags;

/**
 Returns an operation to change flags and custom flags of messages.

 For example: Adds the seen flag and $CNS-Greeting-On flag to the message with UID 456.

     MCOIMAPOperation * op = [session storeFlagsOperationWithFolder:@"INBOX"
                                                               uids:[MCOIndexSet indexSetWithIndex:456]
                                                               kind:MCOIMAPStoreFlagsRequestKindAdd
                                                              flags:MCOMessageFlagSeen
                                                        customFlags:@["$CNS-Greeting-On"]];
     [op start:^(NSError * __nullable error) {
         ...
     }];
 */
- (MCOIMAPOperation *) storeFlagsOperationWithFolder:(NSString *)folder
                                                uids:(MCOIndexSet *)uids
                                                kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               flags:(MCOMessageFlag)flags
                                         customFlags:(NSArray<NSString *> *)customFlags;


/**
 Returns an operation to change flags and custom flags of messages, using IMAP sequence number.

 For example: Adds the seen flag and $CNS-Greeting-On flag to the message with the sequence number 42.

     MCOIMAPOperation * op = [session storeFlagsOperationWithFolder:@"INBOX"
                                                            numbers:[MCOIndexSet indexSetWithIndex:42]
                                                               kind:MCOIMAPStoreFlagsRequestKindAdd
                                                              flags:MCOMessageFlagSeen
                                                        customFlags:@["$CNS-Greeting-On"]];
     [op start:^(NSError * __nullable error) {
         ...
     }];
 */
- (MCOIMAPOperation *) storeFlagsOperationWithFolder:(NSString *)folder
                                             numbers:(MCOIndexSet *)numbers
                                                kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               flags:(MCOMessageFlag)flags
                                         customFlags:(NSArray<NSString *> *)customFlags;

/**
 Returns an operation to change labels of messages. Intended for Gmail

 For example: Adds the label "Home" flag to the message with UID 42.

     MCOIMAPOperation * op = [session storeLabelsOperationWithFolder:@"INBOX"
                                                             numbers:[MCOIndexSet indexSetWithIndex:42]
                                                                kind:MCOIMAPStoreFlagsRequestKindAdd
                                                              labels:[NSArray arrayWithObject:@"Home"]];
     [op start:^(NSError * __nullable error) {
          ...
     }];
*/
- (MCOIMAPOperation *) storeLabelsOperationWithFolder:(NSString *)folder
                                              numbers:(MCOIndexSet *)numbers
                                                 kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               labels:(NSArray<NSString *> *)labels;

/**
 Returns an operation to change labels of messages. Intended for Gmail

 For example: Adds the label "Home" flag to the message with UID 456.

     MCOIMAPOperation * op = [session storeLabelsOperationWithFolder:@"INBOX"
                                                                uids:[MCOIndexSet indexSetWithIndex:456]
                                                                kind:MCOIMAPStoreFlagsRequestKindAdd
                                                              labels:[NSArray arrayWithObject:@"Home"]];
     [op start:^(NSError * __nullable error) {
          ...
     }];
*/
- (MCOIMAPOperation *) storeLabelsOperationWithFolder:(NSString *)folder
                                                 uids:(MCOIndexSet *)uids
                                                 kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               labels:(NSArray<NSString *> *)labels;

/** @name Fetching Messages */

/**
 Returns an operation to fetch messages by UID.

     MCOIMAPFetchMessagesOperation * op = [session fetchMessagesByUIDOperationWithFolder:@"INBOX"
                                                                             requestKind:MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure
                                                                                    uids:MCORangeMake(1, UINT64_MAX)];
     [op start:^(NSError * __nullable error, NSArray * messages, MCOIndexSet * vanishedMessages) {
        for(MCOIMAPMessage * msg in messages) {
          NSLog(@"%lu: %@", [msg uid], [msg header]);
        }
     }];
*/
- (MCOIMAPFetchMessagesOperation *) fetchMessagesByUIDOperationWithFolder:(NSString *)folder
                                                              requestKind:(MCOIMAPMessagesRequestKind)requestKind
                                                                     uids:(MCOIndexSet *)uids DEPRECATED_ATTRIBUTE;

/**
 Returns an operation to fetch messages by UID.

     MCOIMAPFetchMessagesOperation * op = [session fetchMessagesOperationWithFolder:@"INBOX"
                                                                        requestKind:MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure
                                                                               uids:MCORangeMake(1, UINT64_MAX)];
     [op start:^(NSError * __nullable error, NSArray * messages, MCOIndexSet * vanishedMessages) {
        for(MCOIMAPMessage * msg in messages) {
          NSLog(@"%lu: %@", [msg uid], [msg header]);
        }
     }];
*/
- (MCOIMAPFetchMessagesOperation *) fetchMessagesOperationWithFolder:(NSString *)folder
                                                         requestKind:(MCOIMAPMessagesRequestKind)requestKind
                                                                uids:(MCOIndexSet *)uids;

/**
 Returns an operation to fetch messages by (sequence) number.
 For example: show 50 most recent uids.
     NSString *folder = @"INBOX";
     MCOIMAPFolderInfoOperation *folderInfo = [session folderInfoOperation:folder];

     [folderInfo start:^(NSError *error, MCOIMAPFolderInfo *info) {
         int numberOfMessages = 50;
         numberOfMessages -= 1;
         MCOIndexSet *numbers = [MCOIndexSet indexSetWithRange:MCORangeMake([info messageCount] - numberOfMessages, numberOfMessages)];

         MCOIMAPFetchMessagesOperation *fetchOperation = [session fetchMessagesByNumberOperationWithFolder:folder
                                                                                               requestKind:MCOIMAPMessagesRequestKindUid
                                                                                                   numbers:numbers];

         [fetchOperation start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
             for (MCOIMAPMessage * message in messages) {
                 NSLog(@"%u", [message uid]);
             }
         }];
     }];
*/
- (MCOIMAPFetchMessagesOperation *) fetchMessagesByNumberOperationWithFolder:(NSString *)folder
                                                                 requestKind:(MCOIMAPMessagesRequestKind)requestKind
                                                                     numbers:(MCOIndexSet *)numbers;

/**
 Returns an operation to sync the last changes related to the given message list given a modSeq.

     MCOIMAPFetchMessagesOperation * op = [session syncMessagesByUIDWithFolder:@"INBOX"
                                                                   requestKind:MCOIMAPMessagesRequestKindUID
                                                                          uids:MCORangeMake(1, UINT64_MAX)
                                                                        modSeq:lastModSeq];
     [op start:^(NSError * __nullable error, NSArray * messages, MCOIndexSet * vanishedMessages) {
       NSLog(@"added or modified messages: %@", messages);
       NSLog(@"deleted messages: %@", vanishedMessages);
     }];

@warn *Important*: This is only for servers that support Conditional Store. See [RFC4551](http://tools.ietf.org/html/rfc4551)
vanishedMessages will be set only for servers that support QRESYNC. See [RFC5162](http://tools.ietf.org/html/rfc5162)
*/
- (MCOIMAPFetchMessagesOperation *) syncMessagesByUIDWithFolder:(NSString *)folder
                                                    requestKind:(MCOIMAPMessagesRequestKind)requestKind
                                                           uids:(MCOIndexSet *)uids
                                                         modSeq:(uint64_t)modSeq DEPRECATED_ATTRIBUTE;

/**
 Returns an operation to sync the last changes related to the given message list given a modSeq.

     MCOIMAPFetchMessagesOperation * op = [session syncMessagesWithFolder:@"INBOX"
                                                              requestKind:MCOIMAPMessagesRequestKindUID
                                                                     uids:MCORangeMake(1, UINT64_MAX)
                                                                   modSeq:lastModSeq];
     [op start:^(NSError * __nullable error, NSArray * messages, MCOIndexSet * vanishedMessages) {
       NSLog(@"added or modified messages: %@", messages);
       NSLog(@"deleted messages: %@", vanishedMessages);
     }];

@warn *Important*: This is only for servers that support Conditional Store. See [RFC4551](http://tools.ietf.org/html/rfc4551)
vanishedMessages will be set only for servers that support QRESYNC. See [RFC5162](http://tools.ietf.org/html/rfc5162)
*/
- (MCOIMAPFetchMessagesOperation *) syncMessagesWithFolder:(NSString *)folder
                                              requestKind:(MCOIMAPMessagesRequestKind)requestKind
                                                     uids:(MCOIndexSet *)uids
                                                   modSeq:(uint64_t)modSeq;

/**
 Returns an operation to fetch the content of a message.
 @param urgent is set to YES, an additional connection to the same folder might be opened to fetch the content.

     MCOIMAPFetchContentOperation * op = [session fetchMessageByUIDOperationWithFolder:@"INBOX" uid:456 urgent:NO];
     [op start:^(NSError * __nullable error, NSData * messageData) {
        MCOMessageParser * parser = [MCOMessageParser messageParserWithData:messageData]
        ...
     }];
*/
- (MCOIMAPFetchContentOperation *) fetchMessageByUIDOperationWithFolder:(NSString *)folder
                                                                    uid:(uint32_t)uid
                                                                 urgent:(BOOL)urgent DEPRECATED_ATTRIBUTE;

/**
 Returns an operation to fetch the content of a message.

     MCOIMAPFetchContentOperation * op = [session fetchMessageByUIDOperationWithFolder:@"INBOX" uid:456];
     [op start:^(NSError * __nullable error, NSData * messageData) {
        MCOMessageParser * parser = [MCOMessageParser messageParserWithData:messageData]
        ...
     }];
*/
- (MCOIMAPFetchContentOperation *) fetchMessageByUIDOperationWithFolder:(NSString *)folder
                                                                    uid:(uint32_t)uid DEPRECATED_ATTRIBUTE;

/**
 Returns an operation to fetch the content of a message.
 @param urgent is set to YES, an additional connection to the same folder might be opened to fetch the content.

     MCOIMAPFetchContentOperation * op = [session fetchMessageOperationWithFolder:@"INBOX" uid:456 urgent:NO];
     [op start:^(NSError * __nullable error, NSData * messageData) {
        MCOMessageParser * parser = [MCOMessageParser messageParserWithData:messageData]
        ...
     }];
 */
- (MCOIMAPFetchContentOperation *) fetchMessageOperationWithFolder:(NSString *)folder
                                                               uid:(uint32_t)uid
                                                            urgent:(BOOL)urgent;

/**
 Returns an operation to fetch the content of a message.

     MCOIMAPFetchContentOperation * op = [session fetchMessageOperationWithFolder:@"INBOX" uid:456];
     [op start:^(NSError * __nullable error, NSData * messageData) {
        MCOMessageParser * parser = [MCOMessageParser messageParserWithData:messageData]
        ...
     }];
 */
- (MCOIMAPFetchContentOperation *) fetchMessageOperationWithFolder:(NSString *)folder
                                                               uid:(uint32_t)uid;

/**
 Returns an operation to fetch the content of a message, using IMAP sequence number.
 @param urgent is set to YES, an additional connection to the same folder might be opened to fetch the content.

     MCOIMAPFetchContentOperation * op = [session fetchMessageOperationWithFolder:@"INBOX" number:42 urgent:NO];
     [op start:^(NSError * __nullable error, NSData * messageData) {
        MCOMessageParser * parser = [MCOMessageParser messageParserWithData:messageData]
        ...
     }];
*/
- (MCOIMAPFetchContentOperation *) fetchMessageOperationWithFolder:(NSString *)folder
                                                            number:(uint32_t)number
                                                            urgent:(BOOL)urgent;

/**
 Returns an operation to fetch the content of a message, using IMAP sequence number.

     MCOIMAPFetchContentOperation * op = [session fetchMessageOperationWithFolder:@"INBOX" number:42];
     [op start:^(NSError * __nullable error, NSData * messageData) {
        MCOMessageParser * parser = [MCOMessageParser messageParserWithData:messageData]
        ...
     }];
*/
- (MCOIMAPFetchContentOperation *) fetchMessageOperationWithFolder:(NSString *)folder
                                                             number:(uint32_t)number;

/**
 Returns an operation to fetch the parsed content of a message.
 @param urgent is set to YES, an additional connection to the same folder might be opened to fetch the content.

 MCOIMAPFetchParsedContentOperation * op = [session fetchParsedMessageOperationWithFolder:@"INBOX" uid:456 urgent:NO];
 [op start:^(NSError * __nullable error, MCOMessageParser * parser) {

 ...
 }];
 */
- (MCOIMAPFetchParsedContentOperation *) fetchParsedMessageOperationWithFolder:(NSString *)folder
                                                                           uid:(uint32_t)uid
                                                                        urgent:(BOOL)urgent;

/**
 Returns an operation to fetch the parsed content of a message.

 MCOIMAPFetchParsedContentOperation * op = [session fetchParsedMessageOperationWithFolder:@"INBOX" uid:456];
 [op start:^(NSError * __nullable error, MCOMessageParser * parser) {

 ...
 }];
 */
- (MCOIMAPFetchParsedContentOperation *) fetchParsedMessageOperationWithFolder:(NSString *)folder
                                                                           uid:(uint32_t)uid;

/**
 Returns an operation to fetch the parsed content of a message, using IMAP sequence number.
 @param urgent is set to YES, an additional connection to the same folder might be opened to fetch the content.

 MCOIMAPFetchParsedContentOperation * op = [session fetchParsedMessageOperationWithFolder:@"INBOX" number:42 urgent:NO];
 [op start:^(NSError * __nullable error, MCOMessageParser * parser) {

 ...
 }];
 */
- (MCOIMAPFetchParsedContentOperation *) fetchParsedMessageOperationWithFolder:(NSString *)folder
                                                                        number:(uint32_t)number
                                                                        urgent:(BOOL)urgent;

/**
 Returns an operation to fetch the parsed content of a message, using IMAP sequence number.

 MCOIMAPFetchParsedContentOperation * op = [session fetchParsedMessageOperationWithFolder:@"INBOX" number:42];
 [op start:^(NSError * __nullable error, MCOMessageParser * parser) {

 ...
 }];
 */
- (MCOIMAPFetchParsedContentOperation *) fetchParsedMessageOperationWithFolder:(NSString *)folder
                                                                        number:(uint32_t)number;

/** @name Fetching Attachment Operations */

/**
 Returns an operation to fetch an attachment.
 @param  urgent is set to YES, an additional connection to the same folder might be opened to fetch the content.

     MCOIMAPFetchContentOperation * op = [session fetchMessageAttachmentByUIDOperationWithFolder:@"INBOX"
                                                                                             uid:456
                                                                                          partID:@"1.2"
                                                                                        encoding:MCOEncodingBase64
                                                                                          urgent:YES];
     [op start:^(NSError * __nullable error, NSData * partData) {
        ...
     }];
*/
- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentByUIDOperationWithFolder:(NSString *)folder
                                                                              uid:(uint32_t)uid
                                                                           partID:(NSString *)partID
                                                                         encoding:(MCOEncoding)encoding
                                                                           urgent:(BOOL)urgent DEPRECATED_ATTRIBUTE;

/**
 Returns an operation for custom command.
 @param command is the text representation of the command to be send.
 
 
 MCOIMAPCustomCommandOperation * op = [session customCommandOperation:@"ACTIVATE SERVICE"];
 [op start: ^(NSString * __nullable response, NSError * __nullable error) {
   ...
 }];
 */
- (MCOIMAPCustomCommandOperation *) customCommandOperation:(NSString *)command;

/**
  Returns an operation to fetch an attachment.

  Example 1:

     MCOIMAPFetchContentOperation * op = [session fetchMessageAttachmentByUIDOperationWithFolder:@"INBOX"
                                                                                             uid:456
                                                                                          partID:@"1.2"
                                                                                        encoding:MCOEncodingBase64];
     [op start:^(NSError * __nullable error, NSData * partData) {
        ...
     }];

  Example 2:

     MCOIMAPFetchContentOperation * op = [session fetchMessageAttachmentByUIDOperationWithFolder:@"INBOX"
                                                                                             uid:[message uid]
                                                                                          partID:[part partID]
                                                                                        encoding:[part encoding]];
     [op start:^(NSError * __nullable error, NSData * partData) {
        ...
     }];
*/
- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentByUIDOperationWithFolder:(NSString *)folder
                                                                              uid:(uint32_t)uid
                                                                           partID:(NSString *)partID
                                                                         encoding:(MCOEncoding)encoding DEPRECATED_ATTRIBUTE;

/**
 Returns an operation to fetch an attachment.
 @param  urgent is set to YES, an additional connection to the same folder might be opened to fetch the content.

     MCOIMAPFetchContentOperation * op = [session fetchMessageAttachmentOperationWithFolder:@"INBOX"
                                                                                             uid:456
                                                                                          partID:@"1.2"
                                                                                        encoding:MCOEncodingBase64
                                                                                          urgent:YES];
     [op start:^(NSError * __nullable error, NSData * partData) {
        ...
     }];
*/
- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentOperationWithFolder:(NSString *)folder
                                                                         uid:(uint32_t)uid
                                                                      partID:(NSString *)partID
                                                                    encoding:(MCOEncoding)encoding
                                                                      urgent:(BOOL)urgent;

/**
  Returns an operation to fetch an attachment.

  Example 1:

     MCOIMAPFetchContentOperation * op = [session fetchMessageAttachmentOperationWithFolder:@"INBOX"
                                                                                        uid:456
                                                                                     partID:@"1.2"
                                                                                   encoding:MCOEncodingBase64];
     [op start:^(NSError * __nullable error, NSData * partData) {
        ...
     }];

  Example 2:

     MCOIMAPFetchContentOperation * op = [session fetchMessageAttachmentOperationWithFolder:@"INBOX"
                                                                                        uid:[message uid]
                                                                                     partID:[part partID]
                                                                                   encoding:[part encoding]];
     [op start:^(NSError * __nullable error, NSData * partData) {
        ...
     }];
*/
- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentOperationWithFolder:(NSString *)folder
                                                                         uid:(uint32_t)uid
                                                                      partID:(NSString *)partID
                                                                    encoding:(MCOEncoding)encoding;

/**
 Returns an operation to fetch an attachment.
 @param  urgent is set to YES, an additional connection to the same folder might be opened to fetch the content.

     MCOIMAPFetchContentOperation * op = [session fetchMessageAttachmentOperationWithFolder:@"INBOX"
                                                                                             uid:456
                                                                                          partID:@"1.2"
                                                                                        encoding:MCOEncodingBase64
                                                                                          urgent:YES];
     [op start:^(NSError * __nullable error, NSData * partData) {
        ...
     }];
*/
- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentOperationWithFolder:(NSString *)folder
                                                                      number:(uint32_t)number
                                                                      partID:(NSString *)partID
                                                                    encoding:(MCOEncoding)encoding
                                                                      urgent:(BOOL)urgent;

/**
  Returns an operation to fetch an attachment.

  Example 1:

     MCOIMAPFetchContentOperation * op = [session fetchMessageAttachmentOperationWithFolder:@"INBOX"
                                                                                     number:42
                                                                                     partID:@"1.2"
                                                                                   encoding:MCOEncodingBase64];
     [op start:^(NSError * __nullable error, NSData * partData) {
        ...
     }];

  Example 2:

     MCOIMAPFetchContentOperation * op = [session fetchMessageAttachmentOperationWithFolder:@"INBOX"
                                                                                     number:[message sequenceNumber]
                                                                                     partID:[part partID]
                                                                                   encoding:[part encoding]];
     [op start:^(NSError * __nullable error, NSData * partData) {
        ...
     }];
*/
- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentOperationWithFolder:(NSString *)folder
                                                                      number:(uint32_t)number
                                                                      partID:(NSString *)partID
                                                                    encoding:(MCOEncoding)encoding;

/**
 Returns an operation to fetch an attachment to a file.
 @param  urgent is set to YES, an additional connection to the same folder might be opened to fetch the content.
 Operation will be perform in a memory efficient manner.

     MCOIMAPFetchContentToFileOperation * op = [session fetchMessageAttachmentToFileOperationWithFolder:@"INBOX"
                                                                                                    uid:456
                                                                                                 partID:@"1.2"
                                                                                               encoding:MCOEncodingBase64
                                                                                               filename:filename
                                                                                                 urgent:YES];

     // Optionally, explicitly enable chunked mode
     [op setLoadingByChunksEnabled:YES];
     [op setChunksSize:1024*1024];
     // need in chunked mode for correct progress indication
     [op setEstimatedSize:sizeOfAttachFromBodystructure];

     [op start:^(NSError * __nullable error) {
         ...
     }];

 */
- (MCOIMAPFetchContentToFileOperation *) fetchMessageAttachmentToFileOperationWithFolder:(NSString *)folder
                                                                                     uid:(uint32_t)uid
                                                                                  partID:(NSString *)partID
                                                                                encoding:(MCOEncoding)encoding
                                                                                filename:(NSString *)filename
                                                                                  urgent:(BOOL)urgent;


/** @name General IMAP Actions */

/**
 Returns an operation to wait for something to happen in the folder.
 See [RFC2177](http://tools.ietf.org/html/rfc2177) for me info.

     MCOIMAPIdleOperation * op = [session idleOperationWithFolder:@"INBOX"
                                                     lastKnownUID:0];
     [op start:^(NSError * __nullable error) {
          ...
     }];
*/
- (MCOIMAPIdleOperation *) idleOperationWithFolder:(NSString *)folder
                                      lastKnownUID:(uint32_t)lastKnownUID;

/**
 Returns an operation to fetch the list of namespaces.

     MCOIMAPFetchNamespaceOperation * op = [session fetchNamespaceOperation];
     [op start:^(NSError * __nullable error, NSDictionary * namespaces) {
       if (error != nil)
         return;
       MCOIMAPNamespace * ns = [namespace objectForKey:MCOIMAPNamespacePersonal];
       NSString * path = [ns pathForComponents:[NSArray arrayWithObject:]];
       MCOIMAPOperation * createOp = [session createFolderOperation:foobar];
       [createOp start:^(NSError * __nullable error) {
         ...
       }];
     }];
*/
- (MCOIMAPFetchNamespaceOperation *) fetchNamespaceOperation;

/**
 Returns an operation to send the client or get the server identity.

     MCOIMAPIdentity * identity = [MCOIMAPIdentity identityWithVendor:@"Mozilla" name:@"Thunderbird" version:@"17.0.5"];
     MCOIMAPIdentityOperation * op = [session identityOperationWithClientIdentity:identity];
     [op start:^(NSError * __nullable error, NSDictionary * serverIdentity) {
          ...
     }];
*/
- (MCOIMAPIdentityOperation *) identityOperationWithClientIdentity:(MCOIMAPIdentity *)identity;

/**
 Returns an operation that will connect to the given IMAP server without authenticating.
 Useful for checking initial server capabilities.

 MCOIMAPOperation * op = [session connectOperation];
 [op start:^(NSError * __nullable error) {
 ...
 }];
 */
- (MCOIMAPOperation *)connectOperation;

/**
 Returns an operation that will perform a No-Op operation on the given IMAP server.

 MCOIMAPOperation * op = [session noopOperation];
 [op start:^(NSError * __nullable error) {
 ...
 }];
 */
- (MCOIMAPOperation *) noopOperation;

/**
 Returns an operation that will check whether the IMAP account is valid.

     MCOIMAPOperation * op = [session checkAccountOperation];
     [op start:^(NSError * __nullable error) {
          ...
     }];
*/

- (MCOIMAPOperation *) checkAccountOperation;

/**
 Returns an operation to request capabilities of the server.
 See MCOIMAPCapability for the list of capabilities.

     canIdle = NO;
     MCOIMAPCapabilityOperation * op = [session capabilityOperation];
     [op start:^(NSError * __nullable error, MCOIndexSet * capabilities) {
       if ([capabilities containsIndex:MCOIMAPCapabilityIdle]) {
         canIdle = YES;
       }
     }];
*/
- (MCOIMAPCapabilityOperation *) capabilityOperation;

- (MCOIMAPQuotaOperation *) quotaOperation;

/** @name Search Operations */

/**
 Returns an operation to search for messages with a simple match.

     MCOIMAPSearchOperation * op = [session searchOperationWithFolder:@"INBOX"
                                                                 kind:MCOIMAPSearchKindFrom
                                                         searchString:@"laura"];
     [op start:^(NSError * __nullable error, MCOIndexSet * searchResult) {
          ...
     }];
*/
- (MCOIMAPSearchOperation *) searchOperationWithFolder:(NSString *)folder
                                                  kind:(MCOIMAPSearchKind)kind
                                          searchString:(NSString *)searchString;

/**
 Returns an operation to search for messages.

     MCOIMAPSearchExpression * expr = [MCOIMAPSearchExpression searchFrom:@"laura@etpan.org"]
     MCOIMAPSearchOperation * op = [session searchExpressionOperationWithFolder:@"INBOX"
                                                                     expression:expr];
     [op start:^(NSError * __nullable error, MCOIndexSet * searchResult) {
          ...
     }];
*/
- (MCOIMAPSearchOperation *) searchExpressionOperationWithFolder:(NSString *)folder
                                                      expression:(MCOIMAPSearchExpression *)expression;

/** @name Rendering Operations */

/**
 Returns an operation to render the HTML version of a message to be displayed in a web view.

    MCOIMAPMessageRenderingOperation * op = [session htmlRenderingOperationWithMessage:msg
                                                                            folder:@"INBOX"];

    [op start:^(NSString * htmlString, NSError * error) {
        ...
    }];
*/
- (MCOIMAPMessageRenderingOperation *) htmlRenderingOperationWithMessage:(MCOIMAPMessage *)message
                                                                  folder:(NSString *)folder;

/**
 Returns an operation to render the HTML body of a message to be displayed in a web view.

    MCOIMAPMessageRenderingOperation * op = [session htmlBodyRenderingOperationWithMessage:msg
                                                                                    folder:@"INBOX"];

    [op start:^(NSString * htmlString, NSError * error) {
        ...
    }];
 */
- (MCOIMAPMessageRenderingOperation *) htmlBodyRenderingOperationWithMessage:(MCOIMAPMessage *)message
                                                                      folder:(NSString *)folder;

/**
 Returns an operation to render the plain text version of a message.

    MCOIMAPMessageRenderingOperation * op = [session plainTextRenderingOperationWithMessage:msg
                                                                                     folder:@"INBOX"];

    [op start:^(NSString * htmlString, NSError * error) {
        ...
    }];
 */
- (MCOIMAPMessageRenderingOperation *) plainTextRenderingOperationWithMessage:(MCOIMAPMessage *)message
                                                                       folder:(NSString *)folder;

/**
 Returns an operation to render the plain text body of a message.
 All end of line will be removed and white spaces cleaned up if requested.
 This method can be used to generate the summary of the message.

    MCOIMAPMessageRenderingOperation * op = [session plainTextBodyRenderingOperationWithMessage:msg
                                                                                         folder:@"INBOX"
                                                                                stripWhitespace:YES];

    [op start:^(NSString * htmlString, NSError * error) {
        ...
    }];
 */
- (MCOIMAPMessageRenderingOperation *) plainTextBodyRenderingOperationWithMessage:(MCOIMAPMessage *)message
                                                                           folder:(NSString *)folder
                                                                  stripWhitespace:(BOOL)stripWhitespace;

/**
 Returns an operation to render the plain text body of a message.
 All end of line will be removed and white spaces cleaned up.
 This method can be used to generate the summary of the message.

 MCOIMAPMessageRenderingOperation * op = [session plainTextBodyRenderingOperationWithMessage:msg
 folder:@"INBOX"];

 [op start:^(NSString * htmlString, NSError * error) {
 ...
 }];
 */
- (MCOIMAPMessageRenderingOperation *) plainTextBodyRenderingOperationWithMessage:(MCOIMAPMessage *)message
                                                                           folder:(NSString *)folder;

/**
 Returns an operation to disconnect the session.
 It will disconnect all the sockets created by the session.

    MCOIMAPOperation * op = [session disconnectOperation];
    [op start:^(NSError * __nullable error) {
       ...
    }];
 */
- (MCOIMAPOperation *) disconnectOperation;

@end

#endif
