//
//  MCOAccountValidator.m
//  mailcore2
//
//  Created by Christopher Hockley on 20/01/15.
//  Copyright (c) 2015 MailCore. All rights reserved.
//

#import "MCOAccountValidator.h"
#include "MCAccountValidator.h"
#include "MCNetService.h"

#import "MCOOperation+Private.h"
#import "MCOUtils.h"
#import "MCOperationCallback.h"
#import "MCONetService.h"

typedef void (^CompletionType)(void);

@interface MCOAccountValidator ()

- (void) _operationCompleted;
- (void) _logWithSender:(void *)sender connectionType:(MCOConnectionLogType)logType data:(NSData *)data;

@end

class MCOValidatorOperationCallback: public mailcore::Object, public mailcore::OperationCallback, public mailcore::ConnectionLogger {
public:
    MCOValidatorOperationCallback(MCOAccountValidator * op)
    {
        mOperation = op;
    }
    
    void operationFinished(mailcore::Operation * op)
    {
        [mOperation _operationCompleted];
    }
    
    virtual void log(void * sender, mailcore::ConnectionLogType logType, mailcore::Data * data)
    {
        [mOperation _logWithSender:sender connectionType:(MCOConnectionLogType)logType data:MCO_TO_OBJC(data)];
    }

private:
    MCOAccountValidator * mOperation;
};

@implementation MCOAccountValidator{
    CompletionType _completionBlock;
    mailcore::AccountValidator * _validator;
    MCOValidatorOperationCallback * _callback;
    MCOConnectionLogger _connectionLogger;
}

#define nativeType mailcore::AccountValidator

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

- (mailcore::Object *) mco_mcObject
{
    return _validator;
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::AccountValidator * validator = (mailcore::AccountValidator *) object;
    return [[[self alloc] initWithMCValidator:validator] autorelease];
}

MCO_OBJC_SYNTHESIZE_STRING(setEmail, email)
MCO_OBJC_SYNTHESIZE_STRING(setUsername, username)
MCO_OBJC_SYNTHESIZE_STRING(setPassword, password)
MCO_OBJC_SYNTHESIZE_STRING(setOAuth2Token, OAuth2Token)
MCO_OBJC_SYNTHESIZE_ARRAY(setImapServices, imapServices)
MCO_OBJC_SYNTHESIZE_ARRAY(setPopServices, popServices)
MCO_OBJC_SYNTHESIZE_ARRAY(setSmtpServices, smtpServices)
MCO_OBJC_SYNTHESIZE_BOOL(setImapEnabled, isImapEnabled)
MCO_OBJC_SYNTHESIZE_BOOL(setPopEnabled, isPopEnabled)
MCO_OBJC_SYNTHESIZE_BOOL(setSmtpEnabled, isSmtpEnabled)

- (instancetype) init
{
    mailcore::AccountValidator * validator = new mailcore::AccountValidator();
    self = [self initWithMCValidator:validator];
    validator->release();
    return self;
}

- (instancetype) initWithMCValidator:(mailcore::AccountValidator *)validator
{
    self = [super initWithMCOperation:validator];
    
    _validator = validator;
    _callback = new MCOValidatorOperationCallback(self);
    _validator->setCallback(_callback);
    _validator->retain();
    
    return self;
}

- (void) dealloc
{
    [_completionBlock release];
    MC_SAFE_RELEASE(_validator);
    MC_SAFE_RELEASE(_callback);
    [_connectionLogger release];
    [super dealloc];
}

- (void) start:(void (^)(void))completionBlock
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

- (void) _operationCompleted
{
    if (_completionBlock == NULL)
        return;
    
    _completionBlock();
    [_completionBlock release];
    _completionBlock = nil;
}

- (NSString *) identifier
{
    return MCO_OBJC_BRIDGE_GET(identifier);
}

- (MCONetService *) imapServer
{
    return MCO_OBJC_BRIDGE_GET(imapServer);
}

- (MCONetService *) popServer
{
    return MCO_OBJC_BRIDGE_GET(popServer);
}

- (MCONetService *) smtpServer
{
    return MCO_OBJC_BRIDGE_GET(smtpServer);
}

- (NSError *) imapError
{
    return [NSError mco_errorWithErrorCode:_validator->imapError()];
}

- (NSError *) popError
{
    return [NSError mco_errorWithErrorCode:_validator->popError()];
}

- (NSError *) smtpError
{
    return [NSError mco_errorWithErrorCode:_validator->smtpError()];
}

- (void) setConnectionLogger:(MCOConnectionLogger)connectionLogger
{
    [_connectionLogger release];
    _connectionLogger = [connectionLogger copy];

    if (_connectionLogger != nil) {
        _validator->setConnectionLogger(_callback);
    }
    else {
        _validator->setConnectionLogger(NULL);
    }
}

- (MCOConnectionLogger) connectionLogger
{
    return _connectionLogger;
}

- (void) _logWithSender:(void *)sender connectionType:(MCOConnectionLogType)logType data:(NSData *)data
{
    _connectionLogger(sender, logType, data);
}

@end
