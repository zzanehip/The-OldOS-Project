#include "com_libmailcore_POPFetchMessageOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCPOPFetchMessageOperation.h"

using namespace mailcore;

#define nativeType POPFetchMessageOperation
#define javaType nativeType

JNIEXPORT jbyteArray JNICALL Java_com_libmailcore_POPFetchMessageOperation_data
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET_DATA(data);
    MC_POOL_END;
    return (jbyteArray) result;
}

MC_JAVA_BRIDGE
