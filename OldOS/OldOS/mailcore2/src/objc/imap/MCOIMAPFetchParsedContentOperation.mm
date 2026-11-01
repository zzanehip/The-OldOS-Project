//
//  MCOIMAPFetchParsedContentOperation.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPFetchParsedContentOperation.h"

#include "MCAsyncIMAP.h"

#import "MCOMessageParser.h"
#import "MCOOperation+Private.h"
#import "MCOUtils.h"

typedef void (^CompletionType)(NSError *error, MCOMessageParser * parser);

@implementation MCOIMAPFetchParsedContentOperation {
    CompletionType _completionBlock;
    MCOIMAPBaseOperationProgressBlock _progress;
}

@synthesize progress = _progress;

#define nativeType mailcore::IMAPFetchParsedContentOperation

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
    [_progress release];
    [_completionBlock release];
    [super dealloc];
}

- (void) start:(void (^)(NSError *error, MCOMessageParser * parser))completionBlock {
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
        if (op->parser()) {
            _completionBlock(nil, MCO_TO_OBJC(op->parser()));
        } else {
            _completionBlock(nil, nil);
        }
    } else {
        _completionBlock([NSError mco_errorWithErrorCode:op->error()], nil);
    }
    [_completionBlock release];
    _completionBlock = nil;
}

- (void) bodyProgress:(unsigned int)current maximum:(unsigned int)maximum
{
    if (_progress != NULL) {
        _progress(current, maximum);
    }
}

@end
