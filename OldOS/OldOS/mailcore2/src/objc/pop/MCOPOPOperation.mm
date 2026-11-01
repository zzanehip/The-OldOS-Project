//
//  MCODeleteMessagesOperation.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOPOPOperation.h"

#include "MCAsyncPOP.h"

#import "MCOUtils.h"
#import "MCOOperation+Private.h"
#import "MCOPOPSession.h"

typedef void (^CompletionType)(NSError *error);

@implementation MCOPOPOperation {
    CompletionType _completionBlock;
    MCOPOPSession * _session;
}

#define nativeType mailcore::POPOperation

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
    
    NSError * error = [NSError mco_errorWithErrorCode:MCO_NATIVE_INSTANCE->error()];
    _completionBlock(error);
    [_completionBlock release];
    _completionBlock = nil;
}

- (void) setSession:(MCOPOPSession *)session
{
    [_session release];
    _session = [session retain];
}

- (MCOPOPSession *) session
{
    return _session;
}

@end
