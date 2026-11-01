//
//  MCOSMTPLoginOperation.m
//  mailcore2
//
//  Created by Hironori Yoshida on 10/29/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import "MCOSMTPLoginOperation.h"

#include "MCSMTPLoginOperation.h"

#import "MCOUtils.h"
#import "MCOOperation+Private.h"
#import "MCOSMTPOperation+Private.h"

typedef void (^CompletionType)(NSError *error);

@implementation MCOSMTPLoginOperation {
    CompletionType _completionBlock;
}

#define nativeType mailcore::SMTPLoginOperation

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

- (void) start:(void (^)(NSError *error))completionBlock
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

- (void)operationCompleted
{
    if (_completionBlock == NULL)
        return;
    
    NSError * error = [self _errorFromNativeOperation];
    _completionBlock(error);
    [_completionBlock release];
    _completionBlock = NULL;
}


@end
