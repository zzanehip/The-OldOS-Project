#ifndef MAILCORE_TYPES_UTILS_H

#define MAILCORE_TYPES_UTILS_H

#include <typeinfo>
#include <jni.h>
#include "MCBaseTypes.h"
#include "MCDefines.h"
#include "MCRange.h"

#define MC_TO_JAVA(obj) mailcore::mcObjectToJava(env, (Object *) obj)
#define MC_FROM_JAVA(type, obj) ((type *) mailcore::javaToMCObject(env, (jobject) obj))
#define MC_JAVA_NATIVE_INSTANCE ((nativeType *) mailcore::getHandle(env, obj))
#define MC_JAVA_BRIDGE_GET(getter) MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->getter())
#define MC_JAVA_BRIDGE_GET_STRING(getter) ((jstring) MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->getter()))
#define MC_JAVA_BRIDGE_GET_DATA(getter) ((jbyteArray) MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->getter()))
#define MC_JAVA_BRIDGE_GET_SCALAR(javaScalarType, getter) ((javaScalarType) MC_JAVA_NATIVE_INSTANCE->getter())

#define MC_JAVA_SYNTHESIZE(type, setter, getter) MC_JAVA_SYNTHESIZE_internal(type, javaType, setter, getter)
#define MC_JAVA_SYNTHESIZE_STRING(setter, getter) MC_JAVA_SYNTHESIZE_STRING_internal(javaType, setter, getter)
#define MC_JAVA_SYNTHESIZE_DATA(setter, getter) MC_JAVA_SYNTHESIZE_DATA_internal(javaType, setter, getter)
#define MC_JAVA_SYNTHESIZE_SCALAR(javaScalarType, scalarType, setter, getter) MC_JAVA_SYNTHESIZE_SCALAR_internal(javaScalarType, scalarType, javaType, setter, getter)
#define MC_JAVA_BRIDGE MC_JAVA_BRIDGE_internal(javaType, nativeType)

#define MC_JAVA_CONCAT(a, b) a ## b
#define prefixed_function(javaType, function_name) Java_com_libmailcore_ ## javaType ## _ ## function_name

#define MC_POOL_BEGIN AutoreleasePool * __pool = new AutoreleasePool();
#define MC_POOL_END __pool->release();

#define MC_JAVA_SYNTHESIZE_internal(type, javaType, setter, getter) \
    JNIEXPORT jobject JNICALL prefixed_function(javaType, getter) (JNIEnv * env, jobject obj) \
    { \
        MC_POOL_BEGIN; \
        jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->getter()); \
        MC_POOL_END; \
        return result; \
    } \
    \
    JNIEXPORT void JNICALL prefixed_function(javaType, setter) (JNIEnv * env, jobject obj, jobject value) \
    { \
        MC_POOL_BEGIN; \
        MC_JAVA_NATIVE_INSTANCE->setter(MC_FROM_JAVA(type, value)); \
        MC_POOL_END; \
    }

#define MC_JAVA_SYNTHESIZE_STRING_internal(javaType, setter, getter) \
    JNIEXPORT jstring JNICALL prefixed_function(javaType, getter) (JNIEnv * env, jobject obj) \
    { \
        MC_POOL_BEGIN; \
        jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->getter()); \
        MC_POOL_END; \
        return (jstring) result; \
    } \
    \
    JNIEXPORT void JNICALL prefixed_function(javaType, setter) (JNIEnv * env, jobject obj, jstring value) \
    { \
        MC_POOL_BEGIN; \
        MC_JAVA_NATIVE_INSTANCE->setter(MC_FROM_JAVA(String, value)); \
        MC_POOL_END; \
    }

#define MC_JAVA_SYNTHESIZE_DATA_internal(javaType, setter, getter) \
    JNIEXPORT jbyteArray JNICALL prefixed_function(javaType, getter) (JNIEnv * env, jobject obj) \
    { \
        MC_POOL_BEGIN; \
        jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->getter()); \
        MC_POOL_END; \
        return (jbyteArray) result; \
    } \
    \
    JNIEXPORT void JNICALL prefixed_function(javaType, setter) (JNIEnv * env, jobject obj, jbyteArray value) \
    { \
        MC_POOL_BEGIN; \
        MC_JAVA_NATIVE_INSTANCE->setter(MC_FROM_JAVA(Data, value)); \
        MC_POOL_END; \
    }

#define MC_JAVA_SYNTHESIZE_SCALAR_internal(javaScalarType, scalarType, javaType, setter, getter) \
    JNIEXPORT javaScalarType JNICALL prefixed_function(javaType, getter) (JNIEnv * env, jobject obj) \
    { \
        MC_POOL_BEGIN; \
        javaScalarType result = (javaScalarType) MC_JAVA_NATIVE_INSTANCE->getter(); \
        MC_POOL_END; \
        return result; \
    } \
    \
    JNIEXPORT void JNICALL prefixed_function(javaType, setter) (JNIEnv * env, jobject obj, javaScalarType value) \
    { \
        MC_POOL_BEGIN; \
        MC_JAVA_NATIVE_INSTANCE->setter((scalarType) value); \
        MC_POOL_END; \
    }

#define mc_quote(word) #word
#define mc_expand_and_quote(word) mc_quote(word)

#define MC_JAVA_BRIDGE_internal(javaType, nativeType) \
    JNIEXPORT void JNICALL prefixed_function(javaType, setupNative) \
      (JNIEnv * env, jobject obj) \
    { \
        setHandle(env, obj, new nativeType()); \
    } \
    \
    static jobject objectToJavaConverter(JNIEnv * env, Object * obj) \
    { \
        jclass cls = env->FindClass("com/libmailcore/" mc_expand_and_quote(javaType)); \
        jmethodID constructor = env->GetMethodID(cls, "<init>", "()V"); \
        jobject javaObject = env->NewObject(cls, constructor); \
        jmethodID initMethod = env->GetMethodID(cls, "initWithNative", "(J)V"); \
        env->CallVoidMethod(javaObject, initMethod, (jlong) obj); \
        return javaObject; \
    } \
    \
    INITIALIZE(prefixed_function(javaType,)) \
    { \
        MCJNIRegisterNativeClass(&typeid(mailcore::nativeType), (ObjectToJavaConverter *) objectToJavaConverter); \
    }

namespace mailcore {
    typedef jobject ObjectToJavaConverter(JNIEnv * env, Object * obj);
    typedef Object * JavaToObjectConverter(JNIEnv * env, jobject obj);
    
    Object * javaToMCObject(JNIEnv * env, jobject obj);
    jobject mcObjectToJava(JNIEnv * env, Object * obj);
    
    jobject errorToJava(int errorCode);
    
    time_t javaDateToTime(JNIEnv * env, jobject date);
    jobject timeToJavaDate(JNIEnv * env, time_t t);
    
    jobject rangeToJava(JNIEnv * env, Range range);
    Range rangeFromJava(JNIEnv * env, jobject obj);
    
    void MCJNIRegisterNativeClass(const std::type_info * info, ObjectToJavaConverter converter);
    void MCJNIRegisterJavaClass(const char * className, JavaToObjectConverter converter);
    void MCTypesUtilsInit(void);
}

#endif
