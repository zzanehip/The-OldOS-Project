//
//  MCIMAPOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPOperation.h"

#include <stdlib.h>

#include "MCIMAPAsyncSession.h"
#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"
#include "MCIMAPOperationCallback.h"

using namespace mailcore;

IMAPOperation::IMAPOperation()
{
    mSession = NULL;
    mMainSession = NULL;
    mImapCallback = NULL;
    mError = ErrorNone;
    mFolder = NULL;
    mUrgent = false;
}

IMAPOperation::~IMAPOperation()
{
    MC_SAFE_RELEASE(mMainSession);
    MC_SAFE_RELEASE(mFolder);
    MC_SAFE_RELEASE(mSession);
}

void IMAPOperation::setSession(IMAPAsyncConnection * session)
{
    MC_SAFE_REPLACE_RETAIN(IMAPAsyncConnection, mSession, session);
#if __APPLE__
    dispatch_queue_t queue;
    if (session != NULL) {
        queue = session->dispatchQueue();
    }
    else {
        queue = dispatch_get_main_queue();
    }
    setCallbackDispatchQueue(queue);
#endif
}

IMAPAsyncConnection * IMAPOperation::session()
{
    return mSession;
}

void IMAPOperation::setMainSession(IMAPAsyncSession * session)
{
    MC_SAFE_REPLACE_RETAIN(IMAPAsyncSession, mMainSession, session);
}

IMAPAsyncSession * IMAPOperation::mainSession()
{
    return mMainSession;
}

void IMAPOperation::setFolder(String * folder)
{
    MC_SAFE_REPLACE_COPY(String, mFolder, folder);
}

String * IMAPOperation::folder()
{
    return mFolder;
}

void IMAPOperation::setUrgent(bool urgent)
{
    mUrgent = urgent;
}

bool IMAPOperation::isUrgent()
{
    return mUrgent;
}

void IMAPOperation::setImapCallback(IMAPOperationCallback * callback)
{
    mImapCallback = callback;
}

IMAPOperationCallback * IMAPOperation::imapCallback()
{
    return mImapCallback;
}

void IMAPOperation::setError(ErrorCode error)
{
    mError = error;
}

ErrorCode IMAPOperation::error()
{
    return mError;
}

void IMAPOperation::start()
{
    if (session() == NULL) {
        IMAPAsyncConnection * connection = mMainSession->sessionForFolder(mFolder, mUrgent);
        setSession(connection);
    }
    session()->runOperation(this);
}

struct progressContext {
    unsigned int current;
    unsigned int maximum;
};

void IMAPOperation::bodyProgress(IMAPSession * session, unsigned int current, unsigned int maximum)
{
    if (isCancelled())
        return;
    
    struct progressContext * context = (struct progressContext *) calloc(sizeof(* context), 1);
    context->current = current;
    context->maximum = maximum;
    retain();
    performMethodOnCallbackThread((Object::Method) &IMAPOperation::bodyProgressOnMainThread, context, true);
}

void IMAPOperation::bodyProgressOnMainThread(void * ctx)
{
    if (isCancelled()) {
        release();
        return;
    }
    
    struct progressContext * context = (struct progressContext *) ctx;
    if (mImapCallback != NULL) {
        mImapCallback->bodyProgress(this, context->current, context->maximum);
    }
    free(context);
    release();
}

void IMAPOperation::itemsProgress(IMAPSession * session, unsigned int current, unsigned int maximum)
{
    if (isCancelled())
        return;
    
    struct progressContext * context = (struct progressContext *) calloc(sizeof(* context), 1);
    context->current = current;
    context->maximum = maximum;
    retain();
    performMethodOnCallbackThread((Object::Method) &IMAPOperation::itemsProgressOnMainThread, context, true);
}

void IMAPOperation::itemsProgressOnMainThread(void * ctx)
{
    if (isCancelled()) {
        release();
        return;
    }
    
    struct progressContext * context = (struct progressContext *) ctx;
    if (mImapCallback != NULL) {
        mImapCallback->itemProgress(this, context->current, context->maximum);
    }
    free(context);
    release();
}

void IMAPOperation::beforeMain()
{
}

void IMAPOperation::afterMain()
{
    retain();
    performMethodOnMainThread((Object::Method) &IMAPOperation::afterMainOnMainThread, NULL);
}

void IMAPOperation::afterMainOnMainThread()
{
    if (mSession->session()->isAutomaticConfigurationDone()) {
        mSession->owner()->automaticConfigurationDone(mSession->session());
        mSession->session()->resetAutomaticConfigurationDone();
    }
    release();
}
