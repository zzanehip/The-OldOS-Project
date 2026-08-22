#include "com_libmailcore_IMAPSession.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPAsyncSession.h"
#include "JavaOperationQueueCallback.h"
#include "JavaConnectionLogger.h"

using namespace mailcore;

#define nativeType IMAPAsyncSession
#define javaType IMAPSession

MC_JAVA_SYNTHESIZE_STRING(setHostname, hostname)
MC_JAVA_SYNTHESIZE_SCALAR(jint, unsigned int, setPort, port)
MC_JAVA_SYNTHESIZE_STRING(setUsername, username)
MC_JAVA_SYNTHESIZE_STRING(setPassword, password)
MC_JAVA_SYNTHESIZE_STRING(setOAuth2Token, OAuth2Token)
MC_JAVA_SYNTHESIZE_SCALAR(jint, AuthType, setAuthType, authType)
MC_JAVA_SYNTHESIZE_SCALAR(jint, ConnectionType, setConnectionType, connectionType)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, time_t, setTimeout, timeout)
MC_JAVA_SYNTHESIZE_SCALAR(jboolean, bool, setCheckCertificateEnabled, isCheckCertificateEnabled)
MC_JAVA_SYNTHESIZE(IMAPNamespace, setDefaultNamespace, defaultNamespace)
MC_JAVA_SYNTHESIZE_SCALAR(jboolean, bool, setAllowsFolderConcurrentAccessEnabled, allowsFolderConcurrentAccessEnabled)
MC_JAVA_SYNTHESIZE_SCALAR(jint, unsigned int, setMaximumConnections, maximumConnections)

JNIEXPORT jboolean JNICALL Java_com_libmailcore_IMAPSession_isOperationQueueRunning
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jboolean result = MC_JAVA_BRIDGE_GET_SCALAR(jboolean, isOperationQueueRunning);
    MC_POOL_END;
    return result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPSession_cancelAllOperations
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->cancelAllOperations();
    MC_POOL_END;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_serverIdentity
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(serverIdentity);
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_clientIdentity
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(clientIdentity);
    MC_POOL_END;
    return result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_IMAPSession_gmailUserDisplayName
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jstring result = MC_JAVA_BRIDGE_GET_STRING(gmailUserDisplayName);
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_folderInfoOperation
  (JNIEnv * env, jobject obj, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->folderInfoOperation(MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

/*
 * Class:     com_libmailcore_IMAPSession
 * Method:    folderStatusOperation
 * Signature: (Ljava/lang/String;)Lcom/libmailcore/IMAPFolderStatusOperation;
 */
JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_folderStatusOperation
  (JNIEnv * env, jobject obj, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->folderStatusOperation(MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_fetchSubscribedFoldersOperation
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->fetchSubscribedFoldersOperation());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_fetchAllFoldersOperation
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->fetchAllFoldersOperation());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_renameFolderOperation
  (JNIEnv * env, jobject obj, jstring currentName, jstring otherName)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->renameFolderOperation(MC_FROM_JAVA(String, currentName), MC_FROM_JAVA(String, otherName)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_deleteFolderOperation
  (JNIEnv * env, jobject obj, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->deleteFolderOperation(MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_createFolderOperation
  (JNIEnv * env, jobject obj, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->createFolderOperation(MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_subscribeFolderOperation
  (JNIEnv * env, jobject obj, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->subscribeFolderOperation(MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_unsubscribeFolderOperation
  (JNIEnv * env, jobject obj, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->unsubscribeFolderOperation(MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_appendMessageOperation
  (JNIEnv * env, jobject obj, jstring path, jbyteArray data, jint flags, jobject customFlags)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->appendMessageOperation(MC_FROM_JAVA(String, path),
        MC_FROM_JAVA(Data, data), (MessageFlag) flags, MC_FROM_JAVA(Array, customFlags)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_copyMessagesOperation
  (JNIEnv * env, jobject obj, jstring sourcePath, jobject uids, jstring destPath)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->copyMessagesOperation(MC_FROM_JAVA(String, sourcePath),
        MC_FROM_JAVA(IndexSet, uids), MC_FROM_JAVA(String, destPath)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_moveMessagesOperation
  (JNIEnv * env, jobject obj, jstring sourcePath, jobject uids, jstring destPath)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->moveMessagesOperation(MC_FROM_JAVA(String, sourcePath),
        MC_FROM_JAVA(IndexSet, uids), MC_FROM_JAVA(String, destPath)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_expungeOperation
  (JNIEnv * env, jobject obj, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->expungeOperation(MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_fetchMessagesByUIDOperation
  (JNIEnv * env, jobject obj, jstring path, jint kind, jobject uids)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->fetchMessagesByUIDOperation(MC_FROM_JAVA(String, path), (IMAPMessagesRequestKind) kind, MC_FROM_JAVA(IndexSet, uids)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_fetchMessagesByNumberOperation
  (JNIEnv * env, jobject obj, jstring path, jint kind, jobject numbers)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->fetchMessagesByNumberOperation(MC_FROM_JAVA(String, path), (IMAPMessagesRequestKind) kind, MC_FROM_JAVA(IndexSet, numbers)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_syncMessagesByUIDOperation
  (JNIEnv * env, jobject obj, jstring path, jint kind, jobject uids, jlong modSeq)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->syncMessagesByUIDOperation(MC_FROM_JAVA(String, path), (IMAPMessagesRequestKind) kind, MC_FROM_JAVA(IndexSet, uids), (uint64_t) modSeq));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_fetchMessageByUIDOperation
  (JNIEnv * env, jobject obj, jstring path, jlong uid, jboolean urgent)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->fetchMessageByUIDOperation(MC_FROM_JAVA(String, path), (uint32_t) uid, (bool) urgent));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_fetchMessageAttachmentByUIDOperation
  (JNIEnv * env, jobject obj, jstring path, jlong uid, jstring partID, jint encoding, jboolean urgent)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->fetchMessageAttachmentByUIDOperation(MC_FROM_JAVA(String, path),
        (uint32_t) uid, MC_FROM_JAVA(String, partID), (Encoding) encoding, (bool) urgent));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_fetchMessageByNumberOperation
  (JNIEnv * env, jobject obj, jstring path, jlong number, jboolean urgent)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->fetchMessageByNumberOperation(MC_FROM_JAVA(String, path),
        (uint32_t) number, (bool) urgent));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_fetchMessageAttachmentByNumberOperation
  (JNIEnv * env, jobject obj, jstring path, jlong number, jstring partID, jint encoding, jboolean urgent)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->fetchMessageAttachmentByNumberOperation(MC_FROM_JAVA(String, path),
        (uint32_t) number, MC_FROM_JAVA(String, partID), (Encoding) encoding, (bool) urgent));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_fetchParsedMessageByUIDOperation
  (JNIEnv * env, jobject obj, jstring path, jlong uid, jboolean urgent)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->fetchParsedMessageByUIDOperation(MC_FROM_JAVA(String, path),
        (uint32_t) uid, (bool) urgent));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_fetchParsedMessageByNumberOperation
  (JNIEnv * env, jobject obj, jstring path, jlong number, jboolean urgent)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->fetchParsedMessageByNumberOperation(MC_FROM_JAVA(String, path),
        (uint32_t) number, (bool) urgent));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_storeFlagsByUIDOperation
  (JNIEnv * env, jobject obj, jstring path, jobject uids, jint kind, jint flags, jobject customFlags)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->storeFlagsByUIDOperation(MC_FROM_JAVA(String, path),
        MC_FROM_JAVA(IndexSet, uids), (IMAPStoreFlagsRequestKind) kind, (MessageFlag) flags, MC_FROM_JAVA(Array, customFlags)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_storeFlagsByNumberOperation
  (JNIEnv * env, jobject obj, jstring path, jobject uids, jint kind, jint flags, jobject customFlags)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->storeFlagsByUIDOperation(MC_FROM_JAVA(String, path),
        MC_FROM_JAVA(IndexSet, uids), (IMAPStoreFlagsRequestKind) kind, (MessageFlag) flags, MC_FROM_JAVA(Array, customFlags)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_storeLabelsByUIDOperation
  (JNIEnv * env, jobject obj, jstring path, jobject uids, jint kind, jobject labels)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->storeLabelsByUIDOperation(MC_FROM_JAVA(String, path),
        MC_FROM_JAVA(IndexSet, uids), (IMAPStoreFlagsRequestKind) kind, MC_FROM_JAVA(Array, labels)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_storeLabelsByNumberOperation
  (JNIEnv * env, jobject obj, jstring path, jobject numbers, jint kind, jobject labels)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->storeLabelsByNumberOperation(MC_FROM_JAVA(String, path),
        MC_FROM_JAVA(IndexSet, numbers), (IMAPStoreFlagsRequestKind) kind, MC_FROM_JAVA(Array, labels)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_searchOperation__Ljava_lang_String_2ILjava_lang_String_2
  (JNIEnv * env, jobject obj, jstring path, jint kind, jstring searchString)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->searchOperation(MC_FROM_JAVA(String, path),
        (IMAPSearchKind) kind, MC_FROM_JAVA(String, searchString)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_searchOperation__Ljava_lang_String_2Lcom_libmailcore_IMAPSearchExpression_2
  (JNIEnv * env, jobject obj, jstring path, jobject expression)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->searchOperation(MC_FROM_JAVA(String, path),
        MC_FROM_JAVA(IMAPSearchExpression, expression)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_idleOperation
  (JNIEnv * env, jobject obj, jstring path, jlong lastKnownUID)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->idleOperation(MC_FROM_JAVA(String, path), (uint32_t) lastKnownUID));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_fetchNamespaceOperation
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->fetchNamespaceOperation());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_identityOperation
  (JNIEnv * env, jobject obj, jobject identity)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->identityOperation(MC_FROM_JAVA(IMAPIdentity, identity)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_connectOperation
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->connectOperation());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_checkAccountOperation
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->checkAccountOperation());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_disconnectOperation
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->disconnectOperation());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_capabilityOperation
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->capabilityOperation());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_quotaOperation
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->quotaOperation());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_noopOperation
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->noopOperation());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_htmlRenderingOperation
  (JNIEnv * env, jobject obj, jobject msg, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->htmlRenderingOperation(MC_FROM_JAVA(IMAPMessage, msg), MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_htmlBodyRenderingOperation
  (JNIEnv * env, jobject obj, jobject msg, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->htmlBodyRenderingOperation(MC_FROM_JAVA(IMAPMessage, msg), MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_plainTextRenderingOperation
  (JNIEnv * env, jobject obj, jobject msg, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->plainTextRenderingOperation(MC_FROM_JAVA(IMAPMessage, msg), MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSession_plainTextBodyRenderingOperation
  (JNIEnv * env, jobject obj, jobject msg, jstring path, jboolean stripWhitespace)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->plainTextBodyRenderingOperation(MC_FROM_JAVA(IMAPMessage, msg), MC_FROM_JAVA(String, path), (bool) stripWhitespace));
    MC_POOL_END;
    return result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPSession_finalizeNative
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

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPSession_setupNativeOperationQueueListener
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

JNIEXPORT void JNICALL Java_com_libmailcore_IMAPSession_setupNativeConnectionLogger
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
