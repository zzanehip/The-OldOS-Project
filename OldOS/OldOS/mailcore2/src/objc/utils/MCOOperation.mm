//
//  MCOOperation.m
//  mailcore2
//
//  Created by Matt Ronge on 01/31/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "MCOOperation.h"
#import "MCOOperation+Private.h"

#import "MCOperation.h"
#import "MCOperationCallback.h"
#import "MCOObjectWrapper.h"
#import "MCOUtils.h"

#import <Foundation/Foundation.h>

using namespace mailcore;

@interface MCOOperation ()
- (void)_operationCompleted;
@end

class MCOOperationCompletionCallback : public Object, public OperationCallback {
public:
    MCOOperationCompletionCallback(MCOOperation *op) {
        mOperation = op;
    }

    virtual void operationFinished(Operation * op)
    {
        [mOperation _operationCompleted];
    }

    private:
        MCOOperation *mOperation;
};

@implementation MCOOperation {
    Operation * _operation;
    MCOOperationCompletionCallback * _callback;
    BOOL _started;
}

#define nativeType mailcore::Operation

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::Operation * op = (mailcore::Operation *) object;
    return [[[self alloc] initWithMCOperation:op] autorelease];
}

- (mailcore::Object *) mco_mcObject
{
    return _operation;
}

- (instancetype) initWithMCOperation:(Operation *)op
{
    self = [super init];
    
    _operation = op;
    _operation->retain();
    
    _callback = new MCOOperationCompletionCallback(self);
    _operation->setCallback(_callback);
    
    return self;
}

- (void) dealloc
{
    _operation->release();
    _callback->release();
    [super dealloc];
}

- (BOOL) isCancelled
{
    return MCO_NATIVE_INSTANCE->isCancelled();
}

MCO_OBJC_SYNTHESIZE_SCALAR(dispatch_queue_t, dispatch_queue_t, setCallbackDispatchQueue, callbackDispatchQueue);
MCO_OBJC_SYNTHESIZE_SCALAR(BOOL, bool, setShouldRunWhenCancelled, shouldRunWhenCancelled);

- (void) cancel
{
    if (_started) {
        _started = NO;
        [self release];
    }
    _operation->cancel();
}

- (void) start
{
    _started = YES;
    [self retain];
    _operation->start();
}

- (void) _operationCompleted
{
    _started = NO;
    [self operationCompleted];
    [self release];
}

- (void) operationCompleted
{
}

@end
