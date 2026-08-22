//
//  MCOPOPFetchMessagesOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOPOPFETCHMESSAGESOPERATION_H

#define MAILCORE_MCOPOPFETCHMESSAGESOPERATION_H

#import <Foundation/Foundation.h>
#import <MailCore/MCOPOPOperation.h>

@class MCOPOPMessageInfo;

/** This is an asynchronous operation that will fetch the list of a messages on the POP3 account. */

NS_ASSUME_NONNULL_BEGIN
@interface MCOPOPFetchMessagesOperation : MCOPOPOperation

/** 
 Starts the asynchronous fetch operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `messages` will be an array of MCOPOPMessageInfo
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in MCOConstants.h, `messages` will be nil
*/
- (void) start:(void (^)(NSError * __nullable error, NSArray<MCOPOPMessageInfo *> * __nullable messages))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
