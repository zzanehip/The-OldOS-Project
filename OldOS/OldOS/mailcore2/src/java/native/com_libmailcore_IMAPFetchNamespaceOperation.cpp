#include "com_libmailcore_IMAPFetchNamespaceOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPFetchNamespaceOperation.h"

using namespace mailcore;

#define nativeType IMAPFetchNamespaceOperation
#define javaType nativeType

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPFetchNamespaceOperation_namespaces
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(namespaces);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
