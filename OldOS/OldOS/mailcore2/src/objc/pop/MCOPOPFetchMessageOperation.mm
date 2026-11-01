//
//  MCOFetchMessageOperation.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOPOPFetchMessageOperation.h"

#import "MCAsyncPOP.h"

#import "MCOUtils.h"
#import "MCOOperation+Private.h"

#define nativeType mailcore::POPFetchMessageOperation

typedef void (^CompletionType)(NSError *error, NSData * messageData);

@interface MCOPOPFetchMessageOperation ()

- (void) bodyProgress:(unsigned int)current maximum:(unsigned int)maximum;

@end

class MCOPOPFetchMessageOperationCallback : public mailcore::POPOperationCallback {
public:
    MCOPOPFetchMessageOperationCallback(MCOPOPFetchMessageOperation * op)
    {
        mOperation = op;
    }
    virtual ~MCOPOPFetchMessageOperationCallback()
    {
    }
    
    virtual void bodyProgress(mailcore::POPOperation * session, unsigned int current, unsigned int maximum) {
        [mOperation bodyProgress:current maximum:maximum];
    }
    
private:
    MCOPOPFetchMessageOperation * mOperation;
};

@implementation MCOPOPFetchMessageOperation {
    CompletionType _completionBlock;
    MCOPOPFetchMessageOperationCallback * _popCallback;
    MCOPOPOperationProgressBlock _progress;
}

@synthesize progress = _progress;

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    nativeType * op = (nativeType *) object;
    return [[[self alloc] initWithMCOperation:op] autorelease];
}

- (instancetype) initWithMCOperation:(mailcore::Operation *)op
{
    self = [super initWithMCOperation:op];
    
    _popCallback = new MCOPOPFetchMessageOperationCallback(self);
    ((mailcore::POPOperation *) op)->setPopCallback(_popCallback);
    
    return self;
}

- (void) dealloc
{
    [_progress release];
    [_completionBlock release];
    delete _popCallback;
    [super dealloc];
}

- (void) start:(void (^)(NSError *error, NSData * messageData))completionBlock
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
        _completionBlock(nil, MCO_TO_OBJC(op->data()));
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
