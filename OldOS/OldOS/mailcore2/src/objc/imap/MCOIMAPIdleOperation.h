//
//  MCOIMAPIdleOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPIDLEOPERATION_H

#define MAILCORE_MCOIMAPIDLEOPERATION_H

/** 
 This class implements an IMAP IDLE. IDLE is used to keep a connection
 open with the server so that new messages can be pushed to the client.
 See [RFC2177](http://tools.ietf.org/html/rfc2177)
*/

#import <MailCore/MCOIMAPBaseOperation.h>

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPIdleOperation : MCOIMAPBaseOperation

/** Stop the current IDLE session */
- (void) interruptIdle;

/** 
 Starts IDLE

 @param completionBlock Called when the IDLE times out, errors out or detects a change

 - On success `error` will be nil
 
 - On failure, `error` will be set with `MCOErrorDomain` as domain and an 
   error code available in `MCOConstants.h`
*/
- (void) start:(void (^)(NSError * __nullable error))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
