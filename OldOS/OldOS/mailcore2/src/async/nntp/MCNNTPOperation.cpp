//
//  MCNNTPOperation.cpp
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCNNTPOperation.h"

#include <stdlib.h>

#include "MCNNTPSession.h"
#include "MCNNTPAsyncSession.h"
#include "MCNNTPOperationCallback.h"

using namespace mailcore;

NNTPOperation::NNTPOperation()
{
    mSession = NULL;
    mPopCallback = NULL;
    mError = ErrorNone;
}

NNTPOperation::~NNTPOperation()
{
    MC_SAFE_RELEASE(mSession);
}

void NNTPOperation::setSession(NNTPAsyncSession * session)
{
    MC_SAFE_REPLACE_RETAIN(NNTPAsyncSession, mSession, session);
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

NNTPAsyncSession * NNTPOperation::session()
{
    return mSession;
}

void NNTPOperation::setNNTPCallback(NNTPOperationCallback * callback)
{
    mPopCallback = callback;
}

NNTPOperationCallback * NNTPOperation::nntpCallback()
{
    return mPopCallback;
}

void NNTPOperation::setError(ErrorCode error)
{
    mError = error;
}

ErrorCode NNTPOperation::error()
{
    return mError;
}

void NNTPOperation::start()
{
    mSession->runOperation(this);
}

struct progressContext {
    unsigned int current;
    unsigned int maximum;
};

void NNTPOperation::bodyProgress(NNTPSession * session, unsigned int current, unsigned int maximum)
{
    struct progressContext * context = (struct progressContext *) calloc(sizeof(* context), 1);
    context->current = current;
    context->maximum = maximum;
    
    retain();
    performMethodOnCallbackThread((Object::Method) &NNTPOperation::bodyProgressOnMainThread, context);
}

void NNTPOperation::bodyProgressOnMainThread(void * ctx)
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
