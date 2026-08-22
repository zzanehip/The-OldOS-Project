#include "com_libmailcore_NNTPFetchOverviewOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCNNTPFetchOverviewOperation.h"

using namespace mailcore;

#define nativeType NNTPFetchOverviewOperation
#define javaType nativeType

JNIEXPORT jobject JNICALL Java_com_libmailcore_NNTPFetchOverviewOperation_articles
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(articles);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
