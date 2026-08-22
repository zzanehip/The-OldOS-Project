//
//  MCONNTPOperation.m
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import "MCONNTPOperation.h"

#include "MCAsyncNNTP.h"

#import "MCOUtils.h"
#import "MCOOperation+Private.h"
#import "MCONNTPSession.h"

typedef void (^CompletionType)(NSError *error);

@implementation MCONNTPOperation {
    CompletionType _completionBlock;
    MCONNTPSession * _session;
}

#define nativeType mailcore::NNTPOperation

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

- (void) setSession:(MCONNTPSession *)session
{
    [_session release];
    _session = [session retain];
}

- (MCONNTPSession *) session
{
    return _session;
}

@end
