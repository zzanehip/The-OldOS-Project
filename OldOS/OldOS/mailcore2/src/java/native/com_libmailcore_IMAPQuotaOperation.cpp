#include "com_libmailcore_IMAPQuotaOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPQuotaOperation.h"

using namespace mailcore;

#define nativeType IMAPQuotaOperation
#define javaType nativeType

JNIEXPORT jint JNICALL Java_com_libmailcore_IMAPQuotaOperation_usage
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jint result = MC_JAVA_BRIDGE_GET_SCALAR(jint, usage);
    MC_POOL_END;
    return result;
}

JNIEXPORT jint JNICALL Java_com_libmailcore_IMAPQuotaOperation_limit
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jint result = MC_JAVA_BRIDGE_GET_SCALAR(jint, limit);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
