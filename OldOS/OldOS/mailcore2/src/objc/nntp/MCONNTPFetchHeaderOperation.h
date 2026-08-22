//
//  MCONNTPFetchHeaderOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCONNTPFETCHHEADEROPERATION_H

#define MAILCORE_MCONNTPFETCHHEADEROPERATION_H

#import <Foundation/Foundation.h>
#import <MailCore/MCONNTPOperation.h>

/** 
 This is an asynchronous operation that will fetch the header of a message.
 @See MCONNTPSession
 */

@class MCOMessageHeader;

NS_ASSUME_NONNULL_BEGIN
@interface MCONNTPFetchHeaderOperation : MCONNTPOperation

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
