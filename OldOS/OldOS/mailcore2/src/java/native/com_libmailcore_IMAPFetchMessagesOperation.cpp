#include "com_libmailcore_IMAPFetchMessagesOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPFetchMessagesOperation.h"
#include "JavaIMAPOperationCallback.h"

using namespace mailcore;

#define nativeType IMAPFetchMessagesOperation
#define javaType nativeType

MC_JAVA_SYNTHESIZE(Array, setExtraHeaders, extraHeaders)

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPFetchMessagesOperation_messages
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(messages);
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPFetchMessagesOperation_vanishedMessages
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(vanishedMessages);
    MC_POOL_END;
    return result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPFetchMessagesOperation_finalizeNative
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    JavaIMAPOperationCallback * callback = (JavaIMAPOperationCallback *) MC_JAVA_NATIVE_INSTANCE->imapCallback();
    MC_SAFE_RELEASE(callback);
    MC_JAVA_NATIVE_INSTANCE->setImapCallback(NULL);
    MC_POOL_END;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPFetchMessagesOperation_setupNativeOperationProgressListener
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    JavaIMAPOperationCallback * callback = (JavaIMAPOperationCallback *) MC_JAVA_NATIVE_INSTANCE->imapCallback();
    MC_SAFE_RELEASE(callback);
    MC_JAVA_NATIVE_INSTANCE->setImapCallback(NULL);

    jobject javaListener = getObjectField(env, obj, "listener", "J");
    if (javaListener != NULL) {
        callback = new JavaIMAPOperationCallback(env, javaListener);
        MC_JAVA_NATIVE_INSTANCE->setImapCallback(callback);
    }
    MC_POOL_END;
}

MC_JAVA_BRIDGE
