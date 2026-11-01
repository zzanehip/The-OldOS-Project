//
//  MCOIMAPFetchNamespaceOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPFETCHNAMESPACEOPERATION_H

#define MAILCORE_MCOIMAPFETCHNAMESPACEOPERATION_H

/** This class implements an operation to fetch any IMAP namespaces. */

#import <MailCore/MCOIMAPBaseOperation.h>

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPFetchNamespaceOperation : MCOIMAPBaseOperation

/** 
 Starts the asynchronous namespace fetch operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `namespaces` will contain these keys: 

     - `MCOIMAPNamespacePersonal` for personal namespaces,
     - `MCOIMAPNamespaceOther` for other namespaces,
     - `MCOIMAPNamespaceShared` for shared namespaces.

   Values of the dictionary are MCOIMAPNamespace
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in `MCOConstants.h`, `namespaces` will be nil
*/
- (void) start:(void (^)(NSError * __nullable error, NSDictionary * __nullable namespaces))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
