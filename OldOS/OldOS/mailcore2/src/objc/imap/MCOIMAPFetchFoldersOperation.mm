//
//  MCOIMAPFetchFoldersOperation.m
//  mailcore2
//
//  Created by Matt Ronge on 1/31/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPFetchFoldersOperation.h"

#import "NSError+MCO.h"
#import "MCOOperation+Private.h"

#import "MCOUtils.h"

#import <Foundation/Foundation.h>
#import <MailCore/MCAsync.h>

using namespace mailcore;

typedef void (^CompletionType)(NSError *error, NSArray<MCOIMAPFolder *> *folder);

@implementation MCOIMAPFetchFoldersOperation {
    CompletionType _completionBlock;
}

#define nativeType mailcore::IMAPFetchFoldersOperation

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

- (void) start:(void (^)(NSError *error, NSArray<MCOIMAPFolder *> *folders))completionBlock
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
    
    nativeType *op = MCO_NATIVE_INSTANCE;
    if (op->error() == ErrorNone) {
        _completionBlock(nil, MCO_TO_OBJC(op->folders()));
    }
    else {
        _completionBlock([NSError mco_errorWithErrorCode:op->error()], nil);
    }
    [_completionBlock release];
    _completionBlock = nil;
}

@end
