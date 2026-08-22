#ifndef MAILCORE_MCOPERATION_H

#define MAILCORE_MCOPERATION_H

#include <pthread.h>
#include <MailCore/MCObject.h>

#ifdef __cplusplus

namespace mailcore {
    
    class OperationCallback;
    
    class MAILCORE_EXPORT Operation : public Object {
    public:
        Operation();
        virtual ~Operation();
        
        virtual void setCallback(OperationCallback * callback);
        virtual OperationCallback * callback();
        
        virtual void cancel();
        virtual bool isCancelled();
        
        // Will be called on main thread.
        virtual void beforeMain();
        
        virtual void main();
        
        // Will be called on main thread.
        virtual void afterMain();
        
        virtual void start();
        
#ifdef __APPLE__
        virtual void setCallbackDispatchQueue(dispatch_queue_t callbackDispatchQueue);
        virtual dispatch_queue_t callbackDispatchQueue();
#endif
        void performMethodOnCallbackThread(Method method, void * context, bool waitUntilDone = false);
        
        virtual bool shouldRunWhenCancelled();
        virtual void setShouldRunWhenCancelled(bool shouldRunWhenCancelled);
        
    private:
        OperationCallback * mCallback;
        bool mCancelled;
        bool mShouldRunWhenCancelled;
        pthread_mutex_t mLock;
#ifdef __APPLE__
        dispatch_queue_t mCallbackDispatchQueue;
#endif
        
    };
    
}

#endif

#endif
