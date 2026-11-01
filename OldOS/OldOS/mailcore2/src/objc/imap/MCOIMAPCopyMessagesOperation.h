//
//  MCOIMAPCopyMessagesOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import <MailCore/MCOIMAPBaseOperation.h>

#ifndef MAILCORE_MCOCOPYMESSAGESOPERATION_H

#define MAILCORE_MCOCOPYMESSAGESOPERATION_H

/** Implements an operation for copying messages between folders */

@class MCOIndexSet;

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPCopyMessagesOperation : MCOIMAPBaseOperation

/** 
 Starts the asynchronous copy operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `destUids` will contain the UIDs of the messages created
   in the destination folder. If the server doesn't support UIDPLUS then `destUids` will be nil.
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in `MCOConstants.h`, `destUids` will be nil
*/

- (void) start:(void (^)(NSError * __nullable error, NSDictionary * __nullable uidMapping))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
