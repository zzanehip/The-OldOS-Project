#include "com_libmailcore_POPFetchHeaderOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCPOPFetchHeaderOperation.h"

using namespace mailcore;

#define nativeType POPFetchHeaderOperation
#define javaType nativeType

JNIEXPORT jobject JNICALL Java_com_libmailcore_POPFetchHeaderOperation_header
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(header);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
