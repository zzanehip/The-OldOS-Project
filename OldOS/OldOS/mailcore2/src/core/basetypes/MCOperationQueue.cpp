#include "MCOperationQueue.h"

#include <libetpan/libetpan.h>

#include "MCOperation.h"
#include "MCOperationCallback.h"
#include "MCOperationQueueCallback.h"
#include "MCMainThread.h"
#include "MCUtils.h"
#include "MCArray.h"
#include "MCLog.h"
#include "MCAutoreleasePool.h"
#include "MCMainThreadAndroid.h"
#include "MCAssert.h"

using namespace mailcore;

OperationQueue::OperationQueue()
{
    mOperations = new Array();
    mStarted = false;
    pthread_mutex_init(&mLock, NULL);
    mWaiting = false;
    mOperationSem = mailsem_new();
    mStartSem = mailsem_new();
    mStopSem = mailsem_new();
    mWaitingFinishedSem = mailsem_new();
    mQuitting = false;
    mCallback = NULL;
#if __APPLE__
    mDispatchQueue = dispatch_get_main_queue();
#endif
    _pendingCheckRunning = false;
}

OperationQueue::~OperationQueue()
{
#if __APPLE__
    if (mDispatchQueue != NULL) {
        dispatch_release(mDispatchQueue);
    }
#endif
    MC_SAFE_RELEASE(mOperations);
    pthread_mutex_destroy(&mLock);
    mailsem_free(mOperationSem);
    mailsem_free(mStartSem);
    mailsem_free(mStopSem);
    mailsem_free(mWaitingFinishedSem);
}

void OperationQueue::addOperation(Operation * op)
{
    pthread_mutex_lock(&mLock);
    mOperations->addObject(op);
    pthread_mutex_unlock(&mLock);
    mailsem_up(mOperationSem);
    startThread();
}

void OperationQueue::cancelAllOperations()
{
    pthread_mutex_lock(&mLock);
    for (unsigned int i = 0 ; i < mOperations->count() ; i ++) {
        Operation * op = (Operation *) mOperations->objectAtIndex(i);
        op->cancel();
    }
    pthread_mutex_unlock(&mLock);
}

void OperationQueue::runOperationsOnThread(OperationQueue * queue)
{
    queue->runOperations();
}

void OperationQueue::runOperations()
{
#if defined(__ANDROID) || defined(ANDROID)
    androidSetupThread();
#endif

    MCLog("start thread");
    mailsem_up(mStartSem);
    
    while (true) {
        Operation * op = NULL;
        bool needsCheckRunning = false;
        bool quitting;
        
        AutoreleasePool * pool = new AutoreleasePool();
        
        mailsem_down(mOperationSem);
        
        pthread_mutex_lock(&mLock);
        if (mOperations->count() > 0) {
            op = (Operation *) mOperations->objectAtIndex(0);
        }
        quitting = mQuitting;
        pthread_mutex_unlock(&mLock);

        //MCLog("quitting %i %p", mQuitting, op);
        if ((op == NULL) && quitting) {
            MCLog("stopping %p", this);
            mailsem_up(mStopSem);
            
            retain(); // (2)
#if __APPLE__
            performMethodOnDispatchQueue((Object::Method) &OperationQueue::stoppedOnMainThread, NULL, mDispatchQueue, true);
#else
            performMethodOnMainThread((Object::Method) &OperationQueue::stoppedOnMainThread, NULL, true);
#endif
            
            pool->release();
            break;
        }

        MCAssert(op != NULL);
        performOnCallbackThread(op, (Object::Method) &OperationQueue::beforeMain, op, true);
        
        if (!op->isCancelled() || op->shouldRunWhenCancelled()) {
            op->main();
        }
        
        op->retain()->autorelease();
        
        pthread_mutex_lock(&mLock);
        mOperations->removeObjectAtIndex(0);
        if (mOperations->count() == 0) {
            if (mWaiting) {
                mailsem_up(mWaitingFinishedSem);
            }
            needsCheckRunning = true;
        }
        pthread_mutex_unlock(&mLock);
        
        if (!op->isCancelled()) {
            performOnCallbackThread(op, (Object::Method) &OperationQueue::callbackOnMainThread, op, true);
        }
        
        if (needsCheckRunning) {
            retain(); // (1)
            //MCLog("check running %p", this);
#if __APPLE__
            performMethodOnDispatchQueue((Object::Method) &OperationQueue::checkRunningOnMainThread, this, mDispatchQueue);
#else
            performMethodOnMainThread((Object::Method) &OperationQueue::checkRunningOnMainThread, this);
#endif
        }
        
        pool->release();
    }
    MCLog("cleanup thread %p", this);
#if defined(__ANDROID) || defined(ANDROID)
    androidUnsetupThread();
#endif
}

void OperationQueue::performOnCallbackThread(Operation * op, Method method, void * context, bool waitUntilDone)
{
#if __APPLE__
    dispatch_queue_t queue = op->callbackDispatchQueue();
    if (queue == NULL) {
        queue = dispatch_get_main_queue();
    }
    performMethodOnDispatchQueue(method, context, queue, waitUntilDone);
#else
    performMethodOnMainThread(method, context, waitUntilDone);
#endif
}

void OperationQueue::beforeMain(Operation * op)
{
    op->beforeMain();
}

void OperationQueue::callbackOnMainThread(Operation * op)
{
    op->afterMain();
    
    if (op->isCancelled())
        return;
    
    if (op->callback() != NULL) {
        op->callback()->operationFinished(op);
    }
}

void OperationQueue::checkRunningOnMainThread(void * context)
{
    retain(); // (4)
    if (_pendingCheckRunning) {
#if __APPLE__
        cancelDelayedPerformMethodOnDispatchQueue((Object::Method) &OperationQueue::checkRunningAfterDelay, NULL, mDispatchQueue);
#else
        cancelDelayedPerformMethod((Object::Method) &OperationQueue::checkRunningAfterDelay, NULL);
#endif
        release(); // (4)
    }
    _pendingCheckRunning = true;
    
#if __APPLE__
    performMethodOnDispatchQueueAfterDelay((Object::Method) &OperationQueue::checkRunningAfterDelay, NULL, mDispatchQueue, 1);
#else
    performMethodAfterDelay((Object::Method) &OperationQueue::checkRunningAfterDelay, NULL, 1);
#endif

    release(); // (1)
}

void OperationQueue::checkRunningAfterDelay(void * context)
{
    _pendingCheckRunning = false;
    pthread_mutex_lock(&mLock);
    if (!mQuitting) {
        if (mOperations->count() == 0) {
            MCLog("trying to quit %p", this);
            mailsem_up(mOperationSem);
            mQuitting = true;
        }
    }
    pthread_mutex_unlock(&mLock);
    
    // Number of operations can't be changed because it runs on main thread.
    // And addOperation() should also be called from main thread.
    
    release(); // (4)
}

void OperationQueue::stoppedOnMainThread(void * context)
{
    MCLog("thread stopped %p", this);
    mailsem_down(mStopSem);
    mStarted = false;
    
    if (mCallback) {
        mCallback->queueStoppedRunning();
    }
    
    if (mOperations->count() > 0) {
        //Operations have been added while thread was quitting, so restart automatically
        startThread();
    }

    release(); // (2)

    release(); // (3)
}

void OperationQueue::startThread()
{
    if (mStarted)
        return;
    
    if (mCallback) {
        mCallback->queueStartRunning();
    }
    
    retain(); // (3)
    mQuitting = false;
    mStarted = true;
    pthread_create(&mThreadID, NULL, (void * (*)(void *)) OperationQueue::runOperationsOnThread, this);
    pthread_detach(mThreadID);
    mailsem_down(mStartSem);
}

unsigned int OperationQueue::count()
{
    unsigned int count;
    
    pthread_mutex_lock(&mLock);
    count = mOperations->count();
    pthread_mutex_unlock(&mLock);
    
    return count;
}

void OperationQueue::setCallback(OperationQueueCallback * callback)
{
    mCallback = callback;
}

OperationQueueCallback * OperationQueue::callback()
{
    return mCallback;
}

#if 0
void OperationQueue::waitUntilAllOperationsAreFinished()
{
    bool waiting = false;
    
    pthread_mutex_lock(&mLock);
    if (mOperations->count() > 0) {
        mWaiting = true;
        waiting = true;
    }
    pthread_mutex_unlock(&mLock);
    
    if (waiting) {
        sem_wait(&mWaitingFinishedSem);
    }
    mWaiting = false;
}
#endif

#if __APPLE__
void OperationQueue::setDispatchQueue(dispatch_queue_t dispatchQueue)
{
    if (mDispatchQueue != NULL) {
        dispatch_release(mDispatchQueue);
    }
    mDispatchQueue = dispatchQueue;
    if (mDispatchQueue != NULL) {
        dispatch_retain(mDispatchQueue);
    }
}

dispatch_queue_t OperationQueue::dispatchQueue()
{
    return mDispatchQueue;
}
#endif
