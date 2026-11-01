#include "com_libmailcore_Attachment.h"

#include "TypesUtils.h"
#include "JavaHandle.h"
#include "MCAttachment.h"
#include "MCDefines.h"

using namespace mailcore;

#define nativeType Attachment
#define javaType nativeType

JNIEXPORT jstring JNICALL Java_com_libmailcore_Attachment_mimeTypeForFilename
  (JNIEnv * env, jclass javaClass, jstring filename)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Attachment::mimeTypeForFilename(MC_FROM_JAVA(String, filename)));
    MC_POOL_END;
    return (jstring) result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Attachment_attachmentWithContentsOfFile
  (JNIEnv * env, jclass javaClass, jstring filename)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Attachment::attachmentWithContentsOfFile(MC_FROM_JAVA(String, filename)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Attachment_attachmentWithData
  (JNIEnv * env, jclass javaClass, jstring filename, jbyteArray data)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Attachment::attachmentWithData(MC_FROM_JAVA(String, filename), MC_FROM_JAVA(Data, data)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Attachment_attachmentWithHTMLString
  (JNIEnv * env, jclass javaClass, jstring htmlString)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Attachment::attachmentWithHTMLString(MC_FROM_JAVA(String, htmlString)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Attachment_attachmentWithRFC822Message
  (JNIEnv * env, jclass javaClass, jbyteArray data)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Attachment::attachmentWithRFC822Message(MC_FROM_JAVA(Data, data)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Attachment_attachmentWithText
  (JNIEnv * env, jclass javaClass, jstring text)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Attachment::attachmentWithText(MC_FROM_JAVA(String, text)));
    MC_POOL_END;
    return result;
}

MC_JAVA_SYNTHESIZE_DATA(setData, data)

JNIEXPORT jstring JNICALL Java_com_libmailcore_Attachment_decodedString
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jstring result = MC_JAVA_BRIDGE_GET_STRING(decodedString);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
