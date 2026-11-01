#include "com_libmailcore_IMAPIdleOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPIdleOperation.h"

using namespace mailcore;

#define nativeType IMAPIdleOperation
#define javaType nativeType

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPIdleOperation_interruptIdle
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->interruptIdle();
    MC_POOL_END;
}

MC_JAVA_BRIDGE
