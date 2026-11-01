#include "com_libmailcore_AbstractMessage.h"

#include "TypesUtils.h"
#include "JavaHandle.h"
#include "MCAbstractMessage.h"
#include "MCAbstractPart.h"
#include "MCMessageHeader.h"

using namespace mailcore;

#define nativeType AbstractMessage
#define javaType nativeType

MC_JAVA_SYNTHESIZE(MessageHeader, setHeader, header)

JNIEXPORT jobject JNICALL Java_com_libmailcore_AbstractMessage_partForContentID
  (JNIEnv * env, jobject obj, jstring contentID)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->partForContentID(MC_FROM_JAVA(String, contentID)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_AbstractMessage_partForUniqueID
  (JNIEnv * env, jobject obj, jstring uniqueID)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->partForUniqueID(MC_FROM_JAVA(String, uniqueID)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_AbstractMessage_attachments
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(attachments);
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_AbstractMessage_htmlInlineAttachments
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(htmlInlineAttachments);
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_AbstractMessage_requiredPartsForRendering
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(requiredPartsForRendering);
    MC_POOL_END;
    return result;
}
