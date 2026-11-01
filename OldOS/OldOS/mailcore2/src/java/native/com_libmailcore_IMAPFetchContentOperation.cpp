#include "com_libmailcore_IMAPFetchContentOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPFetchContentOperation.h"
#include "JavaIMAPOperationCallback.h"

using namespace mailcore;

#define nativeType IMAPFetchContentOperation
#define javaType nativeType

JNIEXPORT jbyteArray JNICALL Java_com_libmailcore_IMAPFetchContentOperation_data
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jbyteArray result = MC_JAVA_BRIDGE_GET_DATA(data);
    MC_POOL_END;
    return result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPFetchContentOperation_finalizeNative
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    JavaIMAPOperationCallback * callback = (JavaIMAPOperationCallback *) MC_JAVA_NATIVE_INSTANCE->imapCallback();
    MC_SAFE_RELEASE(callback);
    MC_JAVA_NATIVE_INSTANCE->setImapCallback(NULL);
    MC_POOL_END;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPFetchContentOperation_setupNativeOperationProgressListener
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    JavaIMAPOperationCallback * callback = (JavaIMAPOperationCallback *) MC_JAVA_NATIVE_INSTANCE->imapCallback();
    MC_SAFE_RELEASE(callback);
    MC_JAVA_NATIVE_INSTANCE->setImapCallback(NULL);

    jobject javaListener = getObjectField(env, obj, "listener", "Lcom/libmailcore/IMAPOperationProgressListener;");
    if (javaListener != NULL) {
        jobject c = reinterpret_cast<jobject>(env->NewGlobalRef(javaListener));
        callback = new JavaIMAPOperationCallback(env, c);
        MC_JAVA_NATIVE_INSTANCE->setImapCallback(callback);
    }
    MC_POOL_END;
}

MC_JAVA_BRIDGE
