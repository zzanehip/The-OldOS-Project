#include "com_libmailcore_IMAPMoveMessagesOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPMoveMessagesOperation.h"

using namespace mailcore;

#define nativeType IMAPMoveMessagesOperation
#define javaType nativeType

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPMoveMessagesOperation_uidMapping
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(uidMapping);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
