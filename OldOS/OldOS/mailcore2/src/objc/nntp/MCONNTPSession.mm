//
//  MCONNTPSession.m
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import "MCONNTPSession.h"

#include "MCAsyncNNTP.h"

#import "MCOUtils.h"
#import "MCONNTPOperation.h"
#import "MCOOperation+Private.h"
#import "MCONNTPFetchAllArticlesOperation.h"
#import "MCONNTPPostOperation.h"
#import "MCONNTPOperation+Private.h"
#include "MCOperationQueueCallback.h"

using namespace mailcore;

@interface MCONNTPSession ()

- (void) _logWithSender:(void *)sender connectionType:(MCOConnectionLogType)logType data:(NSData *)data;
- (void) _queueRunningChanged;

@end

class MCONNTPCallbackBridge : public Object, public ConnectionLogger, public OperationQueueCallback {
public:
    MCONNTPCallbackBridge(MCONNTPSession * session)
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
    MCONNTPSession * mSession;
};

@implementation MCONNTPSession {
    mailcore::NNTPAsyncSession * _session;
    MCOConnectionLogger _connectionLogger;
    MCONNTPCallbackBridge * _callbackBridge;
    MCOOperationQueueRunningChangeBlock _operationQueueRunningChangeBlock;
}

#define nativeType mailcore::NNTPAsyncSession

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
    
    _session = new mailcore::NNTPAsyncSession();
    _callbackBridge = new MCONNTPCallbackBridge(self);
    
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

- (id) _objcOperationFromNativeOp:(mailcore::NNTPOperation *)op
{
    MCONNTPOperation * result = MCO_TO_OBJC(op);
    [result setSession:self];
    return result;
}

- (id) _objcOpaqueOperationFromNativeOp:(mailcore::NNTPOperation *)op
{
    MCONNTPOperation * result = [[[MCONNTPOperation alloc] initWithMCOperation:op] autorelease];
    [result setSession:self];
    return result;
}

- (MCONNTPFetchAllArticlesOperation *) fetchAllArticlesOperation:(NSString *)group
{
    mailcore::NNTPFetchAllArticlesOperation * coreOp = MCO_NATIVE_INSTANCE->fetchAllArticlesOperation(MCO_FROM_OBJC(mailcore::String, group));
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCONNTPFetchHeaderOperation *) fetchHeaderOperationWithIndex:(unsigned int)index inGroup:(NSString *)group
{
    mailcore::NNTPFetchHeaderOperation * coreOp = MCO_NATIVE_INSTANCE->fetchHeaderOperation(MCO_FROM_OBJC(mailcore::String, group), index);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCONNTPFetchArticleOperation *) fetchArticleOperationWithIndex:(unsigned int)index inGroup:(NSString *)group
{
    mailcore::NNTPFetchArticleOperation * coreOp = MCO_NATIVE_INSTANCE->fetchArticleOperation(MCO_FROM_OBJC(mailcore::String, group), index);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCONNTPFetchArticleOperation *) fetchArticleOperationWithMessageID:(NSString *)messageID {
    mailcore::NNTPFetchArticleOperation * coreOp = MCO_NATIVE_INSTANCE->fetchArticleByMessageIDOperation(MCO_FROM_OBJC(mailcore::String, messageID));
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCONNTPFetchArticleOperation *) fetchArticleOperationWithMessageID:(NSString *)messageID inGroup:(NSString * __nullable)group {
    return [self fetchArticleOperationWithMessageID:messageID];
}

- (MCONNTPFetchOverviewOperation *)fetchOverviewOperationWithIndexes:(MCOIndexSet *)indexes inGroup:(NSString *)group {
    mailcore::NNTPFetchOverviewOperation * coreOp = MCO_NATIVE_INSTANCE->fetchOverviewOperationWithIndexes(MCO_FROM_OBJC(mailcore::String, group), MCO_FROM_OBJC(mailcore::IndexSet, indexes));
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCONNTPFetchServerTimeOperation *) fetchServerDateOperation {
    mailcore::NNTPFetchServerTimeOperation * coreOp = MCO_NATIVE_INSTANCE->fetchServerDateOperation();
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCONNTPListNewsgroupsOperation *) listAllNewsgroupsOperation {
    mailcore::NNTPListNewsgroupsOperation * coreOp = MCO_NATIVE_INSTANCE->listAllNewsgroupsOperation();
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCONNTPListNewsgroupsOperation *) listDefaultNewsgroupsOperation {
    mailcore::NNTPListNewsgroupsOperation * coreOp = MCO_NATIVE_INSTANCE->listDefaultNewsgroupsOperation();
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCONNTPPostOperation *) postOperationWithData:(NSData *)messageData {
    mailcore::NNTPPostOperation * coreOp = MCO_NATIVE_INSTANCE->postMessageOperation(MCO_FROM_OBJC(mailcore::Data, messageData));
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCONNTPPostOperation *) postOperationWithContentsOfFile:(NSString *)path
{
    mailcore::NNTPPostOperation * coreOp = MCO_NATIVE_INSTANCE->postMessageOperation(MCO_FROM_OBJC(mailcore::String, path));
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCONNTPOperation *) disconnectOperation
{
    mailcore::NNTPOperation * coreOp = MCO_NATIVE_INSTANCE->disconnectOperation();
    return OPAQUE_OPERATION(coreOp);
}

- (MCONNTPOperation *) checkAccountOperation
{
    mailcore::NNTPOperation * coreOp = MCO_NATIVE_INSTANCE->checkAccountOperation();
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
