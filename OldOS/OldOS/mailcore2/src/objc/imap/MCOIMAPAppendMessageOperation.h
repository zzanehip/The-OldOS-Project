//
//  MCOIMAPAppendMessageOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPAPPENDMESSAGEOPERATION_H

#define MAILCORE_MCOIMAPAPPENDMESSAGEOPERATION_H

/** This class implements an operation that adds a message to a folder. */

#import <MailCore/MCOIMAPBaseOperation.h>
#import <MailCore/MCOConstants.h>

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPAppendMessageOperation : MCOIMAPBaseOperation

@property (nonatomic, assign) time_t date;

/** 
 This block will be called as bytes are sent
*/
@property (nonatomic, copy) MCOIMAPBaseOperationProgressBlock progress;

/** 
 Starts the asynchronous append operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `createdUID` will be the value of the 
   UID of  the created message if the server supports UIDPLUS or zero if not.
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in MCOConstants.h, `createdUID` will be zero.
*/
- (void) start:(void (^)(NSError * __nullable error, uint32_t createdUID))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
