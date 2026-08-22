//
//  MCOIMAPOperation.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPOperation.h"

#include "MCIMAPOperation.h"
#import "MCOOperation+Private.h"

#import "MCOUtils.h"

typedef void (^CompletionType)(NSError *error);

@implementation MCOIMAPOperation {
    CompletionType _completionBlock;
}

#define nativeType mailcore::IMAPOperation

- (void) dealloc
{
    [_completionBlock release];
    [super dealloc];
}

- (void)start:(void (^)(NSError *error))completionBlock
{
    _completionBlock = [completionBlock copy];
    [self start];
}

- (void) cancel
{
    [_completionBlock release];
    _completionBlock = nil;
    [super cancel];
}

- (void) operationCompleted
{
    if (_completionBlock == NULL)
        return;
    
    NSError * error = [NSError mco_errorWithErrorCode:MCO_NATIVE_INSTANCE->error()];
    _completionBlock(error);
    [_completionBlock release];
    _completionBlock = nil;
}

@end
