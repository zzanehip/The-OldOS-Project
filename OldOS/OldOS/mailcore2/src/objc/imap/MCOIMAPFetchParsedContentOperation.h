//
//  MCOIMAPFetchParsedContentOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPFETCHPARSEDCONTENTOPERATION_H

#define MAILCORE_MCOIMAPFETCHPARSEDCONTENTOPERATION_H

/**
 This class implements an operation to fetch the parsed content of a message.
*/

#import <MailCore/MCOIMAPBaseOperation.h>
#import <MailCore/MCOConstants.h>

@class MCOMessageParser;

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPFetchParsedContentOperation : MCOIMAPBaseOperation

/**
 This block will be called as bytes are received from the network
*/
@property (nonatomic, copy) MCOIMAPBaseOperationProgressBlock progress;

/**
 Starts the asynchronous fetch operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `parser` will contain the requested message

 - On failure, `error` will be set with `MCOErrorDomain` as domain and an
   error code available in `MCOConstants.h`, `parser` will be nil
*/

- (void) start:(void (^)(NSError * __nullable error, MCOMessageParser * __nullable parser))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
