//
//  MCOSMTPSession.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOSMTPSession.h"

#include "MCAsyncSMTP.h"

#import "MCOUtils.h"
#import "MCOSMTPLoginOperation.h"
#import "MCOSMTPSendOperation.h"
#import "MCOSMTPNoopOperation.h"
#import "MCOSMTPOperation.h"
#import "MCOOperation+Private.h"
#import "MCOAddress.h"
#import "MCOSMTPOperation+Private.h"
#include "MCOperationQueueCallback.h"

using namespace mailcore;

@interface MCOSMTPSession ()

- (void) _logWithSender:(void *)sender connectionType:(MCOConnectionLogType)logType data:(NSData *)data;
- (void) _queueRunningChanged;

@end

class MCOSMTPCallbackBridge : public Object, public ConnectionLogger, public OperationQueueCallback {
public:
    MCOSMTPCallbackBridge(MCOSMTPSession * session)
    {
        mSession = session;
    }
    
    virtual void log(void * sender, ConnectionLogType logType, Data * data)
    {
        @autoreleasepool {
            [mSession _logWithSender:sender connectionType:(MCOConnectionLogType)logType data:MCO_TO_OBJC(data)];
        }
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
    MCOSMTPSession * mSession;
};

@implementation MCOSMTPSession {
    mailcore::SMTPAsyncSession * _session;
    MCOConnectionLogger _connectionLogger;
    MCOSMTPCallbackBridge * _callbackBridge;
    MCOOperationQueueRunningChangeBlock _operationQueueRunningChangeBlock;
}

#define nativeType mailcore::SMTPAsyncSession

- (mailcore::Object *) mco_mcObject
{
    return _session;
}

- (instancetype) init {
    self = [super init];
    
    _session = new mailcore::SMTPAsyncSession();
    _callbackBridge = new MCOSMTPCallbackBridge(self);
    
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
MCO_OBJC_SYNTHESIZE_STRING(setOAuth2Token, OAuth2Token)
MCO_OBJC_SYNTHESIZE_SCALAR(MCOAuthType, mailcore::AuthType, setAuthType, authType)
MCO_OBJC_SYNTHESIZE_SCALAR(MCOConnectionType, mailcore::ConnectionType, setConnectionType, connectionType)
MCO_OBJC_SYNTHESIZE_SCALAR(NSTimeInterval, time_t, setTimeout, timeout)
MCO_OBJC_SYNTHESIZE_BOOL(setCheckCertificateEnabled, isCheckCertificateEnabled)
MCO_OBJC_SYNTHESIZE_BOOL(setUseHeloIPEnabled, useHeloIPEnabled)
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

- (MCOSMTPOperation *) loginOperation
{
    mailcore::SMTPOperation * coreOp = MCO_NATIVE_INSTANCE->loginOperation();
    MCOSMTPLoginOperation * result = [[[MCOSMTPLoginOperation alloc] initWithMCOperation:coreOp] autorelease];
    [result setSession:self];
    return result;
}

- (MCOSMTPSendOperation *) sendOperationWithData:(NSData *)messageData
{
    mailcore::SMTPOperation * coreOp = MCO_NATIVE_INSTANCE->sendMessageOperation([messageData mco_mcData]);
    MCOSMTPSendOperation * result = [[[MCOSMTPSendOperation alloc] initWithMCOperation:coreOp] autorelease];
    [result setSession:self];
    return result;
}

- (MCOSMTPSendOperation *) sendOperationWithData:(NSData *)messageData
                                            from:(MCOAddress *)from
                                      recipients:(NSArray<MCOAddress *> *)recipients
{
    mailcore::SMTPOperation * coreOp =
    MCO_NATIVE_INSTANCE->sendMessageOperation(MCO_FROM_OBJC(Address, from),
                                              MCO_FROM_OBJC(Array, recipients),
                                              [messageData mco_mcData]);
    MCOSMTPSendOperation * result = [[[MCOSMTPSendOperation alloc] initWithMCOperation:coreOp] autorelease];
    [result setSession:self];
    return result;
}

- (MCOSMTPSendOperation *) sendOperationWithContentsOfFile:(NSString *)path
                                                      from:(MCOAddress *)from
                                                recipients:(NSArray<MCOAddress *> *)recipients
{
    mailcore::SMTPOperation * coreOp =
    MCO_NATIVE_INSTANCE->sendMessageOperation(MCO_FROM_OBJC(Address, from),
                                              MCO_FROM_OBJC(Array, recipients),
                                              MCO_FROM_OBJC(String, path));
    MCOSMTPSendOperation * result = [[[MCOSMTPSendOperation alloc] initWithMCOperation:coreOp] autorelease];
    [result setSession:self];
    return result;
}

- (MCOSMTPOperation *) checkAccountOperationWithFrom:(MCOAddress *)from
{
    mailcore::SMTPOperation *coreOp = MCO_NATIVE_INSTANCE->checkAccountOperation(MCO_FROM_OBJC(mailcore::Address, from));
    MCOSMTPOperation * result = [[[MCOSMTPOperation alloc] initWithMCOperation:coreOp] autorelease];
    [result setSession:self];
    return result;
}

- (MCOSMTPOperation *) noopOperation
{
    mailcore::SMTPOperation * coreOp = MCO_NATIVE_INSTANCE->noopOperation();
    MCOSMTPNoopOperation * result = [[[MCOSMTPNoopOperation alloc] initWithMCOperation:coreOp] autorelease];
    [result setSession:self];
    return result;
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
