#include "com_libmailcore_MessageParser.h"

#include "TypesUtils.h"
#include "JavaHandle.h"
#include "MCMessageParser.h"
#include "MCDefines.h"
#include "JavaHTMLRendererTemplateCallback.h"

using namespace mailcore;

#define nativeType MessageParser
#define javaType nativeType

JNIEXPORT jobject JNICALL Java_com_libmailcore_MessageParser_messageParserWithData
  (JNIEnv * env, jclass cls, jbyteArray data)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MessageParser::messageParserWithData(MC_FROM_JAVA(Data, data)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_MessageParser_messageParserWithContentsOfFile
  (JNIEnv * env, jclass cls, jstring filename)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MessageParser::messageParserWithContentsOfFile(MC_FROM_JAVA(String, filename)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_MessageParser_mainPart
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(mainPart);
    MC_POOL_END;
    return result;
}

JNIEXPORT jbyteArray JNICALL Java_com_libmailcore_MessageParser_data
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jbyteArray result = MC_JAVA_BRIDGE_GET_DATA(data);
    MC_POOL_END;
    return result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_MessageParser_htmlRendering
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

JNIEXPORT jstring JNICALL Java_com_libmailcore_MessageParser_htmlBodyRendering
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    return MC_JAVA_BRIDGE_GET_STRING(htmlBodyRendering);
    MC_POOL_END;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_MessageParser_plainTextRendering
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    return MC_JAVA_BRIDGE_GET_STRING(plainTextRendering);
    MC_POOL_END;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_MessageParser_plainTextBodyRendering
  (JNIEnv * env, jobject obj, jboolean stripWhitespace)
{
    MC_POOL_BEGIN;
    return (jstring) MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->plainTextBodyRendering((bool) stripWhitespace));
    MC_POOL_END;
}

MC_JAVA_BRIDGE
