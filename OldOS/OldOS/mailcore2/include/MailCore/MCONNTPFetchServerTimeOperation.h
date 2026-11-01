//
//  MCONNTPFetchServerTimeOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 10/21/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCONNTPFETCHSERVERTIMEOPERATION_H

#define MAILCORE_MCONNTPFETCHSERVERTIMEOPERATION_H

#import <Foundation/Foundation.h>
#import <MailCore/MCONNTPOperation.h>

@class MCOIndexSet;

NS_ASSUME_NONNULL_BEGIN
/** This is an asynchronous operation that will fetch the list of a messages on the NNTP server. */
@interface MCONNTPFetchServerTimeOperation : MCONNTPOperation

/** 
 Starts the asynchronous fetch operation.
 
 @param completionBlock Called when the operation is finished.
 
 - On success `error` will be nil and `date` will be the server's date and time as an NSDate.
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
 error code available in MCOConstants.h, `date` will be null
 */
- (void) start:(void (^)(NSError * __nullable error, NSDate * __nullable date))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
