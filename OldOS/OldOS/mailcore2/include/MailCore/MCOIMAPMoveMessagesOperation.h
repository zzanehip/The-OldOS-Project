//
//  MCOIMAPMoveMessagesOperation.h
//  mailcore2
//
//  Created by Nikolay Morev on 02/02/16.
//  Copyright © 2016 MailCore. All rights reserved.
//

#import <MailCore/MCOIMAPBaseOperation.h>

#ifndef MAILCORE_MCOMOVEMESSAGESOPERATION_H

#define MAILCORE_MCOMOVEMESSAGESOPERATION_H

/** Implements an operation for moving messages between folders */

@class MCOIndexSet;

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPMoveMessagesOperation : MCOIMAPBaseOperation

/**
 Starts the asynchronous move operation.

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
