//
//  MCOFetchHeaderOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOPOPFETCHHEADEROPERATION_H

#define MAILCORE_MCOPOPFETCHHEADEROPERATION_H

#import <Foundation/Foundation.h>
#import <MailCore/MCOPOPOperation.h>

/** 
 This is an asynchronous operation that will fetch the header of a message.
 @See MCOPOPSession
*/

@class MCOMessageHeader;

NS_ASSUME_NONNULL_BEGIN
@interface MCOPOPFetchHeaderOperation : MCOPOPOperation

/** 
 Starts the asynchronous fetch operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `header` will contain the message header
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in MCOConstants.h, `header` will be nil
*/
- (void) start:(void (^)(NSError * __nullable error, MCOMessageHeader * __nullable header))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
