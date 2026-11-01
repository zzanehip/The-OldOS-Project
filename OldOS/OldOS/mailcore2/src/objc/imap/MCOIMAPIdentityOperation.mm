//
//  MCOIMAPIdentityOperation.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPIdentityOperation.h"

#include "MCAsyncIMAP.h"

#import "MCOOperation+Private.h"
#import "MCOUtils.h"

typedef void (^CompletionType)(NSError *error, NSDictionary * serverIdentity);

@implementation MCOIMAPIdentityOperation {
    CompletionType _completionBlock;
}

#define nativeType mailcore::IMAPIdentityOperation

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

- (void) start:(void (^)(NSError *error, NSDictionary * serverIdentity))completionBlock
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
        _completionBlock(nil, MCO_TO_OBJC(op->serverIdentity()));
    } else {
        _completionBlock([NSError mco_errorWithErrorCode:op->error()], nil);
    }
    [_completionBlock release];
    _completionBlock = nil;
}

@end
