#include "com_libmailcore_NNTPOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCNNTPOperation.h"

using namespace mailcore;

#define nativeType NNTPOperation
#define javaType nativeType

JNIEXPORT jint JNICALL Java_com_libmailcore_NNTPOperation_errorCode
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jint result = MC_JAVA_BRIDGE_GET_SCALAR(jint, error);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
