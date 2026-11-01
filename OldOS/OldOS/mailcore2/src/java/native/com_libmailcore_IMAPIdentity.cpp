#include "com_libmailcore_IMAPIdentity.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPIdentity.h"

using namespace mailcore;

#define nativeType IMAPIdentity
#define javaType nativeType

MC_JAVA_SYNTHESIZE_STRING(setVendor, vendor)
MC_JAVA_SYNTHESIZE_STRING(setName, name)
MC_JAVA_SYNTHESIZE_STRING(setVersion, version)

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPIdentity_removeAllInfos
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->removeAllInfos();
    MC_POOL_END;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPIdentity_allInfoKeys
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(allInfoKeys);
    MC_POOL_END;
    return result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_IMAPIdentity_infoForKey
  (JNIEnv * env, jobject obj, jstring key)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->infoForKey(MC_FROM_JAVA(String, key)));
    MC_POOL_END;
    return (jstring) result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPIdentity_setInfoForKey
  (JNIEnv * env, jobject obj, jstring key, jstring value)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->setInfoForKey(MC_FROM_JAVA(String, key), MC_FROM_JAVA(String, value));
    MC_POOL_END;
}

MC_JAVA_BRIDGE
