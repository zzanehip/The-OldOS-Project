//
//  MCOIMAPMoveMessagesOperation.m
//  mailcore2
//
//  Created by Nikolay Morev on 02/02/16.
//  Copyright © 2016 MailCore. All rights reserved.
//

#import "MCOIMAPMoveMessagesOperation.h"

#include "MCAsyncIMAP.h"

#import "MCOOperation+Private.h"
#import "MCOUtils.h"
#import "MCOIndexSet.h"

typedef void (^CompletionType)(NSError *error, MCOIndexSet * destUids);

@implementation MCOIMAPMoveMessagesOperation {
    CompletionType _completionBlock;
}

#define nativeType mailcore::IMAPMoveMessagesOperation

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

- (void) start:(void (^)(NSError *error, NSDictionary * uidMapping))completionBlock
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
        _completionBlock(nil, MCO_TO_OBJC(op->uidMapping()));
    }
    else {
        _completionBlock([NSError mco_errorWithErrorCode:op->error()], 0);
    }
    [_completionBlock release];
    _completionBlock = nil;
}

@end
