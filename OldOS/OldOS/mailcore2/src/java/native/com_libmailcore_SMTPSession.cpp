#include "com_libmailcore_SMTPSession.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCSMTPAsyncSession.h"
#include "JavaOperationQueueCallback.h"
#include "JavaConnectionLogger.h"

using namespace mailcore;

#define nativeType SMTPAsyncSession
#define javaType SMTPSession

MC_JAVA_SYNTHESIZE_STRING(setHostname, hostname)
MC_JAVA_SYNTHESIZE_SCALAR(jint, unsigned int, setPort, port)
MC_JAVA_SYNTHESIZE_STRING(setUsername, username)
MC_JAVA_SYNTHESIZE_STRING(setPassword, password)
MC_JAVA_SYNTHESIZE_STRING(setOAuth2Token, OAuth2Token)
MC_JAVA_SYNTHESIZE_SCALAR(jint, AuthType, setAuthType, authType)
MC_JAVA_SYNTHESIZE_SCALAR(jint, ConnectionType, setConnectionType, connectionType)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, time_t, setTimeout, timeout)
MC_JAVA_SYNTHESIZE_SCALAR(jboolean, bool, setCheckCertificateEnabled, isCheckCertificateEnabled)
MC_JAVA_SYNTHESIZE_SCALAR(jboolean, bool, setUseHeloIPEnabled, useHeloIPEnabled)

JNIEXPORT jboolean JNICALL Java_com_libmailcore_SMTPSession_isOperationQueueRunning
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jboolean result = MC_JAVA_BRIDGE_GET_SCALAR(jboolean, isOperationQueueRunning);
    MC_POOL_END;
    return result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_SMTPSession_cancelAllOperations
    (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->cancelAllOperations();
    MC_POOL_END;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_SMTPSession_loginOperation
    (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->loginOperation());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_SMTPSession_sendMessageOperation___3B
  (JNIEnv * env, jobject obj, jbyteArray data)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->sendMessageOperation(MC_FROM_JAVA(Data, data)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_SMTPSession_sendMessageOperation__Lcom_libmailcore_Address_2Ljava_util_List_2_3B
  (JNIEnv * env, jobject obj, jobject from, jobject recipients, jbyteArray data)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->sendMessageOperation(MC_FROM_JAVA(Address, from), MC_FROM_JAVA(Array, recipients), MC_FROM_JAVA(Data, data)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_SMTPSession_checkAccountOperation
  (JNIEnv * env, jobject obj, jobject address)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->checkAccountOperation(MC_FROM_JAVA(Address, address)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_SMTPSession_noopOperation
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->noopOperation());
    MC_POOL_END;
    return result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_SMTPSession_finalizeNative
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    JavaOperationQueueCallback * callback = (JavaOperationQueueCallback *) MC_JAVA_NATIVE_INSTANCE->operationQueueCallback();
    MC_SAFE_RELEASE(callback);
    MC_JAVA_NATIVE_INSTANCE->setOperationQueueCallback(NULL);

    JavaConnectionLogger * logger = (JavaConnectionLogger *) MC_JAVA_NATIVE_INSTANCE->connectionLogger();
    MC_SAFE_RELEASE(logger);
    MC_JAVA_NATIVE_INSTANCE->setConnectionLogger(NULL);
    MC_POOL_END;
}

JNIEXPORT void JNICALL Java_com_libmailcore_SMTPSession_setupNativeOperationQueueListener
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    JavaOperationQueueCallback * callback = (JavaOperationQueueCallback *) MC_JAVA_NATIVE_INSTANCE->operationQueueCallback();
    MC_SAFE_RELEASE(callback);
    MC_JAVA_NATIVE_INSTANCE->setOperationQueueCallback(NULL);

    jobject javaListener = getObjectField(env, obj, "operationQueueListener", "J");
    if (javaListener != NULL) {
        callback = new JavaOperationQueueCallback(env, javaListener);
        MC_JAVA_NATIVE_INSTANCE->setOperationQueueCallback(callback);
    }
    MC_POOL_END;
}

JNIEXPORT void JNICALL Java_com_libmailcore_SMTPSession_setupNativeConnectionLogger
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    JavaConnectionLogger * logger = (JavaConnectionLogger *) MC_JAVA_NATIVE_INSTANCE->connectionLogger();
    MC_SAFE_RELEASE(logger);
    MC_JAVA_NATIVE_INSTANCE->setConnectionLogger(NULL);

    jobject javaLogger = getObjectField(env, obj, "connectionLogger", "J");
    if (javaLogger != NULL) {
        logger = new JavaConnectionLogger(env, javaLogger);
        MC_JAVA_NATIVE_INSTANCE->setConnectionLogger(logger);
    }
    MC_POOL_END;
}

MC_JAVA_BRIDGE
