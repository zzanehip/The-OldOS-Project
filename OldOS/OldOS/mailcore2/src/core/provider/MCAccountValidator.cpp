//
//  MCAccountValidator.cpp
//  mailcore2
//
//  Created by Christopher Hockley on 22/01/15.
//  Copyright (c) 2015 MailCore. All rights reserved.
//

#include "MCAccountValidator.h"
#include "MCMailProvider.h"
#include "MCMailProvidersManager.h"
#include "MCIMAPAsyncSession.h"
#include "MCPOPAsyncSession.h"
#include "MCSMTPAsyncSession.h"
#include "MCNetService.h"
#include "MCAddress.h"
#include "MCIMAPOperation.h"
#include "MCPOPOperation.h"
#include "MCSMTPOperation.h"
#include "MCMXRecordResolverOperation.h"
#include "MCIMAPCheckAccountOperation.h"

using namespace mailcore;

/* this is the service being tested */

enum {
    SERVICE_IMAP,  /* IMAP service */
    SERVICE_POP,   /* POP  service */
    SERVICE_SMTP,  /* SMTP service */
};

void AccountValidator::init()
{
    mEmail = NULL;
    mUsername = NULL;
    mPassword = NULL;
    mOAuth2Token = NULL;
    
    mImapServices = new Array();
    mSmtpServices = new Array();
    mPopServices = new Array();
    
    mIdentifier = NULL;
    mImapServer = NULL;
    mPopServer = NULL;
    mSmtpServer = NULL;
    mImapError = ErrorNone;
    mPopError = ErrorNone;
    mSmtpError = ErrorNone;
    mImapLoginResponse = NULL;
    
    mCurrentServiceIndex = 0;
    mCurrentServiceTested = 0;
    
    mProvider = NULL;
    
    mOperation = NULL;
    mQueue = NULL;
    mResolveMX = NULL;
    
    mImapSession = NULL;
    mPopSession = NULL;
    mSmtpSession = NULL;

    mImapEnabled = false;
    mPopEnabled = false;
    mSmtpEnabled = false;

    mConnectionLogger = NULL;
    pthread_mutex_init(&mConnectionLoggerLock, NULL);
}

AccountValidator::AccountValidator()
{
    init();
}

AccountValidator::~AccountValidator()
{
    pthread_mutex_destroy(&mConnectionLoggerLock);
    MC_SAFE_RELEASE(mImapLoginResponse);
    MC_SAFE_RELEASE(mEmail);
    MC_SAFE_RELEASE(mUsername);
    MC_SAFE_RELEASE(mPassword);
    MC_SAFE_RELEASE(mOAuth2Token);
    MC_SAFE_RELEASE(mImapServices);
    MC_SAFE_RELEASE(mSmtpServices);
    MC_SAFE_RELEASE(mPopServices);
    MC_SAFE_RELEASE(mIdentifier);
    MC_SAFE_RELEASE(mProvider);
    MC_SAFE_RELEASE(mOperation);
    MC_SAFE_RELEASE(mQueue);
    MC_SAFE_RELEASE(mResolveMX);
    MC_SAFE_RELEASE(mImapSession);
    MC_SAFE_RELEASE(mPopSession);
    MC_SAFE_RELEASE(mSmtpSession);
}

void AccountValidator::start()
{
    if (mEmail == NULL) {
        if (mUsername == NULL) {
            return;
        }
        else {
            mEmail = mUsername;
            MC_SAFE_RETAIN(mEmail);
        }
    }
    else if (mUsername == NULL){
        mUsername = mEmail;
        MC_SAFE_RETAIN(mUsername);
    }

    MC_SAFE_RELEASE(mProvider);
    mProvider = MailProvidersManager::sharedManager()->providerForEmail(mEmail);
    if (mProvider != NULL) {
        MC_SAFE_REPLACE_COPY(String, mIdentifier, mProvider->identifier());
    }
    MC_SAFE_RETAIN(mProvider);

    if (mProvider == NULL) {
        resolveMX();
    }
    else{
        startCheckingHosts();
    }
}

void AccountValidator::cancel()
{
    if(mOperation != NULL)
        mOperation->cancel();
    
    if(mResolveMX != NULL)
        mResolveMX->cancel();
    
    if (mQueue != NULL)
        mQueue->cancelAllOperations();
    
    cancelDelayedPerformMethod((Object::Method) &AccountValidator::resolveMXTimeout, NULL);

    MC_SAFE_RELEASE(mOperation);
    MC_SAFE_RELEASE(mResolveMX);
    MC_SAFE_RELEASE(mQueue);
    if (mImapSession != NULL) {
        mImapSession->setConnectionLogger(NULL);
        MC_SAFE_RELEASE(mImapSession);
    }
    if (mPopSession != NULL) {
        mPopSession->setConnectionLogger(NULL);
        MC_SAFE_RELEASE(mPopSession);
    }
    if (mSmtpSession != NULL) {
        mSmtpSession->setConnectionLogger(NULL);
        MC_SAFE_RELEASE(mSmtpSession);
    }

    Operation::cancel();
}

void AccountValidator::operationFinished(Operation * op)
{
    if (op == mResolveMX) {
        resolveMXDone();
    }
    else {
        checkNextHostDone();
    }
}

void AccountValidator::resolveMX()
{
    Array * components;
    String * domain;
    
    components = mEmail->componentsSeparatedByString(MCSTR("@"));
    if (components->count() >= 2) {
        performMethodAfterDelay((Object::Method) &AccountValidator::resolveMXTimeout, NULL, 30.0);

        domain = (String *) components->lastObject();
        mResolveMX = new MXRecordResolverOperation();
        mResolveMX->setHostname(domain);
        mResolveMX->setCallback((OperationCallback *)this);
        
        mQueue = new OperationQueue();
        mQueue->addOperation(mResolveMX);
    }
    else {
        mImapError = ErrorNoValidServerFound;
        mPopError = ErrorNoValidServerFound;
        mSmtpError = ErrorNoValidServerFound;
        
        callback()->operationFinished(this);
    }
}

void AccountValidator::resolveMXTimeout(void * context)
{
    mResolveMX->cancel();
    MC_SAFE_RELEASE(mResolveMX);
    resolveMXDone();
}

void AccountValidator::resolveMXDone()
{
    cancelDelayedPerformMethod((Object::Method) &AccountValidator::resolveMXTimeout, NULL);

    Array * mxRecords = NULL;
    if (mResolveMX != NULL) {
        mxRecords = mResolveMX->mxRecords();
    }

    mc_foreacharray(String, mxRecord, mxRecords) {
        MailProvider * provider = MailProvidersManager::sharedManager()->providerForMX(mxRecord);
        if (provider != NULL){
            MC_SAFE_REPLACE_RETAIN(MailProvider, mProvider, provider);
            if (mProvider != NULL) {
                MC_SAFE_REPLACE_COPY(String, mIdentifier, mProvider->identifier());
            }
            break;
        }
    }
    
    startCheckingHosts();
}

void AccountValidator::setupServices()
{
    if (mImapServices->count() == 0 && mProvider->imapServices() != NULL) {
        MC_SAFE_RELEASE(mImapServices);
        mImapServices = mProvider->imapServices();
        MC_SAFE_RETAIN(mImapServices);
    }

    if (mPopServices->count() == 0 && mProvider->popServices() != NULL) {
        MC_SAFE_RELEASE(mPopServices);
        mPopServices = mProvider->popServices();
        MC_SAFE_RETAIN(mPopServices);
    }

    if (mSmtpServices->count() == 0 && mProvider->smtpServices() != NULL) {
        MC_SAFE_RELEASE(mSmtpServices);
        mSmtpServices = mProvider->smtpServices();
        MC_SAFE_RETAIN(mSmtpServices);
    }
}

void AccountValidator::startCheckingHosts()
{
    if (mProvider != NULL) {
        setupServices();
    }

    if ((mPassword == NULL) && (mOAuth2Token == NULL)) {
        // Shortcut to retrieve only the account type.
        callback()->operationFinished(this);
        return;
    }

    if (mImapEnabled && mImapServices->count() == 0)
        mImapError = ErrorNoValidServerFound;
    
    if (mPopEnabled && mPopServices->count() == 0)
        mPopError = ErrorNoValidServerFound;
    
    if (mSmtpEnabled && mSmtpServices->count() == 0)
        mSmtpError = ErrorNoValidServerFound;
    
    checkNextHost();
}

/**
 Each service(IMAP/POP/SMTP) is tested one after the other.
 For each service we test each server details (NetService),
 Until either:  
    we find on that works and returns ErrorNone in checkNextHostDone().
    we have gone trough the Array of NetService for that service and checkNextHost() is then called for the next service.
 */
void AccountValidator::checkNextHost()
{
    if (mCurrentServiceTested == SERVICE_IMAP) {
        if (mImapEnabled && (mCurrentServiceIndex < mImapServices->count())) {
            mImapSession = new IMAPAsyncSession();
            mImapSession->setUsername(mUsername);
            mImapSession->setPassword(mPassword);
            if (mOAuth2Token != NULL) {
                mImapSession->setOAuth2Token(mOAuth2Token);
                mImapSession->setAuthType(AuthTypeXOAuth2);
            }
            
            mImapServer = (NetService *) mImapServices->objectAtIndex(mCurrentServiceIndex);
            MCLog("checking imap %s %i\n", MCUTF8(mImapServer->hostname()), mImapServer->port());
            mImapSession->setHostname(mImapServer->hostname());
            mImapSession->setPort(mImapServer->port());
            mImapSession->setConnectionType(mImapServer->connectionType());
            mImapSession->setConnectionLogger(this);

            mOperation = mImapSession->checkAccountOperation();
            mOperation->retain();
            mOperation->setCallback(this);
            mOperation->start();
        }
        else if (mImapEnabled && (mImapServices->count() > 0)) {
            mImapServer = NULL;
            callback()->operationFinished(this);
        }
        else {
            mCurrentServiceTested ++;
            mCurrentServiceIndex = 0;
            checkNextHost();
        }
    }
    else if (mCurrentServiceTested == SERVICE_POP){
        if (mPopEnabled && (mCurrentServiceIndex < mPopServices->count())) {
            mPopSession = new POPAsyncSession();
            mPopSession->setUsername(mUsername);
            mPopSession->setPassword(mPassword);

            mPopServer = (NetService *) mPopServices->objectAtIndex(mCurrentServiceIndex);
            MCLog("checking pop %s %i\n", MCUTF8(mPopServer->hostname()), mPopServer->port());
            mPopSession->setHostname(mPopServer->hostname());
            mPopSession->setPort(mPopServer->port());
            mPopSession->setConnectionType(mPopServer->connectionType());
            mPopSession->setConnectionLogger(this);

            mOperation = mPopSession->checkAccountOperation();
            mOperation->retain();
            mOperation->setCallback(this);
            mOperation->start();
        }
        else if (mPopEnabled && (mPopServices->count() > 0)) {
            mPopServer = NULL;
            callback()->operationFinished(this);
        }
        else {
            mCurrentServiceTested ++;
            mCurrentServiceIndex = 0;
            checkNextHost();
        }
    }
    else if (mCurrentServiceTested == SERVICE_SMTP){
        if (mSmtpEnabled && (mCurrentServiceIndex < mSmtpServices->count())) {
            mSmtpSession = new SMTPAsyncSession();
            mSmtpSession->setUsername(mUsername);
            mSmtpSession->setPassword(mPassword);
            if (mOAuth2Token != NULL) {
                mSmtpSession->setOAuth2Token(mOAuth2Token);
                mSmtpSession->setAuthType(AuthTypeXOAuth2);
            }
            
            mSmtpServer = (NetService *) mSmtpServices->objectAtIndex(mCurrentServiceIndex);
            MCLog("checking smtp %s %i\n", MCUTF8(mSmtpServer->hostname()), mSmtpServer->port());
            mSmtpSession->setHostname(mSmtpServer->hostname());
            mSmtpSession->setPort(mSmtpServer->port());
            mSmtpSession->setConnectionType(mSmtpServer->connectionType());
            mSmtpSession->setConnectionLogger(this);

            mOperation = mSmtpSession->checkAccountOperation(Address::addressWithMailbox(mEmail));
            mOperation->retain();
            mOperation->setCallback(this);
            mOperation->start();
        }
        else if (mSmtpEnabled && (mSmtpServices->count() > 0)) {
            mSmtpServer = NULL;
            callback()->operationFinished(this);
        }
        else {
            mCurrentServiceTested ++;
            mCurrentServiceIndex = 0;
            checkNextHost();
        }
    }
    else {
        callback()->operationFinished(this);
    }
}

void AccountValidator::checkNextHostDone()
{
    ErrorCode error = ErrorNone;
    
    if (mCurrentServiceTested == SERVICE_IMAP) {
        if (mImapError == ErrorAuthentication) {
            if (((IMAPOperation *)mOperation)->error() != ErrorConnection) {
                mImapError = ((IMAPOperation *)mOperation)->error();
            }
        }
        else {
            mImapError = ((IMAPOperation *)mOperation)->error();
        }
        MCLog("checking imap done %i\n", mImapError);
        MC_SAFE_REPLACE_COPY(String, mImapLoginResponse, ((IMAPCheckAccountOperation *)mOperation)->loginResponse());
        error = mImapError;
        mImapSession->setConnectionLogger(NULL);
        MC_SAFE_RELEASE(mImapSession);
    }
    else if (mCurrentServiceTested == SERVICE_POP) {
        if (mPopError == ErrorAuthentication) {
            if (((POPOperation *)mOperation)->error() != ErrorConnection) {
                mPopError = ((POPOperation *)mOperation)->error();
            }
        }
        else {
            mPopError = ((POPOperation *)mOperation)->error();
        }
        MCLog("checking pop done %i\n", mImapError);
        error = mPopError;
        mPopSession->setConnectionLogger(NULL);
        MC_SAFE_RELEASE(mPopSession);
    }
    else if (mCurrentServiceTested == SERVICE_SMTP) {
        if (mSmtpError == ErrorAuthentication) {
            if (((SMTPOperation *)mOperation)->error() != ErrorConnection) {
                mSmtpError = ((SMTPOperation *)mOperation)->error();
            }
        }
        else {
            mSmtpError = ((SMTPOperation *)mOperation)->error();
        }
        MCLog("checking smtp done %i\n", mImapError);
        error = mSmtpError;
        mSmtpSession->setConnectionLogger(NULL);
        MC_SAFE_RELEASE(mSmtpSession);
    }
    
    MC_SAFE_RELEASE(mOperation);
    
    if (error == ErrorNone) {
        mCurrentServiceIndex = 0;
        mCurrentServiceTested ++;
    }
    else {
        mCurrentServiceIndex ++;
    }
    
    checkNextHost();
}

void AccountValidator::setEmail(String * email)
{
    MC_SAFE_REPLACE_COPY(String, mEmail, email);
}

String * AccountValidator::email()
{
    return mEmail;
}

void AccountValidator::setUsername(String * username)
{
    MC_SAFE_REPLACE_COPY(String, mUsername, username);
}

String * AccountValidator::username()
{
    return mUsername;
}

void AccountValidator::setPassword(String * password)
{
    MC_SAFE_REPLACE_COPY(String, mPassword, password);
}

String * AccountValidator::password()
{
    return mPassword;
}

void AccountValidator::setOAuth2Token(String * OAuth2Token)
{
    MC_SAFE_REPLACE_COPY(String, mOAuth2Token, OAuth2Token);
}

String * AccountValidator::OAuth2Token()
{
    return mOAuth2Token;
}

void AccountValidator::setImapEnabled(bool enabled)
{
    mImapEnabled = enabled;
}

bool AccountValidator::isImapEnabled()
{
    return mImapEnabled;
}

void AccountValidator::setPopEnabled(bool enabled)
{
    mPopEnabled = enabled;
}

bool AccountValidator::isPopEnabled()
{
    return mPopEnabled;
}


void AccountValidator::setSmtpEnabled(bool enabled)
{
    mSmtpEnabled = enabled;
}

bool AccountValidator::isSmtpEnabled()
{
    return mSmtpEnabled;
}

void AccountValidator::setImapServices(Array * imapServices)
{
    MC_SAFE_REPLACE_COPY(Array, mImapServices, imapServices);
}

Array * AccountValidator::imapServices()
{
    return mImapServices;
}

void AccountValidator::setSmtpServices(Array * smtpServices)
{
    MC_SAFE_REPLACE_COPY(Array, mSmtpServices, smtpServices);
}

Array * AccountValidator::smtpServices()
{
    return mSmtpServices;
}

void AccountValidator::setPopServices(Array * popServices)
{
    MC_SAFE_REPLACE_COPY(Array, mPopServices, popServices);
}

Array * AccountValidator::popServices()
{
    return mPopServices;
}

String * AccountValidator::identifier()
{
    return mIdentifier;
}

NetService * AccountValidator::imapServer()
{
    return mImapServer;
}

NetService * AccountValidator::smtpServer()
{
    return mSmtpServer;
}

NetService * AccountValidator::popServer()
{
    return mPopServer;
}

ErrorCode AccountValidator::imapError()
{
    return mImapError;
}

ErrorCode AccountValidator::popError()
{
    return mPopError;
}

ErrorCode AccountValidator::smtpError()
{
    return mSmtpError;
}

String * AccountValidator::imapLoginResponse()
{
    return mImapLoginResponse;
}

void AccountValidator::setConnectionLogger(ConnectionLogger * logger)
{
    pthread_mutex_lock(&mConnectionLoggerLock);
    mConnectionLogger = logger;
    pthread_mutex_unlock(&mConnectionLoggerLock);
}

ConnectionLogger * AccountValidator::connectionLogger()
{
    ConnectionLogger * result;

    pthread_mutex_lock(&mConnectionLoggerLock);
    result = mConnectionLogger;
    pthread_mutex_unlock(&mConnectionLoggerLock);

    return result;
}

void AccountValidator::log(void * sender, ConnectionLogType logType, Data * buffer)
{
    pthread_mutex_lock(&mConnectionLoggerLock);
    if (mConnectionLogger != NULL) {
        mConnectionLogger->log(this, logType, buffer);
    }
    pthread_mutex_unlock(&mConnectionLoggerLock);
}
