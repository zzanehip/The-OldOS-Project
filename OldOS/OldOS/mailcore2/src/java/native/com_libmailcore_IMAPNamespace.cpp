#include "com_libmailcore_IMAPNamespace.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPNamespace.h"

using namespace mailcore;

#define nativeType IMAPNamespace
#define javaType nativeType

JNIEXPORT jstring JNICALL Java_com_libmailcore_IMAPNamespace_mainPrefix
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jstring result = MC_JAVA_BRIDGE_GET_STRING(mainPrefix);
    MC_POOL_END;
    return result;
}

JNIEXPORT jchar JNICALL Java_com_libmailcore_IMAPNamespace_mainDelimiter
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jchar result = MC_JAVA_BRIDGE_GET_SCALAR(jchar, mainDelimiter);
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPNamespace_prefixes
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_JAVA_BRIDGE_GET(prefixes);
    MC_POOL_END;
    return result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_IMAPNamespace_pathForComponents
  (JNIEnv * env, jobject obj, jobject components)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->pathForComponents(MC_FROM_JAVA(Array, components)));
    MC_POOL_END;
    return (jstring) result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_IMAPNamespace_pathForComponentsAndPrefix
  (JNIEnv * env, jobject obj, jobject components, jstring prefix)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->pathForComponentsAndPrefix(MC_FROM_JAVA(Array, components),
        MC_FROM_JAVA(String, prefix)));
    MC_POOL_END;
    return (jstring) result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPNamespace_componentsFromPath
  (JNIEnv * env, jobject obj, jstring path)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(MC_JAVA_NATIVE_INSTANCE->componentsFromPath(MC_FROM_JAVA(String, path)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jboolean JNICALL Java_com_libmailcore_IMAPNamespace_containsFolderPath
  (JNIEnv * env, jobject obj, jstring path)
{
    MC_POOL_BEGIN;
    jboolean result = (jboolean) MC_JAVA_NATIVE_INSTANCE->containsFolderPath(MC_FROM_JAVA(String, path));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPNamespace_namespaceWithPrefix
  (JNIEnv * env, jclass cls, jstring prefix, jchar delimiter)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPNamespace::namespaceWithPrefix(MC_FROM_JAVA(String, prefix), (char) delimiter));
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
