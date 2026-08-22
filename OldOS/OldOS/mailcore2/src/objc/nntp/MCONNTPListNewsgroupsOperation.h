//
//  MCONNTPListNewsgroupsOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCONNTPLISTNEWSGROUPSOPERATION_H

#define MAILCORE_MCONNTPLISTNEWSGROUPSOPERATION_H

#import <Foundation/Foundation.h>
#import <MailCore/MCONNTPOperation.h>

@class MCONNTPGroupInfo;

NS_ASSUME_NONNULL_BEGIN
@interface MCONNTPListNewsgroupsOperation : MCONNTPOperation

/** 
 Starts the asynchronous fetch operation.
 
 @param completionBlock Called when the operation is finished.
 
 - On success `error` will be nil and `messages` will be an array of MCONNTPGroupInfo
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
 error code available in MCOConstants.h, `messages` will be null
 */
- (void) start:(void (^)(NSError * __nullable error, NSArray<MCONNTPGroupInfo *> * __nullable messages))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
