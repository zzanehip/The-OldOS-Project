//
//  MCOIMAPCapabilityOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPCAPABILITYOPERATION_H

#define MAILCORE_MCOIMAPCAPABILITYOPERATION_H

/** 
 This class implements an operation to query for IMAP capabilities, 
 like for example the extensions UIDPLUS, IDLE, NAMESPACE, ... etc
*/

#import <MailCore/MCOIMAPBaseOperation.h>

@class MCOIndexSet;

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPCapabilityOperation : MCOIMAPBaseOperation


/** 
 Starts the asynchronous capabilities operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `capabilities` will contain a set of IMAP capabilities.
   See `MCOConstants.h` under `MCOIMAPCapability` for a list of possible values.
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in MCOConstants.h, `capabilities` will be nil
*/
- (void) start:(void (^)(NSError * __nullable error, MCOIndexSet * __nullable capabilities))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
