#include "com_libmailcore_MessageBuilder.h"

#include "TypesUtils.h"
#include "JavaHandle.h"
#include "MCMessageBuilder.h"
#include "MCDefines.h"
#include "JavaHTMLRendererTemplateCallback.h"

using namespace mailcore;

#define nativeType MessageBuilder
#define javaType nativeType

MC_JAVA_SYNTHESIZE_STRING(setHTMLBody, htmlBody)
MC_JAVA_SYNTHESIZE_STRING(setTextBody, textBody)
MC_JAVA_SYNTHESIZE(Array, setAttachments, attachments)

JNIEXPORT void JNICALL Java_com_libmailcore_MessageBuilder_addAttachment
    (JNIEnv * env, jobject obj, jobject attachment)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->addAttachment(MC_FROM_JAVA(Attachment, attachment));
    MC_POOL_END;
}

MC_JAVA_SYNTHESIZE(Array, setRelatedAttachments, relatedAttachments)

JNIEXPORT void JNICALL Java_com_libmailcore_MessageBuilder_addRelatedAttachment
    (JNIEnv * env, jobject obj, jobject attachment)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->addRelatedAttachment(MC_FROM_JAVA(Attachment, attachment));
    MC_POOL_END;
}

MC_JAVA_SYNTHESIZE_STRING(setBoundaryPrefix, boundaryPrefix)

JNIEXPORT jbyteArray JNICALL Java_com_libmailcore_MessageBuilder_data
    (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jbyteArray result = MC_JAVA_BRIDGE_GET_DATA(data);
    MC_POOL_END;
    return result;
}

JNIEXPORT jbyteArray JNICALL Java_com_libmailcore_MessageBuilder_dataForEncryption
    (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jbyteArray result = MC_JAVA_BRIDGE_GET_DATA(dataForEncryption);
    MC_POOL_END;
    return result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_MessageBuilder_htmlRendering
    (JNIEnv * env, jobject obj, jobject javaCallback)
{
    MC_POOL_BEGIN;
    JavaHTMLRendererTemplateCallback * callback = NULL;
    if (javaCallback != NULL) {
        callback = new JavaHTMLRendererTemplateCallback(env, javaCallback);
    }
    jstring result = (jstring) MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->htmlRendering(callback));
    if (callback != NULL) {
        delete callback;
    }
    MC_POOL_END;
    return result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_MessageBuilder_htmlBodyRendering
    (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jstring result = MC_JAVA_BRIDGE_GET_STRING(htmlBodyRendering);
    MC_POOL_END;
    return result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_MessageBuilder_plainTextRendering
    (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jstring result = MC_JAVA_BRIDGE_GET_STRING(plainTextRendering);
    MC_POOL_END;
    return result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_MessageBuilder_plainTextBodyRendering
    (JNIEnv * env, jobject obj, jboolean stripWhitespace)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->plainTextBodyRendering((bool) stripWhitespace));
    MC_POOL_END;
    return (jstring) result;
}

JNIEXPORT jbyteArray JNICALL Java_com_libmailcore_MessageBuilder_openPGPSignedMessageDataWithSignatureData
    (JNIEnv * env, jobject obj, jbyteArray signature)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->openPGPSignedMessageDataWithSignatureData(MC_FROM_JAVA(Data, signature)));
    MC_POOL_END;
    return (jbyteArray) result;
}

JNIEXPORT jbyteArray JNICALL Java_com_libmailcore_MessageBuilder_openPGPEncryptedMessageDataWithEncryptedData
    (JNIEnv * env, jobject obj, jbyteArray encryptedData)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->openPGPEncryptedMessageDataWithEncryptedData(MC_FROM_JAVA(Data, encryptedData)));
    MC_POOL_END;
    return (jbyteArray) result;
}

MC_JAVA_BRIDGE
