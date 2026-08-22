#ifndef MAILCORE_MCOPERATIONQUEUE_H

#define MAILCORE_MCOPERATIONQUEUE_H

#include <pthread.h>
#include <semaphore.h>
#include <MailCore/MCObject.h>
#include <MailCore/MCLibetpanTypes.h>

#ifdef __cplusplus

namespace mailcore {
    
    class Operation;
    class OperationQueueCallback;
    class Array;
    
    class MAILCORE_EXPORT OperationQueue : public Object {
    public:
        OperationQueue();
        virtual ~OperationQueue();
        
        virtual void addOperation(Operation * op);
        virtual void cancelAllOperations();
        
        virtual unsigned int count();
        
        virtual void setCallback(OperationQueueCallback * callback);
        virtual OperationQueueCallback * callback();
        
#ifdef __APPLE__
        virtual void setDispatchQueue(dispatch_queue_t dispatchQueue);
        virtual dispatch_queue_t dispatchQueue();
#endif
        
    private:
        Array * mOperations;
        pthread_t mThreadID;
        bool mStarted;
        struct mailsem * mOperationSem;
        struct mailsem * mStartSem;
        struct mailsem * mStopSem;
        pthread_mutex_t mLock;
        bool mWaiting;
        struct mailsem * mWaitingFinishedSem;
        bool mQuitting;
        OperationQueueCallback * mCallback;
#if __APPLE__
        dispatch_queue_t mDispatchQueue;
#endif
        bool _pendingCheckRunning;
        
        void startThread();
        static void runOperationsOnThread(OperationQueue * queue);
        void runOperations();
        void beforeMain(Operation * op);
        void callbackOnMainThread(Operation * op);
        void checkRunningOnMainThread(void * context);
        void checkRunningAfterDelay(void * context);
        void stoppedOnMainThread(void * context);
        void performOnCallbackThread(Operation * op, Method method, void * context, bool waitUntilDone);
    };
    
}

#endif

#endif
