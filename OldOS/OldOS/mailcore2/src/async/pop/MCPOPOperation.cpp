//
//  MCPOPOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/16/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCPOPOperation.h"

#include <stdlib.h>

#include "MCPOPSession.h"
#include "MCPOPAsyncSession.h"
#include "MCPOPOperationCallback.h"

using namespace mailcore;

POPOperation::POPOperation()
{
    mSession = NULL;
    mPopCallback = NULL;
    mError = ErrorNone;
}

POPOperation::~POPOperation()
{
    MC_SAFE_RELEASE(mSession);
}

void POPOperation::setSession(POPAsyncSession * session)
{
    MC_SAFE_REPLACE_RETAIN(POPAsyncSession, mSession, session);
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

POPAsyncSession * POPOperation::session()
{
    return mSession;
}

void POPOperation::setPopCallback(POPOperationCallback * callback)
{
    mPopCallback = callback;
}

POPOperationCallback * POPOperation::popCallback()
{
    return mPopCallback;
}

void POPOperation::setError(ErrorCode error)
{
    mError = error;
}

ErrorCode POPOperation::error()
{
    return mError;
}

void POPOperation::start()
{
    mSession->runOperation(this);
}

struct progressContext {
    unsigned int current;
    unsigned int maximum;
};

void POPOperation::bodyProgress(POPSession * session, unsigned int current, unsigned int maximum)
{
    struct progressContext * context = (struct progressContext *) calloc(sizeof(* context), 1);
    context->current = current;
    context->maximum = maximum;
    
    retain();
    performMethodOnCallbackThread((Object::Method) &POPOperation::bodyProgressOnMainThread, context);
}

void POPOperation::bodyProgressOnMainThread(void * ctx)
{
    if (isCancelled()) {
        release();
        return;
    }
    
    struct progressContext * context = (struct progressContext *) ctx;
    if (mPopCallback != NULL) {
        mPopCallback->bodyProgress(this, context->current, context->maximum);
    }
    free(context);
    release();
}
