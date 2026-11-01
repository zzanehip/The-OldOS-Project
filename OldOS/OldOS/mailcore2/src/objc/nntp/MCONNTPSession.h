//
//  MCONNTPSession.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCONNTPSESSION_H

#define MAILCORE_MCONNTPSESSION_H

#import <Foundation/Foundation.h>

#import <MailCore/MCOConstants.h>

@class MCONNTPFetchAllArticlesOperation;
@class MCONNTPFetchHeaderOperation;
@class MCONNTPFetchArticleOperation;
@class MCONNTPListNewsgroupsOperation;
@class MCONNTPFetchOverviewOperation;
@class MCONNTPFetchServerTimeOperation;
@class MCONNTPPostOperation;
@class MCONNTPOperation;
@class MCOIndexSet;

/** This class implements asynchronous access to the NNTP protocol.*/

NS_ASSUME_NONNULL_BEGIN
@interface MCONNTPSession : NSObject

/** This is the hostname of the NNTP server to connect to.*/
@property (nonatomic, copy) NSString * hostname;

/** This is the port of the NNTP server to connect to.*/
@property (nonatomic, assign) unsigned int port;

/** This is the username of the account.*/
@property (nonatomic, copy) NSString * username;

/** This is the password of the account.*/
@property (nonatomic, copy) NSString * password;

/** This is the encryption type to use.
 See MCOConnectionType for more information.*/
@property (nonatomic, assign) MCOConnectionType connectionType;

/** This is the timeout of the connection.*/
@property (nonatomic, assign) NSTimeInterval timeout;

/** When set to YES, the connection will fail if the certificate is incorrect.*/
@property (nonatomic, assign, getter=isCheckCertificateEnabled) BOOL checkCertificateEnabled;

/**
 Sets logger callback. The network traffic will be sent to this block.
 
 [session setConnectionLogger:^(void * connectionID, MCOConnectionLogType type, NSData * data) {
 ...
 }];
 */
@property (nonatomic, copy) MCOConnectionLogger connectionLogger;

/** This property provides some hints to MCONNTPSession about where it's called from.
 It will make MCONNTPSession safe. It will also set all the callbacks of operations to run on this given queue.
 Defaults to the main queue.
 This property should be used only if there's performance issue using MCONNTPSession in the main thread. */
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

/** @name Operations */

/**
 Returns an operation that will fetch the list of article numbers.
 
 MCONNTPFetchAllArticlesOperation * op = [session fetchAllArticlesOperation:@"comp.lang.c"];
 [op start:^(NSError * __nullable error, MCOIndexSet * articles) {
 }];
 */
- (MCONNTPFetchAllArticlesOperation *) fetchAllArticlesOperation:(NSString *)group;

/**
 Returns an operation that will fetch the header of the given message.
 
 MCONNTPFetchHeaderOperation * op = [session fetchHeaderOperationWithIndex:idx inGroup:@"comp.lang.c"];
 [op start:^(NSError * __nullable error, MCOMessageHeader * header) {
 // header is the parsed header of the message.
 }];
 */
- (MCONNTPFetchHeaderOperation *) fetchHeaderOperationWithIndex:(unsigned int)index inGroup:(NSString *)group;

/**
 Returns an operation that will fetch an overview (headers) for a set of messages.
 
 MCONNTPFetchHeaderOperation * op = [session fetchOverviewOperationWithIndexes:indexes inGroup:@"comp.lang.c"];
 [op start:^(NSError * __nullable error, NSArray * headers) {
 // headers are the parsed headers of each part of the overview.
 }];
 */
- (MCONNTPFetchOverviewOperation *)fetchOverviewOperationWithIndexes:(MCOIndexSet *)indexes inGroup:(NSString *)group;

/**
 Returns an operation that will fetch the content of the given message.
 
 MCONNTPFetchArticleOperation * op = [session fetchArticleOperationWithIndex:idx inGroup:@"comp.lang.c"];
 [op start:^(NSError * __nullable error, NSData * messageData) {
 // messageData is the RFC 822 formatted message data.
 }];
 */
- (MCONNTPFetchArticleOperation *) fetchArticleOperationWithIndex:(unsigned int)index inGroup:(NSString *)group;

/**
 Returns an operation that will fetch the content of a message with the given messageID.
 
 MCONNTPFetchArticleOperation * op = [session fetchArticleOperationWithMessageID:@"<MessageID123@mail.google.com>"];
 [op start:^(NSError * __nullable error, NSData * messageData) {
 // messageData is the RFC 822 formatted message data.
 }];
 */
- (MCONNTPFetchArticleOperation *) fetchArticleOperationWithMessageID:(NSString *)messageID;

/**
 Obsolete. Use -fetchArticleOperationWithMessageID: instead.
 
 MCONNTPFetchArticleOperation * op = [session fetchArticleOperationWithMessageID:@"<MessageID123@mail.google.com>" inGroup:@"comp.lang.c"];
 [op start:^(NSError * __nullable error, NSData * messageData) {
 // messageData is the RFC 822 formatted message data.
 }];
 */
- (MCONNTPFetchArticleOperation *) fetchArticleOperationWithMessageID:(NSString *)messageID inGroup:(NSString * __nullable)group DEPRECATED_ATTRIBUTE;

/**
 Returns an operation that will fetch the server's date and time.
 
 MCONNTPFetchArticleOperation * op = [session fetchServerDateOperation];
 [op start:^(NSError * __nullable error, NSDate * serverDate) {
 }];
 */
- (MCONNTPFetchServerTimeOperation *) fetchServerDateOperation;

/**
 Returns an operation that will list all available newsgroups.
 
 MCONNTPListNewsgroupsOperation * op = [session listAllNewsgroupsOperation];
 [op start:^(NSError * __nullable error, NSArray * subscribedGroups) {
 }];
 */
- (MCONNTPListNewsgroupsOperation *) listAllNewsgroupsOperation;

/**
 Returns an operation that will list server-suggested default newsgroups.
 
 MCONNTPListNewsgroupsOperation * op = [session listDefaultNewsgroupsOperation];
 [op start:^(NSError * __nullable error, NSArray * defaultGroups) {
 }];
 */
- (MCONNTPListNewsgroupsOperation *) listDefaultNewsgroupsOperation;

/**
 Returns an operation that will post the given message through NNTP.
 It will use the newsgroups set in the message data.
 It will also filter out Bcc from the content of the message.
 
 Generate RFC 822 data using MCOMessageBuilder
 
      MCONNTPOperation * op = [session postOperationWithData:rfc822Data];
      [op start:^(NSError * __nullable error) {
           ...
      }];
 */
- (MCONNTPPostOperation *) postOperationWithData:(NSData *)messageData;

/**
 Returns an operation that will post the message from the given file through NNTP.
 It will use the newsgroups set in the message data.
 It will also filter out Bcc from the content of the message.
 
      MCONNTPOperation * op = [session postOperationWithContentsOfFile:rfc822DataFilename];
      [op start:^(NSError * __nullable error) {
           ...
      }];
 */
- (MCONNTPPostOperation *) postOperationWithContentsOfFile:(NSString *)path;

/**
 Returns an operation that will disconnect the session.
 
 MCONNTPOperation * op = [session disconnectOperation];
 [op start:^(NSError * __nullable error) {
 ...
 }];
 */
- (MCONNTPOperation *) disconnectOperation;

/**
 Returns an operation that will check whether the NNTP account is valid.
 
 MCONNTPOperation * op = [session checkAccountOperation];
 [op start:^(NSError * __nullable error) {
 ...
 }];
 */
- (MCONNTPOperation *) checkAccountOperation;

@end
NS_ASSUME_NONNULL_END

#endif
