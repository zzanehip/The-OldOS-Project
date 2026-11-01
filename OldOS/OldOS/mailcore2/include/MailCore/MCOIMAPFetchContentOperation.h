//
//  MCOIMAPFetchContentOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPFETCHCONTENTOPERATION_H

#define MAILCORE_MCOIMAPFETCHCONTENTOPERATION_H

/** 
 This class implements an operation to fetch the content of a message.
 It can be a part or a full message.
*/

#import <MailCore/MCOIMAPBaseOperation.h>
#import <MailCore/MCOConstants.h>

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPFetchContentOperation : MCOIMAPBaseOperation

/** 
 This block will be called as bytes are received from the network
*/
@property (nonatomic, copy) MCOIMAPBaseOperationProgressBlock progress;

/** 
 Starts the asynchronous fetch operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `data` will contain the requested data
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in `MCOConstants.h`, `data` will be nil
*/

- (void) start:(void (^)(NSError * __nullable error, NSData * __nullable data))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
