//
//  MCOIMAPSession.m
//  mailcore2
//
//  Created by Matt Ronge on 1/31/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPSession.h"

#import "MCOOperation.h"
#import "MCOOperation+Private.h"
#import "MCOObjectWrapper.h"
#import "MCOIMAPOperation.h"
#import "MCOIMAPFetchFoldersOperation.h"
#import "MCOIMAPBaseOperation+Private.h"
#import "MCOIMAPMessageRenderingOperation.h"
#import "MCOIMAPIdentity.h"

#import "MCOUtils.h"

#import <MailCore/MCAsync.h>

#include "MCIMAPMessageRenderingOperation.h"
#include "MCOperationQueueCallback.h"

using namespace mailcore;

@interface MCOIMAPSession ()

- (void) _logWithSender:(void *)sender connectionType:(MCOConnectionLogType)logType data:(NSData *)data;
- (void) _queueRunningChanged;

@end

class MCOIMAPCallbackBridge : public Object, public ConnectionLogger, public OperationQueueCallback {
public:
    MCOIMAPCallbackBridge(MCOIMAPSession * session)
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
    MCOIMAPSession * mSession;
};

@implementation MCOIMAPSession {
    IMAPAsyncSession * _session;
    MCOConnectionLogger _connectionLogger;
    MCOIMAPCallbackBridge * _callbackBridge;
    MCOOperationQueueRunningChangeBlock _operationQueueRunningChangeBlock;
}

#define nativeType mailcore::IMAPAsyncSession

- (mailcore::Object *) mco_mcObject
{
    return _session;
}

- (instancetype) init {
    self = [super init];
    
    _session = new IMAPAsyncSession();
    _callbackBridge = new MCOIMAPCallbackBridge(self);
    _session->setOperationQueueCallback(_callbackBridge);
    
    return self;
}

- (void)dealloc {
    _session->setConnectionLogger(NULL);
    _session->setOperationQueueCallback(NULL);
    MC_SAFE_RELEASE(_callbackBridge);
    [_operationQueueRunningChangeBlock release];
    [_connectionLogger release];
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
MCO_OBJC_SYNTHESIZE_BOOL(setVoIPEnabled, isVoIPEnabled)
MCO_OBJC_SYNTHESIZE_SCALAR(BOOL, BOOL, setAllowsFolderConcurrentAccessEnabled, allowsFolderConcurrentAccessEnabled)
MCO_OBJC_SYNTHESIZE_SCALAR(unsigned int, unsigned int, setMaximumConnections, maximumConnections)
MCO_OBJC_SYNTHESIZE_SCALAR(dispatch_queue_t, dispatch_queue_t, setDispatchQueue, dispatchQueue);

- (void) setDefaultNamespace:(MCOIMAPNamespace *)defaultNamespace
{
    _session->setDefaultNamespace(MCO_FROM_OBJC(IMAPNamespace, defaultNamespace));
}

- (MCOIMAPNamespace *) defaultNamespace
{
    return MCO_TO_OBJC(_session->defaultNamespace());
}

- (MCOIMAPIdentity *) clientIdentity
{
    return MCO_OBJC_BRIDGE_GET(clientIdentity);
}

- (void) setClientIdentity:(MCOIMAPIdentity *)clientIdentity
{
    MCO_OBJC_BRIDGE_SET(setClientIdentity, IMAPIdentity, clientIdentity);
}

- (MCOIMAPIdentity *) serverIdentity
{
    return MCO_OBJC_BRIDGE_GET(serverIdentity);
}

- (NSString *) gmailUserDisplayName
{
    return MCO_TO_OBJC(_session->gmailUserDisplayName());
}

- (BOOL) isIdleEnabled
{
    return MCO_NATIVE_INSTANCE->isIdleEnabled();
}

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

- (id) _objcOperationFromNativeOp:(IMAPOperation *)op
{
    MCOIMAPBaseOperation * result = MCO_TO_OBJC(op);
    [result setSession:self];
    return result;
}

- (id) _objcOpaqueOperationFromNativeOp:(IMAPOperation *)op
{
    MCOIMAPOperation * result = [[[MCOIMAPOperation alloc] initWithMCOperation:op] autorelease];
    [result setSession:self];
    return result;
}

- (MCOIMAPFolderInfoOperation *) folderInfoOperation:(NSString *)folder
{
    IMAPFolderInfoOperation * coreOp = MCO_NATIVE_INSTANCE->folderInfoOperation([folder mco_mcString]);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFolderStatusOperation *) folderStatusOperation:(NSString *)folder
{
    IMAPFolderStatusOperation * coreOp = MCO_NATIVE_INSTANCE->folderStatusOperation([folder mco_mcString]);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFetchFoldersOperation *) fetchSubscribedFoldersOperation
{
    IMAPOperation *coreOp = MCO_NATIVE_INSTANCE->fetchSubscribedFoldersOperation();
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFetchFoldersOperation *)fetchAllFoldersOperation {
    IMAPOperation *coreOp = MCO_NATIVE_INSTANCE->fetchAllFoldersOperation();
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPOperation *) renameFolderOperation:(NSString *)folder otherName:(NSString *)otherName
{
    IMAPOperation *coreOp = MCO_NATIVE_INSTANCE->renameFolderOperation([folder mco_mcString], [otherName mco_mcString]);
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPOperation *) deleteFolderOperation:(NSString *)folder
{
    IMAPOperation *coreOp = MCO_NATIVE_INSTANCE->deleteFolderOperation([folder mco_mcString]);
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPOperation *) createFolderOperation:(NSString *)folder
{
    IMAPOperation *coreOp = MCO_NATIVE_INSTANCE->createFolderOperation([folder mco_mcString]);
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPOperation *) subscribeFolderOperation:(NSString *)folder
{
    IMAPOperation *coreOp = MCO_NATIVE_INSTANCE->subscribeFolderOperation([folder mco_mcString]);
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPOperation *) unsubscribeFolderOperation:(NSString *)folder
{
    IMAPOperation *coreOp = MCO_NATIVE_INSTANCE->unsubscribeFolderOperation([folder mco_mcString]);
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPAppendMessageOperation *)appendMessageOperationWithFolder:(NSString *)folder
                                                        messageData:(NSData *)messageData
                                                              flags:(MCOMessageFlag)flags
{
    return [self appendMessageOperationWithFolder:folder messageData:messageData flags:flags customFlags:NULL];
}

- (MCOIMAPAppendMessageOperation *)appendMessageOperationWithFolder:(NSString *)folder
                                                        messageData:(NSData *)messageData
                                                              flags:(MCOMessageFlag)flags
                                                        customFlags:(NSArray<NSString *> *)customFlags
{
    IMAPAppendMessageOperation * coreOp = MCO_NATIVE_INSTANCE->appendMessageOperation([folder mco_mcString],
                                                                                      [messageData mco_mcData],
                                                                                      (MessageFlag) flags,
                                                                                      MCO_FROM_OBJC(Array, customFlags));
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPAppendMessageOperation *)appendMessageOperationWithFolder:(NSString *)folder
                                                     contentsAtPath:(NSString *)path
                                                              flags:(MCOMessageFlag)flags
                                                        customFlags:(NSArray<NSString *> *)customFlags
{
    IMAPAppendMessageOperation * coreOp = MCO_NATIVE_INSTANCE->appendMessageOperation([folder mco_mcString],
                                                                                      MCO_FROM_OBJC(String, path),
                                                                                      (MessageFlag) flags,
                                                                                      MCO_FROM_OBJC(Array, customFlags));
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPCopyMessagesOperation *)copyMessagesOperationWithFolder:(NSString *)folder
                                                             uids:(MCOIndexSet *)uids
                                                       destFolder:(NSString *)destFolder
{
    IMAPCopyMessagesOperation * coreOp = MCO_NATIVE_INSTANCE->copyMessagesOperation([folder mco_mcString],
                                                                                    MCO_FROM_OBJC(IndexSet, uids),
                                                                                    [destFolder mco_mcString]);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPMoveMessagesOperation *)moveMessagesOperationWithFolder:(NSString *)folder
                                                             uids:(MCOIndexSet *)uids
                                                       destFolder:(NSString *)destFolder
{
    IMAPMoveMessagesOperation * coreOp = MCO_NATIVE_INSTANCE->moveMessagesOperation([folder mco_mcString],
                                                                                    MCO_FROM_OBJC(IndexSet, uids),
                                                                                    [destFolder mco_mcString]);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPOperation *) expungeOperation:(NSString *)folder
{
    IMAPOperation *coreOp = MCO_NATIVE_INSTANCE->expungeOperation([folder mco_mcString]);
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPFetchMessagesOperation *) fetchMessagesByUIDOperationWithFolder:(NSString *)folder
                                                              requestKind:(MCOIMAPMessagesRequestKind)requestKind
                                                                     uids:(MCOIndexSet *)uids
{
    return [self fetchMessagesOperationWithFolder:folder requestKind:requestKind uids:uids];
}

- (MCOIMAPFetchMessagesOperation *) fetchMessagesOperationWithFolder:(NSString *)folder
                                                         requestKind:(MCOIMAPMessagesRequestKind)requestKind
                                                                uids:(MCOIndexSet *)uids
{
    IMAPFetchMessagesOperation * coreOp = MCO_NATIVE_INSTANCE->fetchMessagesByUIDOperation([folder mco_mcString],
                                                                                           (IMAPMessagesRequestKind) requestKind,
                                                                                           MCO_FROM_OBJC(IndexSet, uids));
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFetchMessagesOperation *) fetchMessagesByNumberOperationWithFolder:(NSString *)folder
                                                                 requestKind:(MCOIMAPMessagesRequestKind)requestKind
                                                                     numbers:(MCOIndexSet *)numbers
{
    IMAPFetchMessagesOperation * coreOp = MCO_NATIVE_INSTANCE->fetchMessagesByNumberOperation([folder mco_mcString],
                                                                                              (IMAPMessagesRequestKind) requestKind,
                                                                                              MCO_FROM_OBJC(IndexSet, numbers));
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFetchMessagesOperation *) syncMessagesByUIDWithFolder:(NSString *)folder
                                                    requestKind:(MCOIMAPMessagesRequestKind)requestKind
                                                           uids:(MCOIndexSet *)uids
                                                         modSeq:(uint64_t)modSeq
{
    return [self syncMessagesWithFolder:folder requestKind:requestKind uids:uids modSeq:modSeq];
}

- (MCOIMAPFetchMessagesOperation *) syncMessagesWithFolder:(NSString *)folder
                                               requestKind:(MCOIMAPMessagesRequestKind)requestKind
                                                      uids:(MCOIndexSet *)uids
                                                    modSeq:(uint64_t)modSeq
{
    IMAPFetchMessagesOperation * coreOp = MCO_NATIVE_INSTANCE->syncMessagesByUIDOperation([folder mco_mcString],
                                                                                          (IMAPMessagesRequestKind) requestKind,
                                                                                          MCO_FROM_OBJC(IndexSet, uids),
                                                                                          modSeq);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFetchContentOperation *) fetchMessageByUIDOperationWithFolder:(NSString *)folder
                                                                    uid:(uint32_t)uid
                                                                 urgent:(BOOL)urgent
{
    return [self fetchMessageOperationWithFolder:folder uid:uid urgent:urgent];
}

- (MCOIMAPFetchContentOperation *) fetchMessageByUIDOperationWithFolder:(NSString *)folder
                                                                    uid:(uint32_t)uid
{
    return [self fetchMessageOperationWithFolder:folder uid:uid];
}

- (MCOIMAPFetchContentOperation *) fetchMessageOperationWithFolder:(NSString *)folder
                                                               uid:(uint32_t)uid
                                                            urgent:(BOOL)urgent
{
    IMAPFetchContentOperation * coreOp = MCO_NATIVE_INSTANCE->fetchMessageByUIDOperation([folder mco_mcString], uid, urgent);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFetchContentOperation *) fetchMessageOperationWithFolder:(NSString *)folder
                                                               uid:(uint32_t)uid
{
    return [self fetchMessageOperationWithFolder:folder uid:uid urgent:NO];
}

- (MCOIMAPFetchContentOperation *) fetchMessageOperationWithFolder:(NSString *)folder
                                                            number:(uint32_t)number
                                                            urgent:(BOOL)urgent
{
    IMAPFetchContentOperation * coreOp = MCO_NATIVE_INSTANCE->fetchMessageByNumberOperation([folder mco_mcString], number, urgent);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFetchContentOperation *) fetchMessageOperationWithFolder:(NSString *)folder
                                                            number:(uint32_t)number
{
    return [self fetchMessageOperationWithFolder:folder number:number urgent:NO];
}

- (MCOIMAPFetchParsedContentOperation *) fetchParsedMessageOperationWithFolder:(NSString *)folder
                                                                           uid:(uint32_t)uid
                                                                        urgent:(BOOL)urgent
{
    IMAPFetchParsedContentOperation * coreOp = MCO_NATIVE_INSTANCE->fetchParsedMessageByUIDOperation([folder mco_mcString], uid, urgent);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFetchParsedContentOperation *) fetchParsedMessageOperationWithFolder:(NSString *)folder
                                                                           uid:(uint32_t)uid
{
    return [self fetchParsedMessageOperationWithFolder:folder uid:uid urgent:NO];
}

- (MCOIMAPFetchParsedContentOperation *) fetchParsedMessageOperationWithFolder:(NSString *)folder
                                                                        number:(uint32_t)number
                                                                        urgent:(BOOL)urgent
{
    IMAPFetchParsedContentOperation * coreOp = MCO_NATIVE_INSTANCE->fetchParsedMessageByNumberOperation([folder mco_mcString], number, urgent);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFetchParsedContentOperation *) fetchParsedMessageOperationWithFolder:(NSString *)folder
                                                                        number:(uint32_t)number
{
    return [self fetchParsedMessageOperationWithFolder:folder number:number urgent:NO];
}

- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentByUIDOperationWithFolder:(NSString *)folder
                                                                              uid:(uint32_t)uid
                                                                           partID:(NSString *)partID
                                                                         encoding:(MCOEncoding)encoding
                                                                           urgent:(BOOL)urgent
{
    return [self fetchMessageAttachmentOperationWithFolder:folder
                                                       uid:uid
                                                    partID:partID
                                                  encoding:encoding
                                                    urgent:urgent];
}

- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentByUIDOperationWithFolder:(NSString *)folder
                                                                              uid:(uint32_t)uid
                                                                           partID:(NSString *)partID
                                                                         encoding:(MCOEncoding)encoding
{
    return [self fetchMessageAttachmentOperationWithFolder:folder
                                                       uid:uid
                                                    partID:partID
                                                  encoding:encoding];
}

- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentOperationWithFolder:(NSString *)folder
                                                                         uid:(uint32_t)uid
                                                                      partID:(NSString *)partID
                                                                    encoding:(MCOEncoding)encoding
                                                                      urgent:(BOOL)urgent
{
    IMAPFetchContentOperation * coreOp = MCO_NATIVE_INSTANCE->fetchMessageAttachmentByUIDOperation([folder mco_mcString],
                                                                                                   uid,
                                                                                                   [partID mco_mcString],
                                                                                                   (Encoding) encoding,
                                                                                                   urgent);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPCustomCommandOperation *) customCommandOperation:(NSString *)command {
    IMAPCustomCommandOperation *customOp = MCO_NATIVE_INSTANCE->customCommand([command mco_mcString], false);
    return MCO_TO_OBJC_OP(customOp);
}

- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentOperationWithFolder:(NSString *)folder
                                                                         uid:(uint32_t)uid
                                                                      partID:(NSString *)partID
                                                                    encoding:(MCOEncoding)encoding
{
    return [self fetchMessageAttachmentOperationWithFolder:folder uid:uid partID:partID encoding:encoding urgent:NO];
}

- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentOperationWithFolder:(NSString *)folder
                                                                      number:(uint32_t)number
                                                                      partID:(NSString *)partID
                                                                    encoding:(MCOEncoding)encoding
                                                                      urgent:(BOOL)urgent
{
    IMAPFetchContentOperation * coreOp = MCO_NATIVE_INSTANCE->fetchMessageAttachmentByNumberOperation([folder mco_mcString],
                                                                                                      number,
                                                                                                      [partID mco_mcString],
                                                                                                      (Encoding) encoding,
                                                                                                      urgent);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFetchContentOperation *) fetchMessageAttachmentOperationWithFolder:(NSString *)folder
                                                                      number:(uint32_t)number
                                                                      partID:(NSString *)partID
                                                                    encoding:(MCOEncoding)encoding
{
    return [self fetchMessageAttachmentOperationWithFolder:folder number:number partID:partID encoding:encoding urgent:NO];
}

- (MCOIMAPFetchContentToFileOperation *) fetchMessageAttachmentToFileOperationWithFolder:(NSString *)folder
                                                                                     uid:(uint32_t)uid
                                                                                  partID:(NSString *)partID
                                                                                encoding:(MCOEncoding)encoding
                                                                                filename:(NSString *)filename
                                                                                  urgent:(BOOL)urgent
{
    IMAPFetchContentToFileOperation * coreOp = MCO_NATIVE_INSTANCE->fetchMessageAttachmentToFileByUIDOperation([folder mco_mcString],
                                                                                                               uid,
                                                                                                               [partID mco_mcString],
                                                                                                               (Encoding) encoding,
                                                                                                               [filename mco_mcString],
                                                                                                               urgent);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPOperation *) storeFlagsOperationWithFolder:(NSString *)folder
                                                uids:(MCOIndexSet *)uids
                                                kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               flags:(MCOMessageFlag)flags
{
    return [self storeFlagsOperationWithFolder:folder uids:uids kind:kind flags:flags customFlags:NULL];
}

- (MCOIMAPOperation *) storeFlagsOperationWithFolder:(NSString *)folder
                                                uids:(MCOIndexSet *)uids
                                                kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               flags:(MCOMessageFlag)flags
                                         customFlags:(NSArray<NSString *> *)customFlags
{
    IMAPOperation * coreOp = MCO_NATIVE_INSTANCE->storeFlagsByUIDOperation([folder mco_mcString],
                                                                           MCO_FROM_OBJC(IndexSet, uids),
                                                                           (IMAPStoreFlagsRequestKind) kind,
                                                                           (MessageFlag) flags,
                                                                           MCO_FROM_OBJC(Array, customFlags));
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPOperation *) storeFlagsOperationWithFolder:(NSString *)folder
                                             numbers:(MCOIndexSet *)numbers
                                                kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               flags:(MCOMessageFlag)flags
{
    return [self storeFlagsOperationWithFolder:folder numbers:numbers kind:kind flags:flags customFlags:NULL];
}

- (MCOIMAPOperation *) storeFlagsOperationWithFolder:(NSString *)folder
                                             numbers:(MCOIndexSet *)numbers
                                                kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               flags:(MCOMessageFlag)flags
                                         customFlags:(NSArray<NSString *> *)customFlags
{
    IMAPOperation * coreOp = MCO_NATIVE_INSTANCE->storeFlagsByNumberOperation([folder mco_mcString],
                                                                              MCO_FROM_OBJC(IndexSet, numbers),
                                                                              (IMAPStoreFlagsRequestKind) kind,
                                                                              (MessageFlag) flags,
                                                                              MCO_FROM_OBJC(Array, customFlags));
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPOperation *) storeLabelsOperationWithFolder:(NSString *)folder
                                                 uids:(MCOIndexSet *)uids
                                                 kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               labels:(NSArray<NSString *> *)labels
{
    IMAPOperation * coreOp = MCO_NATIVE_INSTANCE->storeLabelsByUIDOperation([folder mco_mcString],
                                                                            MCO_FROM_OBJC(IndexSet, uids),
                                                                            (IMAPStoreFlagsRequestKind) kind,
                                                                            MCO_FROM_OBJC(Array, labels));
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPOperation *) storeLabelsOperationWithFolder:(NSString *)folder
                                              numbers:(MCOIndexSet *)numbers
                                                 kind:(MCOIMAPStoreFlagsRequestKind)kind
                                               labels:(NSArray<NSString *> *)labels
{
    IMAPOperation * coreOp = MCO_NATIVE_INSTANCE->storeLabelsByNumberOperation([folder mco_mcString],
                                                                               MCO_FROM_OBJC(IndexSet, numbers),
                                                                               (IMAPStoreFlagsRequestKind) kind,
                                                                               MCO_FROM_OBJC(Array, labels));
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPSearchOperation *) searchOperationWithFolder:(NSString *)folder
                                                  kind:(MCOIMAPSearchKind)kind
                                          searchString:(NSString *)searchString
{
    IMAPSearchOperation * coreOp = MCO_NATIVE_INSTANCE->searchOperation([folder mco_mcString],
                                                                        (IMAPSearchKind) kind,
                                                                        [searchString mco_mcString]);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPSearchOperation *) searchExpressionOperationWithFolder:(NSString *)folder
                                                      expression:(MCOIMAPSearchExpression *)expression
{
    IMAPSearchOperation * coreOp = MCO_NATIVE_INSTANCE->searchOperation([folder mco_mcString],
                                                                        MCO_FROM_OBJC(IMAPSearchExpression, expression));
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPIdleOperation *) idleOperationWithFolder:(NSString *)folder
                                      lastKnownUID:(uint32_t)lastKnownUID
{
    IMAPIdleOperation * coreOp = MCO_NATIVE_INSTANCE->idleOperation([folder mco_mcString], lastKnownUID);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPFetchNamespaceOperation *) fetchNamespaceOperation
{
    IMAPFetchNamespaceOperation * coreOp = MCO_NATIVE_INSTANCE->fetchNamespaceOperation();
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPIdentityOperation *) identityOperationWithClientIdentity:(MCOIMAPIdentity *)identity
{
    IMAPIdentityOperation * coreOp = MCO_NATIVE_INSTANCE->identityOperation(MCO_FROM_OBJC(IMAPIdentity, identity));
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPOperation *)connectOperation
{
    IMAPOperation *coreOp = MCO_NATIVE_INSTANCE->connectOperation();
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPOperation *) noopOperation
{
    IMAPOperation *coreOp = MCO_NATIVE_INSTANCE->noopOperation();
    return OPAQUE_OPERATION(coreOp);
}

- (MCOIMAPOperation *)checkAccountOperation
{
    IMAPOperation *coreOp = MCO_NATIVE_INSTANCE->checkAccountOperation();
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPCapabilityOperation *) capabilityOperation
{
    IMAPCapabilityOperation * coreOp = MCO_NATIVE_INSTANCE->capabilityOperation();
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPQuotaOperation *) quotaOperation
{
    IMAPQuotaOperation * coreOp = MCO_NATIVE_INSTANCE->quotaOperation();
    return MCO_TO_OBJC_OP((IMAPOperation*)coreOp);
}

- (void) _logWithSender:(void *)sender connectionType:(MCOConnectionLogType)logType data:(NSData *)data
{
    _connectionLogger(sender, logType, data);
}

- (MCOIMAPMessageRenderingOperation *) htmlRenderingOperationWithMessage:(MCOIMAPMessage *)message
                                                                  folder:(NSString *)folder
{
    IMAPMessageRenderingOperation * coreOp = MCO_NATIVE_INSTANCE->htmlRenderingOperation(MCO_FROM_OBJC(IMAPMessage, message), [folder mco_mcString]);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPMessageRenderingOperation *) htmlBodyRenderingOperationWithMessage:(MCOIMAPMessage *)message
                                                                      folder:(NSString *)folder
{
    IMAPMessageRenderingOperation * coreOp = MCO_NATIVE_INSTANCE->htmlBodyRenderingOperation(MCO_FROM_OBJC(IMAPMessage, message), [folder mco_mcString]);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPMessageRenderingOperation *) plainTextRenderingOperationWithMessage:(MCOIMAPMessage *)message
                                                                       folder:(NSString *)folder
{
    IMAPMessageRenderingOperation * coreOp = MCO_NATIVE_INSTANCE->plainTextRenderingOperation(MCO_FROM_OBJC(IMAPMessage, message), [folder mco_mcString]);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPMessageRenderingOperation *) plainTextBodyRenderingOperationWithMessage:(MCOIMAPMessage *)message
                                                                           folder:(NSString *)folder
{
    return [self plainTextBodyRenderingOperationWithMessage:message folder:folder stripWhitespace:YES];
}

- (MCOIMAPMessageRenderingOperation *) plainTextBodyRenderingOperationWithMessage:(MCOIMAPMessage *)message
                                                                           folder:(NSString *)folder
                                                                  stripWhitespace:(BOOL)stripWhitespace
{
    IMAPMessageRenderingOperation * coreOp = MCO_NATIVE_INSTANCE->plainTextBodyRenderingOperation(MCO_FROM_OBJC(IMAPMessage, message), [folder mco_mcString], stripWhitespace);
    return MCO_TO_OBJC_OP(coreOp);
}

- (MCOIMAPOperation *) disconnectOperation
{
    IMAPOperation * coreOp = MCO_NATIVE_INSTANCE->disconnectOperation();
    return MCO_TO_OBJC_OP(coreOp);
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
