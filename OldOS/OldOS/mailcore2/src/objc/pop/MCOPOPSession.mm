//
//  MCOPOPSession.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOPOPSession.h"

#include "MCAsyncPOP.h"

#import "MCOUtils.h"
#import "MCOPOPOperation.h"
#import "MCOOperation+Private.h"
#import "MCOPOPFetchMessagesOperation.h"
#import "MCOPOPOperation+Private.h"
#include "MCOperationQueueCallback.h"

using namespace mailcore;

@interface MCOPOPSession ()

- (void) _logWithSender:(void *)sender connectionType:(MCOConnectionLogType)logType data:(NSData *)data;
- (void) _queueRunningChanged;

@end

class MCOPOPCallbackBridge : public Object, public ConnectionLogger, public OperationQueueCallback {
public:
    MCOPOPCallbackBridge(MCOPOPSession * session)
    {
        mSession = session;
    }
    
    virtual void log(void * sender, ConnectionLogType logType, Data * data)
    {
        [mSession _logWithSender:sender connectionType:(MCOConnectionLogType)logType data:MCO_TO_OBJC(data)];
    }

    virtual void queueStartRunning()
    {
        [mSession _queueRunningChanged];
    }

    virtual void queueStoppedRunning()
    {
        [mSession _queueRunningChanged];
    }

private:
    MCOPOPSession * mSession;
};

@implementation MCOPOPSession {
    mailcore::POPAsyncSession * _session;
    MCOConnectionLogger _connectionLogger;
    MCOPOPCallbackBridge * _callbackBridge;
    MCOOperationQueueRunningChangeBlock _operationQueueRunningChangeBlock;
}

#define nativeType mailcore::POPAsyncSession

- (mailcore::Object *) mco_mcObject
{
    return _session;
}

- (NSString *) description
{
    return MCO_OBJC_BRIDGE_GET(description);
}

- (instancetype) init {
    self = [super init];
    
    _session = new mailcore::POPAsyncSession();
    _callbackBridge = new MCOPOPCallbackBridge(self);
    
    return self;
}

- (void)dealloc {
    MC_SAFE_RELEASE(_callbackBridge);
    [_connectionLogger release];
    _session->setConnectionLogger(NULL);
    _session->release();
    [super dealloc];
}

MCO_OBJC_SYNTHESIZE_STRING(setHostname, hostname)
MCO_OBJC_SYNTHESIZE_SCALAR(unsigned int, unsigned int, setPort, port)
MCO_OBJC_SYNTHESIZE_STRING(setUsername, username)
MCO_OBJC_SYNTHESIZE_STRING(setPassword, password)
MCO_OBJC_SYNTHESIZE_SCALAR(MCOAuthType, mailcore::AuthType, setAuthType, authType)
MCO_OBJC_SYNTHESIZE_SCALAR(MCOConnectionType, mailcore::ConnectionType, setConnectionType, connectionType)
MCO_OBJC_SYNTHESIZE_SCALAR(NSTimeInterval, time_t, setTimeout, timeout)
MCO_OBJC_SYNTHESIZE_BOOL(setCheckCertificateEnabled, isCheckCertificateEnabled)
MCO_OBJC_SYNTHESIZE_SCALAR(dispatch_queue_t, dispatch_queue_t, setDispatchQueue, dispatchQueue);

- (void) setConnectionLogger:(MCOConnectionLogger)connectionLogger
{
    [_connectionLogger release];
    _connectionLogger = [connectionLogger copy];
    
    if (_connectionLogger != nil) {
        _session->setConnectionLogger(_callbackBridge);
    }
    else {
        _session->setConnectionLogger(NULL);
    }
}

- (MCOConnectionLogger) connectionLogger
{
    return _connectionLogger;
}

- (void) setOperationQueueRunningChangeBlock:(MCOOperationQueueRunningChangeBlock)operationQueueRunningChangeBlock
{
    [_operationQueueRunningChangeBlock release];
    _operationQueueRunningChangeBlock = [operationQueueRunningChangeBlock copy];

    if (_operationQueueRunningChangeBlock != nil) {
        _session->setOperationQueueCallback(_callbackBridge);
    }
    else {
        _session->setOperationQueueCallback(NULL);
    }
}

- (MCOOperationQueueRunningChangeBlock) operationQueueRunningChangeBlock
{
    return _operationQueueRunningChangeBlock;
}

- (void) cancelAllOperations
{
    MCO_NATIVE_INSTANCE->cancelAllOperations();
}

#pragma mark - Operations


#define MCO_TO_OBJC_OP(op) [self _objcOperationFromNativeOp:op];
#define OPAQUE_OPERATION(op) [self _objcOpaqueOperationFromNativeOp:op]

- (id) _objcOperationFromNativeOp:(mailcore::POPOperation *)op
{
    MCOPOPOperation * result = MCO_TO_OBJC(op);
    [result setSession:self];
    return result;
}

- (id) _objcOpaqueOperationFromNativeOp:(mailcore::POPOperation *)op
{
    MCOPOPOperation * result = [[[MCOPOPOperation alloc] initWithMCOperation:op] autorelease];
    [result setSession:self];
    return result;
}

- (MCOPOPFetchMessagesOperation *) fetchMessagesOperation
{
    mailcore::POPFetchMessagesOperation * coreOp = MCO_NATIVE_INSTANCE->fetchMessagesOperation();
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOPOPFetchHeaderOperation *) fetchHeaderOperationWithIndex:(unsigned int)index
{
    mailcore::POPFetchHeaderOperation * coreOp = MCO_NATIVE_INSTANCE->fetchHeaderOperation(index);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOPOPFetchMessageOperation *) fetchMessageOperationWithIndex:(unsigned int)index;
{
    mailcore::POPFetchMessageOperation * coreOp = MCO_NATIVE_INSTANCE->fetchMessageOperation(index);
    return MCO_TO_OBJC_OP(coreOp);
}

// Will disconnect.
- (MCOPOPOperation *) deleteMessagesOperationWithIndexes:(MCOIndexSet *)indexes
{
    mailcore::POPOperation * coreOp = MCO_NATIVE_INSTANCE->deleteMessagesOperation(MCO_FROM_OBJC(mailcore::IndexSet, indexes));
    return OPAQUE_OPERATION(coreOp);
}

- (MCOPOPOperation *) disconnectOperation
{
    mailcore::POPOperation * coreOp = MCO_NATIVE_INSTANCE->disconnectOperation();
    return OPAQUE_OPERATION(coreOp);
}

- (MCOPOPOperation *) checkAccountOperation
{
    mailcore::POPOperation * coreOp = MCO_NATIVE_INSTANCE->checkAccountOperation();
    return OPAQUE_OPERATION(coreOp);
}

- (MCOPOPOperation *) noopOperation
{
    mailcore::POPOperation * coreOp = MCO_NATIVE_INSTANCE->noopOperation();
    return OPAQUE_OPERATION(coreOp);
}

- (void) _logWithSender:(void *)sender connectionType:(MCOConnectionLogType)logType data:(NSData *)data
{
    _connectionLogger(sender, logType, data);
}

- (void) _queueRunningChanged
{
    if (_operationQueueRunningChangeBlock == NULL)
        return;

    _operationQueueRunningChangeBlock();
}

- (BOOL) isOperationQueueRunning
{
    return _session->isOperationQueueRunning();
}

@end
