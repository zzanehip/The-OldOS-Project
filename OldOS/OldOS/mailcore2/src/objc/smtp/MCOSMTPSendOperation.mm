//
//  MCOSMTPSendOperation.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOSMTPSendOperation.h"

#include "MCAsyncSMTP.h"

#import "MCOUtils.h"
#import "MCOOperation+Private.h"
#import "MCOSMTPOperation+Private.h"

#define nativeType mailcore::SMTPOperation

typedef void (^CompletionType)(NSError *error);

@interface MCOSMTPSendOperation ()

- (void) bodyProgress:(unsigned int)current maximum:(unsigned int)maximum;

@end

class MCOSMTPSendOperationCallback : public mailcore::SMTPOperationCallback {
public:
    MCOSMTPSendOperationCallback(MCOSMTPSendOperation * op)
    {
        mOperation = op;
    }
    
    virtual ~MCOSMTPSendOperationCallback()
    {
    }
    
    virtual void bodyProgress(mailcore::SMTPOperation * session, unsigned int current, unsigned int maximum) {
        [mOperation bodyProgress:current maximum:maximum];
    }
    
private:
    MCOSMTPSendOperation * mOperation;
};

@implementation MCOSMTPSendOperation {
    CompletionType _completionBlock;
    MCOSMTPSendOperationCallback * _smtpCallback;
    MCOSMTPOperationProgressBlock _progress;
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
    
    _smtpCallback = new MCOSMTPSendOperationCallback(self);
    ((mailcore::SMTPOperation *) op)->setSmtpCallback(_smtpCallback);
    
    return self;
}

- (void) dealloc
{
    [_progress release];
    [_completionBlock release];
    delete _smtpCallback;
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

// This method needs to be duplicated from MCOSMTPOperation since _completionBlock
// references the instance of this subclass and not the one from MCOSMTPOperation.
- (void)operationCompleted
{
    if (_completionBlock == NULL)
        return;
    
    NSError * error = [self _errorFromNativeOperation];
    _completionBlock(error);
    [_completionBlock release];
    _completionBlock = NULL;
}

- (void) bodyProgress:(unsigned int)current maximum:(unsigned int)maximum
{
    if (_progress != NULL) {
        _progress(current, maximum);
    }
}

@end
