#include "com_libmailcore_NNTPListNewsgroupsOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCNNTPListNewsgroupsOperation.h"

using namespace mailcore;

#define nativeType NNTPListNewsgroupsOperation
#define javaType nativeType

JNIEXPORT jobject JNICALL Java_com_libmailcore_NNTPListNewsgroupsOperation_groups
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(groups);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
