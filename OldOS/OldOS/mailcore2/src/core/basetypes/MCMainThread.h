#ifndef MAILCORE_MCMAINTHREAD_H

#define MAILCORE_MCMAINTHREAD_H

#ifdef __cplusplus

namespace mailcore {
    void callOnMainThread(void (*)(void *), void * context);
    void callOnMainThreadAndWait(void (*)(void *), void * context);
    
    // Returns a "call" object.
    void * callAfterDelay(void (*)(void *), void * context, double time);
    
    // Pass the pointer returns by callAfterDelay() to cancel a delayed call.
    void cancelDelayedCall(void * call);
}

#endif

#endif
