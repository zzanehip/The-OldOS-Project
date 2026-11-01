//
//  MCOIMAPFolderStatusOperation.mm
//  mailcore2
//
//  Created by Sebastian on 6/5/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPFolderStatusOperation.h"

#include "MCAsyncIMAP.h"

#import "MCOOperation+Private.h"
#import "MCOIMAPFolderStatus.h"
#import "MCOUtils.h"

typedef void (^CompletionType)(NSError *error, MCOIMAPFolderStatus *status);

@implementation MCOIMAPFolderStatusOperation {
    CompletionType _completionBlock;
}

#define nativeType mailcore::IMAPFolderStatusOperation

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

- (void) start:(void (^)(NSError * error, MCOIMAPFolderStatus * status))completionBlock
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
        MCOIMAPFolderStatus * status = MCO_TO_OBJC(op->status());
        _completionBlock(nil, status);
    } else {
        _completionBlock([NSError mco_errorWithErrorCode:op->error()], nil);
    }
    [_completionBlock release];
    _completionBlock = nil;
}

@end
