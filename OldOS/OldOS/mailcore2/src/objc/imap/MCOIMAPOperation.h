//
//  MCOIMAPOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPOPERATION_H

#define MAILCORE_MCOIMAPOPERATION_H

/** This class implements a generic IMAP operation */

#import <MailCore/MCOIMAPBaseOperation.h>


NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPOperation : MCOIMAPBaseOperation

/** 
 Starts the asynchronous append operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in MCOConstants.h,
*/
- (void) start:(void (^)(NSError * __nullable error))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
