#include "com_libmailcore_IMAPCopyMessagesOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPCopyMessagesOperation.h"

using namespace mailcore;

#define nativeType IMAPCopyMessagesOperation
#define javaType nativeType

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPCopyMessagesOperation_uidMapping
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(uidMapping);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
