//
//  MCSMTPOperation.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/11/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCSMTPOperation.h"

#include <stdlib.h>

#include "MCSMTPSession.h"
#include "MCSMTPAsyncSession.h"
#include "MCSMTPOperationCallback.h"

using namespace mailcore;

SMTPOperation::SMTPOperation()
{
    mSession = NULL;
    mError = ErrorNone;
    mSmtpCallback = NULL;
}

SMTPOperation::~SMTPOperation()
{
    MC_SAFE_RELEASE(mSession);
}

void SMTPOperation::setSession(SMTPAsyncSession * session)
{
    MC_SAFE_REPLACE_RETAIN(SMTPAsyncSession, mSession, session);
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

SMTPAsyncSession * SMTPOperation::session()
{
    return mSession;
}

void SMTPOperation::start()
{
    mSession->runOperation(this);
}

void SMTPOperation::setSmtpCallback(SMTPOperationCallback * callback)
{
    mSmtpCallback = callback;
}

SMTPOperationCallback * SMTPOperation::smtpCallback()
{
    return mSmtpCallback;
}

void SMTPOperation::setError(ErrorCode error)
{
    mError = error;
}

ErrorCode SMTPOperation::error()
{
    return mError;
}

String * SMTPOperation::lastSMTPResponse()
{
    return session()->session()->lastSMTPResponse();
}

int SMTPOperation::lastSMTPResponseCode()
{
    return session()->session()->lastSMTPResponseCode();
}

struct progressContext {
    unsigned int current;
    unsigned int maximum;
};

void SMTPOperation::bodyProgress(SMTPSession * session, unsigned int current, unsigned int maximum)
{
    struct progressContext * context = (struct progressContext *) calloc(sizeof(* context), 1);
    context->current = current;
    context->maximum = maximum;
    
    retain();
    performMethodOnCallbackThread((Object::Method) &SMTPOperation::bodyProgressOnMainThread, context);
}

void SMTPOperation::bodyProgressOnMainThread(void * ctx)
{
    if (isCancelled()) {
        release();
        return;
    }
    
    struct progressContext * context = (struct progressContext *) ctx;
    if (mSmtpCallback != NULL) {
        mSmtpCallback->bodyProgress(this, context->current, context->maximum);
    }
    free(context);
    release();
}
