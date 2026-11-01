#ifndef MAILCORE_MCOBJECT_H

#define MAILCORE_MCOBJECT_H

#include <pthread.h>
#if __APPLE__
#include <dispatch/dispatch.h>
#include <libkern/OSAtomic.h>
#endif

#include <MailCore/MCUtils.h>

#ifdef __cplusplus

namespace mailcore {
    
    extern bool zombieEnabled;
    
    class String;
    class HashMap;
    
    class MAILCORE_EXPORT Object {
    public:
        Object();
        virtual ~Object();
        
        virtual int retainCount();
        virtual Object * retain();
        virtual void release();
        virtual Object * autorelease();
        virtual String * description();
        virtual String * className();
        
        virtual bool isEqual(Object * otherObject);
        virtual unsigned int hash();
        
        // optional
        virtual Object * copy();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);
        
        typedef void (Object::*Method) (void *);
        virtual void performMethod(Method method, void * context);
        virtual void performMethodOnMainThread(Method method, void * context, bool waitUntilDone = false);
        virtual void performMethodAfterDelay(Method method, void * context, double delay);
#if __APPLE__
        virtual void performMethodOnDispatchQueue(Method method, void * context, void * targetDispatchQueue, bool waitUntilDone = false);
        virtual void performMethodOnDispatchQueueAfterDelay(Method method, void * context, void * targetDispatchQueue, double delay);
        virtual void cancelDelayedPerformMethodOnDispatchQueue(Method method, void * context, void * targetDispatchQueue);
#endif
        virtual void cancelDelayedPerformMethod(Method method, void * context);
        
        // serialization utils
        static void registerObjectConstructor(const char * className, void * (* objectConstructor)(void));
        static Object * objectWithSerializable(HashMap * serializable);
        
    public: // private
        
    private:
#if __APPLE__
        OSSpinLock mLock;
#else
        pthread_mutex_t mLock;
#endif
        int mCounter;
        void init();
        static void initObjectConstructors();
    };

}

#endif

#endif
