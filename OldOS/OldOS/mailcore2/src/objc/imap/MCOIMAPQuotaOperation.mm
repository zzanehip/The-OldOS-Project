//
//  MCOIMAPQuotaOperation.m
//  mailcore2
//
//  Created by Petro Korenev on 8/2/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPQuotaOperation.h"

#include "MCAsyncIMAP.h"

#import "MCOOperation+Private.h"
#import "MCOUtils.h"

typedef void (^CompletionType)(NSError *error, NSUInteger usage, NSUInteger limit);

@implementation MCOIMAPQuotaOperation {
    CompletionType _completionBlock;
}

#define nativeType mailcore::IMAPQuotaOperation

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    nativeType * op = (nativeType *) object;
    return [[[self alloc] initWithMCOperation:op] autorelease];
}

- (void) dealloc
{
    [_completionBlock release];
    [super dealloc];
}

- (void) start:(void (^)(NSError *error, NSUInteger usage, NSUInteger limit))completionBlock
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
    
    nativeType *op = MCO_NATIVE_INSTANCE;
    if (op->error() == mailcore::ErrorNone) {
        _completionBlock(nil, op->usage(), op->limit());
    } else {
        _completionBlock([NSError mco_errorWithErrorCode:op->error()], 0, 0);
    }
    [_completionBlock release];
    _completionBlock = nil;
}

@end
