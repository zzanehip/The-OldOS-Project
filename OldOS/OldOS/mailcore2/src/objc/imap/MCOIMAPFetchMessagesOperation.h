//
//  MCOIMAPFetchMessagesOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPFETCHMESSAGESOPERATION_H

#define MAILCORE_MCOIMAPFETCHMESSAGESOPERATION_H

#import <MailCore/MCOIMAPBaseOperation.h>
#import <MailCore/MCOConstants.h>

/** This class implements an operation to fetch a list of messages from a folder */

@class MCOIMAPMessage;
@class MCOIndexSet;

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPFetchMessagesOperation : MCOIMAPBaseOperation

/** This block will be called each time a new message is downloaded. */
@property (nonatomic, copy) MCOIMAPBaseOperationItemProgressBlock progress;

/** Extra headers to request. Must set requestKind | IMAPMessagesRequestKindExtraHeaders */
@property (nonatomic, copy) NSArray * extraHeaders;

/** 
 Starts the asynchronous fetch operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `messages` will be an array of MCOIMAPMessage.
   `vanishedMessages` will contain the messages removed on the server if the server supports QRESYNC and if it was a sync request
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in `MCOConstants.h`, `messages` and `vanishedMessages` will be nil

   If you are not supporting QRESYNC you can safely ignore `vanishedMessages`.
*/
- (void) start:(void (^)(NSError * __nullable error, NSArray<MCOIMAPMessage *> * __nullable messages, MCOIndexSet * __nullable vanishedMessages))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
