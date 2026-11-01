#include "com_libmailcore_NNTPFetchArticleOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCNNTPFetchArticleOperation.h"

using namespace mailcore;

#define nativeType NNTPFetchArticleOperation
#define javaType nativeType


JNIEXPORT jbyteArray JNICALL Java_com_libmailcore_NNTPFetchArticleOperation_data
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jbyteArray result = MC_JAVA_BRIDGE_GET_DATA(data);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
