#ifndef MAILCORE_MCAUTORELEASEPOOL_H

#define MAILCORE_MCAUTORELEASEPOOL_H

#include <MailCore/MCObject.h>
#include <pthread.h>

#ifdef __cplusplus

typedef struct carray_s carray;

namespace mailcore {
    
    class MAILCORE_EXPORT AutoreleasePool : public Object {
    public:
        AutoreleasePool();
        virtual ~AutoreleasePool();
        
        static void autorelease(Object * obj);
        
    public: // subclass behavior
        virtual String * description();
        
    private:
        static void init();
        static pthread_key_t autoreleasePoolStackKey;
        carray * mPoolObjects;
        static carray * createAutoreleasePoolStackIfNeeded();
        static void destroyAutoreleasePoolStack(void *);
        static void initAutoreleasePoolStackKey();
        static AutoreleasePool * currentAutoreleasePool();
        virtual void add(Object * obj);
#ifdef __APPLE__
        void * mAppleAutoreleasePool;
        static void * createAppleAutoreleasePool();
        static void releaseAppleAutoreleasePool(void * appleAutoreleasePool);
#endif
    };

}

#endif

#endif
