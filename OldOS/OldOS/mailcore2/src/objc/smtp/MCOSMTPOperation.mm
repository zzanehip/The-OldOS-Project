//
//  MCOSMTPCheckAccountOperation.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOSMTPOperation.h"

#include "MCAsyncSMTP.h"

#import "MCOUtils.h"
#import "MCOOperation+Private.h"
#import "MCOSMTPSession.h"

typedef void (^CompletionType)(NSError *error);

@implementation MCOSMTPOperation {
    CompletionType _completionBlock;
    MCOSMTPSession * _session;
}

#define nativeType mailcore::SMTPOperation

- (void) dealloc
{
    [_session release];
    [_completionBlock release];
    [super dealloc];
}

- (void)start:(void (^)(NSError *error))completionBlock {
    _completionBlock = [completionBlock copy];
    [self start];
}

- (void)operationCompleted {
    if (_completionBlock == NULL)
        return;
    
    NSError * error = [self _errorFromNativeOperation];
    _completionBlock(error);
    [_completionBlock release];
    _completionBlock = NULL;
}

- (void) setSession:(MCOSMTPSession *)session
{
    [_session release];
    _session = [session retain];
}

- (MCOSMTPSession *) session
{
    return _session;
}

- (NSError *) _errorFromNativeOperation
{
    nativeType * op = MCO_NATIVE_INSTANCE;
    NSError * error = [NSError mco_errorWithErrorCode:op->error()];
    if (error != nil) {
        if (op->lastSMTPResponse() != NULL || op->lastSMTPResponseCode() != 0) {
            NSMutableDictionary * userInfo = [[error userInfo] mutableCopy];
            if (op->lastSMTPResponse() != NULL) {
                userInfo[MCOSMTPResponseKey] = MCO_TO_OBJC(op->lastSMTPResponse());
            }
            if (op->lastSMTPResponseCode() != 0) {
                userInfo[MCOSMTPResponseCodeKey] = @(op->lastSMTPResponseCode());
            }
            error = [NSError errorWithDomain:[error domain] code:[error code] userInfo:userInfo];
            [userInfo release];
        }
    }
    return error;
}

@end
