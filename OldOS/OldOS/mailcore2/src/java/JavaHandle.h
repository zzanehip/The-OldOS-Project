#ifndef MAILCORE_JAVA_HANDLE_H

#define MAILCORE_JAVA_HANDLE_H

#include <jni.h>

namespace mailcore {
    void * getHandle(JNIEnv * env, jobject obj);
    void setHandle(JNIEnv * env, jobject obj, void * t);
    void * getCustomHandle(JNIEnv * env, jobject obj, const char * fieldName);
    void setCustomHandle(JNIEnv *env, jobject obj, const char * fieldName, void *t);
    jobject getObjectField(JNIEnv *env, jobject obj, const char * fieldName, const char * fieldClass);
}

#endif
