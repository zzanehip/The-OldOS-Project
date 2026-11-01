//
//  MCONNTPFetchOverviewOperation.m
//  mailcore2
//
//  Created by Robert Widmann on 10/21/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import "MCONNTPFetchOverviewOperation.h"

#include "MCAsyncNNTP.h"

#import "MCOUtils.h"
#import "MCOOperation+Private.h"
#import "MCOMessageHeader.h"

typedef void (^CompletionType)(NSError *error, NSArray<MCOMessageHeader *> * groups);

@implementation MCONNTPFetchOverviewOperation {
    CompletionType _completionBlock;
}

#define nativeType mailcore::NNTPFetchOverviewOperation

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

- (void) start:(void (^)(NSError *error, NSArray<MCOMessageHeader *> * groups))completionBlock
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
        _completionBlock(nil, MCO_TO_OBJC(op->articles()));
    } else {
        _completionBlock([NSError mco_errorWithErrorCode:op->error()], nil);
    }
    [_completionBlock release];
    _completionBlock = nil;
}

@end
