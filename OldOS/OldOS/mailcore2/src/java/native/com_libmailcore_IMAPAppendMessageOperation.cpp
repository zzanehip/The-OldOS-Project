#include "com_libmailcore_IMAPAppendMessageOperation.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "JavaIMAPOperationCallback.h"
#include "MCIMAPAppendMessageOperation.h"

using namespace mailcore;

#define nativeType IMAPAppendMessageOperation
#define javaType nativeType

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPAppendMessageOperation_setDate
  (JNIEnv * env, jobject obj, jobject date)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->setDate(javaDateToTime(env, date));
    MC_POOL_END;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPAppendMessageOperation_date
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = timeToJavaDate(env, MC_JAVA_NATIVE_INSTANCE->date());
    MC_POOL_END;
    return result;
}

JNIEXPORT jlong JNICALL Java_com_libmailcore_IMAPAppendMessageOperation_createdUID
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jlong result = MC_JAVA_BRIDGE_GET_SCALAR(jlong, createdUID);
    MC_POOL_END;
    return result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPAppendMessageOperation_finalizeNative
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    JavaIMAPOperationCallback * callback = (JavaIMAPOperationCallback *) MC_JAVA_NATIVE_INSTANCE->imapCallback();
    MC_SAFE_RELEASE(callback);
    MC_JAVA_NATIVE_INSTANCE->setImapCallback(NULL);
    MC_POOL_END;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPAppendMessageOperation_setupNativeOperationProgressListener
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
