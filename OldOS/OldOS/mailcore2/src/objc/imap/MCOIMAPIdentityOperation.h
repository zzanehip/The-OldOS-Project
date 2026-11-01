//
//  MCOIMAPIdentityOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPIDENTITYOPERATION_H

#define MAILCORE_MCOIMAPIDENTITYOPERATION_H

/** 
 This class implements an operation to get the servers identification info or
 to send the clients identification info. Useful for bug reports and usage
 statistics. 
 @warn Not all servers support this.
*/

#import <MailCore/MCOIMAPBaseOperation.h>

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPIdentityOperation : MCOIMAPBaseOperation

/** 
 Starts the asynchronous identity operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `serverIdentity` will contain identifying server information.
   See [RFC2971](http://tools.ietf.org/html/rfc2971) for commons dictionary keys.
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in `MCOConstants.h`, `serverIdentity` will be nil
*/
- (void) start:(void (^)(NSError * __nullable error, NSDictionary * __nullable serverIdentity))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
