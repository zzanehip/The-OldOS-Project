#include "com_libmailcore_IMAPCapabilityOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPCapabilityOperation.h"

using namespace mailcore;

#define nativeType IMAPCapabilityOperation
#define javaType nativeType

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPCapabilityOperation_capabilities
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(capabilities);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
