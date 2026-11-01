//
//  MCOIMAPFolderInfoOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPFOLDERINFOOPERATION_H

#define MAILCORE_MCOIMAPFOLDERINFOOPERATION_H

#import <MailCore/MCOIMAPBaseOperation.h>

/**
 The class is used to get folder metadata (like UIDVALIDITY, UIDNEXT, etc).
 @see MCOIMAPFolderInfo
*/

@class MCOIMAPFolderInfo;

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPFolderInfoOperation : MCOIMAPBaseOperation

/** 
 Starts the asynchronous operation.

 @param completionBlock Called when the operation is finished.

 - On success `error` will be nil and `info` will contain the folder metadata
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in `MCOConstants.h`, `info` will be nil
*/

- (void) start:(void (^)(NSError * __nullable error, MCOIMAPFolderInfo * __nullable info))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
