//
//  MCOIMAPSearchOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOSEARCHOPERATION_H

#define MAILCORE_MCOSEARCHOPERATION_H

/** This class runs an IMAP search operation */

#import <MailCore/MCOIMAPBaseOperation.h>

@class MCOIndexSet;

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPSearchOperation : MCOIMAPBaseOperation

/** 
 Starts the asynchronous search operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `searchResults` will contain the UIDs of any matching messages
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in MCOConstants.h, `searchResult` will be nil
*/

- (void) start:(void (^)(NSError * __nullable error, MCOIndexSet * __nullable searchResult))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
