//
//  MCOIMAPMessageRenderingOperation.mm
//  mailcore2
//
//  Created by Paul Young on 07/07/2013.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPMessageRenderingOperation.h"

#include "MCAsyncIMAP.h"
#include "MCIMAPMessageRenderingOperation.h"

#import "MCOOperation+Private.h"
#import "MCOUtils.h"

typedef void (^CompletionType)(NSString * htmlString, NSError * error);

@implementation MCOIMAPMessageRenderingOperation {
    CompletionType _completionBlock;
}

#define nativeType mailcore::IMAPMessageRenderingOperation

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

- (void) start:(void (^)(NSString * htmlString, NSError * error))completionBlock
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
        _completionBlock([NSString mco_stringWithMCString:op->result()], nil);
    } else {
        _completionBlock(nil, [NSError mco_errorWithErrorCode:op->error()]);
    }
    [_completionBlock release];
    _completionBlock = nil;
}

@end
