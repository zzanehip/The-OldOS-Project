#include "com_libmailcore_IMAPNamespaceItem.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPNamespaceItem.h"

using namespace mailcore;

#define nativeType IMAPNamespaceItem
#define javaType nativeType

MC_JAVA_SYNTHESIZE_STRING(setPrefix, prefix)
MC_JAVA_SYNTHESIZE_SCALAR(jchar, char, setDelimiter, delimiter)
    
JNIEXPORT jstring JNICALL Java_com_libmailcore_IMAPNamespaceItem_pathForComponents
  (JNIEnv * env, jobject obj, jobject components)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->pathForComponents(MC_FROM_JAVA(Array, components)));
    MC_POOL_END;
    return (jstring) result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPNamespaceItem_componentsForPath
  (JNIEnv * env, jobject obj, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->componentsForPath(MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jboolean JNICALL Java_com_libmailcore_IMAPNamespaceItem_containsFolder
  (JNIEnv * env, jobject obj, jstring path)
{
    MC_POOL_BEGIN;
    jboolean result = (jboolean) MC_JAVA_NATIVE_INSTANCE->containsFolder(MC_FROM_JAVA(String, path));
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
