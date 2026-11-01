//
//  MCOIMAPFetchFoldersOperation.h
//  mailcore2
//
//  Created by Matt Ronge on 1/31/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPFETCHFOLDERSOPERATION_H

#define MAILCORE_MCOIMAPFETCHFOLDERSOPERATION_H

/** This class implements an operation to fetch a list of folders. */

#import <MailCore/MCOIMAPBaseOperation.h>

@class MCOIMAPFolder;

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPFetchFoldersOperation : MCOIMAPBaseOperation

/** 
 Starts the asynchronous fetch operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `folders` will contain an array of MCOIMAPFolder
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in `MCOConstants.h`, `folders` will be nil
*/
- (void) start:(void (^)(NSError * __nullable error, NSArray<MCOIMAPFolder *> * __nullable folders))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
