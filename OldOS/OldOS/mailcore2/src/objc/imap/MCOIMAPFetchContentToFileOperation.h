//
//  MCOIMAPFetchContentToFileOperation.h
//  mailcore2
//
//  Created by Dmitry Isaikin on 2/08/16.
//  Copyright (c) 2016 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPFETCHCONTENTTOFILEOPERATION_H

#define MAILCORE_MCOIMAPFETCHCONTENTTOFILEOPERATION_H

/** 
 This class implements an operation to fetch the content of a message to the file.
 It can be a part or a full message.
*/

#import <MailCore/MCOIMAPBaseOperation.h>
#import <MailCore/MCOConstants.h>

NS_ASSUME_NONNULL_BEGIN

@interface MCOIMAPFetchContentToFileOperation : MCOIMAPBaseOperation

/** 
 This block will be called as bytes are received from the network
*/
@property (nonatomic, copy, nullable) MCOIMAPBaseOperationProgressBlock progress;

@property (nonatomic, assign, getter=isLoadingByChunksEnabled) BOOL loadingByChunksEnabled;
@property (nonatomic, assign) uint32_t chunksSize;
@property (nonatomic, assign) uint32_t estimatedSize;

/** 
 Starts the asynchronous fetch operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in `MCOConstants.h`
*/

- (void) start:(void (^)(NSError * __nullable error))completionBlock;

@end

NS_ASSUME_NONNULL_END

#endif
