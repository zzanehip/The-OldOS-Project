#include "com_libmailcore_IMAPPart.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPPart.h"

using namespace mailcore;

#define nativeType IMAPPart
#define javaType nativeType

MC_JAVA_SYNTHESIZE_STRING(setPartID, partID)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, unsigned int, setSize, size)
MC_JAVA_SYNTHESIZE_SCALAR(jint, Encoding, setEncoding, encoding)

JNIEXPORT jlong JNICALL Java_com_libmailcore_IMAPPart_decodedSize
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jlong result = MC_JAVA_BRIDGE_GET_SCALAR(jlong, decodedSize);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
