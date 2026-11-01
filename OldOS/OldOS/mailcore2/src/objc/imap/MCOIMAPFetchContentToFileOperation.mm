//
//  MCOIMAPFetchContentToFileOperation.mm
//  mailcore2
//
//  Created by Dmitry Isaikin on 2/08/16.
//  Copyright (c) 2016 MailCore. All rights reserved.
//

#import "MCOIMAPFetchContentToFileOperation.h"

#include "MCAsyncIMAP.h"

#import "MCOOperation+Private.h"
#import "MCOUtils.h"

typedef void (^CompletionType)(NSError *error);

@implementation MCOIMAPFetchContentToFileOperation {
    CompletionType _completionBlock;
    MCOIMAPBaseOperationProgressBlock _progress;
}

@synthesize progress = _progress;

#define nativeType mailcore::IMAPFetchContentToFileOperation

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    nativeType * op = (nativeType *) object;
    return [[[self alloc] initWithMCOperation:op] autorelease];
}

- (void)setLoadingByChunksEnabled:(BOOL)loadingByChunksEnabled {
    MCO_NATIVE_INSTANCE->setLoadingByChunksEnabled(loadingByChunksEnabled);
}

- (BOOL)isLoadingByChunksEnabled {
    return MCO_NATIVE_INSTANCE->isLoadingByChunksEnabled();
}

- (void)setChunksSize:(uint32_t)chunksSize {
    MCO_NATIVE_INSTANCE->setChunksSize(chunksSize);
}

- (uint32_t)chunksSize {
    return MCO_NATIVE_INSTANCE->chunksSize();
}

- (void)setEstimatedSize:(uint32_t)estimatedSize {
    MCO_NATIVE_INSTANCE->setEstimatedSize(estimatedSize);
}

- (uint32_t)estimatedSize {
    return MCO_NATIVE_INSTANCE->estimatedSize();
}

- (void) dealloc
{
    [_progress release];
    [_completionBlock release];
    [super dealloc];
}

- (void) start:(void (^)(NSError *error))completionBlock {
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
        _completionBlock(nil);
    } else {
        _completionBlock([NSError mco_errorWithErrorCode:op->error()]);
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
