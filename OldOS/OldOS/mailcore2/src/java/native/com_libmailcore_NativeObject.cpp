#include "com_libmailcore_NativeObject.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"

#define nativeType Object

using namespace mailcore;

JNIEXPORT void JNICALL Java_com_libmailcore_NativeObject_initWithNative
  (JNIEnv * env, jobject obj, jlong nativeHandle)
{
    setHandle(env, obj, (void *) nativeHandle);
    Object * mcObject = (Object *) nativeHandle;
    MC_SAFE_RETAIN(mcObject);
}

JNIEXPORT void JNICALL Java_com_libmailcore_NativeObject_unsetupNative
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    Object * mcObj = (Object *) getHandle(env, obj);
    MC_SAFE_RELEASE(mcObj);
    setHandle(env, obj, NULL);
    MC_POOL_END;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_NativeObject_toString
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jstring result = NULL;
    Object * mcObj = (Object *) getHandle(env, obj);
    if (mcObj == NULL) {
        result = (jstring) MC_TO_JAVA(MCSTR("<Uninitialized NativeObject>"));
    }
    else {
        result = MC_JAVA_BRIDGE_GET_STRING(description);
    }
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_NativeObject_clone
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_FROM_JAVA(Object, obj)->copy()->autorelease());
    MC_POOL_END;
    return result;
}

JNIEXPORT jbyteArray JNICALL Java_com_libmailcore_NativeObject_serializableData
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(JSON::objectToJSONData(MC_JAVA_NATIVE_INSTANCE->serializable()));
    MC_POOL_END;
    return (jbyteArray) result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_NativeObject_importSerializableData
  (JNIEnv * env, jobject obj, jbyteArray data)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->importSerializable((HashMap *) JSON::objectFromJSONData(MC_FROM_JAVA(Data, data)));
    MC_POOL_END;
}
