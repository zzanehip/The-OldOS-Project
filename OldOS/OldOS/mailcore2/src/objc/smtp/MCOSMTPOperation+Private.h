//
//  MCOSMTPOperation+Private.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 6/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOSMTPOPERATION_PRIVATE_H

#define MAILCORE_MCOSMTPOPERATION_PRIVATE_H

@class MCOSMTPSession;

@interface MCOSMTPOperation (Private)

@property (nonatomic, retain) MCOSMTPSession * session;

- (NSError *) _errorFromNativeOperation;

@end

#endif
