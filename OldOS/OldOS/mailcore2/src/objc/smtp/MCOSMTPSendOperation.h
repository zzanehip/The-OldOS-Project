//
//  MCOSMTPSendOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOSMTPSENDOPERATION_H

#define MAILCORE_MCOSMTPSENDOPERATION_H

#import <MailCore/MCOSMTPOperation.h>

/** This is an asynchronous operation that will send a message through SMTP. */

typedef void (^MCOSMTPOperationProgressBlock)(unsigned int current, unsigned int maximum);

NS_ASSUME_NONNULL_BEGIN
@interface MCOSMTPSendOperation : MCOSMTPOperation

/** This block will be called as the message is sent */
@property (nonatomic, copy) MCOSMTPOperationProgressBlock progress;

/* 
 Starts the asynchronous operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in MCOConstants.h,
*/
- (void) start:(void (^)(NSError * __nullable error))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
