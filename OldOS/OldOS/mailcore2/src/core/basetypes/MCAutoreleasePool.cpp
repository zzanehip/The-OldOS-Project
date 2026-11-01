#include "MCAutoreleasePool.h"

#include <libetpan/libetpan.h>

#include "MCString.h"
#include "MCLog.h"
#include "MCUtils.h"

using namespace mailcore;

pthread_key_t AutoreleasePool::autoreleasePoolStackKey;

void AutoreleasePool::init()
{
    static pthread_once_t once = PTHREAD_ONCE_INIT;
    pthread_once(&once, initAutoreleasePoolStackKey);
}

AutoreleasePool::AutoreleasePool()
{
    mPoolObjects = carray_new(4);
    
#if __APPLE__
    mAppleAutoreleasePool = createAppleAutoreleasePool();
#endif
    
    unsigned int idx;
    carray * stack = createAutoreleasePoolStackIfNeeded();
    carray_add(stack, this, &idx);
}

AutoreleasePool::~AutoreleasePool()
{
#if __APPLE__
    releaseAppleAutoreleasePool(mAppleAutoreleasePool);
#endif
    
    carray * stack = createAutoreleasePoolStackIfNeeded();
    carray_delete_slow(stack, carray_count(stack) - 1);
    
    unsigned int count = carray_count(mPoolObjects);
    for(unsigned int i = 0 ; i < count ; i ++) {
        Object * obj = (Object *) carray_get(mPoolObjects, i);
        obj->release();
    }
    carray_free(mPoolObjects);
}

carray * AutoreleasePool::createAutoreleasePoolStackIfNeeded()
{
    init();
    carray * stack = (carray *) pthread_getspecific(autoreleasePoolStackKey);
    if (stack != NULL) {
        return stack;
    }
    
    stack = carray_new(4);
    pthread_setspecific(autoreleasePoolStackKey, stack);
    
    return stack;
}

void AutoreleasePool::destroyAutoreleasePoolStack(void * value)
{
    carray * stack = (carray *) value;
    if (carray_count(stack) != 0) {
        MCLog("some autoreleasepool have not been released\n");
    }
    carray_free(stack);
}

void AutoreleasePool::initAutoreleasePoolStackKey()
{
    pthread_key_create(&autoreleasePoolStackKey, destroyAutoreleasePoolStack);
}

AutoreleasePool * AutoreleasePool::currentAutoreleasePool()
{
    init();
    carray * stack;
    stack = createAutoreleasePoolStackIfNeeded();
    if (carray_count(stack) == 0) {
        //fprintf(stderr, "no current autoreleasepool\n");
        return NULL;
    }

    AutoreleasePool * pool;
    pool = (AutoreleasePool *) carray_get(stack, carray_count(stack) - 1);
    return pool;
}

void AutoreleasePool::add(Object * obj)
{
    unsigned int idx;
    carray_add(mPoolObjects, obj, &idx);
}

void AutoreleasePool::autorelease(Object * obj)
{
    AutoreleasePool * pool = AutoreleasePool::currentAutoreleasePool();
    if (pool == NULL) {
        MCLog("-autorelease called with no current autoreleasepool\n");
        return;
    }
    pool->add(obj);
}

String * AutoreleasePool::description()
{
    String * result = String::string();
    result->appendUTF8Format("<%p:%p ", className(), this);
    unsigned int count = carray_count(mPoolObjects);
    for(unsigned int i = 0 ; i < count ; i ++) {
        Object * obj = (Object *) carray_get(mPoolObjects, i);
        if (i != 0) {
            result->appendUTF8Characters(" ");
        }
        result->appendString(obj->description());
    }
    result->appendUTF8Characters(">");
    
    return result;
}
