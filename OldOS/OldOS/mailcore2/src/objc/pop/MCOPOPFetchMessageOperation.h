//
//  MCOFetchMessageOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOPOPFETCHMESSAGEOPERATION_H

#define MAILCORE_MCOPOPFETCHMESSAGEOPERATION_H

#import <Foundation/Foundation.h>
#import <MailCore/MCOPOPOperation.h>

/** Fetch a message from POP3 */

typedef void (^MCOPOPOperationProgressBlock)(unsigned int current, unsigned int maximum);

NS_ASSUME_NONNULL_BEGIN
@interface MCOPOPFetchMessageOperation : MCOPOPOperation

/** This block will be called as data is downloaded from the network */
@property (nonatomic, copy) MCOPOPOperationProgressBlock progress;

/** 
 Starts the asynchronous fetch operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `data` will contain the message data
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in MCOConstants.h, `data` will be nil
*/
- (void) start:(void (^)(NSError * __nullable error, NSData * __nullable messageData))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
