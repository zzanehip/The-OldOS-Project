#include "com_libmailcore_IndexSet.h"

#include "TypesUtils.h"
#include "JavaHandle.h"
#include "MCDefines.h"
#include "MCIndexSet.h"

using namespace mailcore;

#define nativeType IndexSet
#define javaType nativeType

JNIEXPORT jobject JNICALL Java_com_libmailcore_IndexSet_indexSet
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IndexSet::indexSet());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IndexSet_indexSetWithRange
  (JNIEnv * env, jclass cls, jobject range)
{
    MC_POOL_BEGIN;
    Range mcRange = rangeFromJava(env, range);
    jobject result = MC_TO_JAVA(IndexSet::indexSetWithRange(mcRange));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IndexSet_indexSetWithIndex
  (JNIEnv * env, jclass cls, jlong idx)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IndexSet::indexSetWithIndex((uint64_t) idx));
    MC_POOL_END;
    return result;
}

JNIEXPORT jint JNICALL Java_com_libmailcore_IndexSet_count
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jint result = MC_JAVA_BRIDGE_GET_SCALAR(jint, count);
    MC_POOL_END;
    return result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IndexSet_addIndex
  (JNIEnv * env, jobject obj, jlong idx)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->addIndex((uint64_t) idx);
    MC_POOL_END;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IndexSet_removeIndex
  (JNIEnv * env, jobject obj, jlong idx)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->removeIndex((uint64_t) idx);
    MC_POOL_END;
}

JNIEXPORT jboolean JNICALL Java_com_libmailcore_IndexSet_containsIndex
  (JNIEnv * env, jobject obj, jlong idx)
{
    MC_POOL_BEGIN;
    jboolean result = (jboolean) MC_JAVA_NATIVE_INSTANCE->containsIndex((uint64_t) idx);
    MC_POOL_END;
    return result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IndexSet_addRange
  (JNIEnv * env, jobject obj, jobject range)
{
    MC_POOL_BEGIN;
    Range mcRange = rangeFromJava(env, range);
    MC_JAVA_NATIVE_INSTANCE->addRange(mcRange);
    MC_POOL_END;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IndexSet_removeRange
  (JNIEnv * env, jobject obj, jobject range)
{
    MC_POOL_BEGIN;
    Range mcRange = rangeFromJava(env, range);
    MC_JAVA_NATIVE_INSTANCE->removeRange(mcRange);
    MC_POOL_END;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IndexSet_intersectsRange
  (JNIEnv * env, jobject obj, jobject range)
{
    MC_POOL_BEGIN;
    Range mcRange = rangeFromJava(env, range);
    MC_JAVA_NATIVE_INSTANCE->intersectsRange(mcRange);
    MC_POOL_END;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IndexSet_addIndexSet
  (JNIEnv * env, jobject obj, jobject otherIndexSet)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->addIndexSet(MC_FROM_JAVA(IndexSet, otherIndexSet));
    MC_POOL_END;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IndexSet_removeIndexSet
  (JNIEnv * env, jobject obj, jobject otherIndexSet)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->removeIndexSet(MC_FROM_JAVA(IndexSet, otherIndexSet));
    MC_POOL_END;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IndexSet_intersectsIndexSet
  (JNIEnv * env, jobject obj, jobject otherIndexSet)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->intersectsIndexSet(MC_FROM_JAVA(IndexSet, otherIndexSet));
    MC_POOL_END;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IndexSet_allRanges
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jclass cls = env->FindClass("java/util/Vector");
    jmethodID constructor = env->GetMethodID(cls, "<init>", "(I)V");
    unsigned int count = MC_JAVA_NATIVE_INSTANCE->rangesCount();
    jobject javaVector = env->NewObject(cls, constructor, count);
    jmethodID method = env->GetMethodID(cls, "add", "(Ljava/lang/Object;)Z");
    Range * ranges = MC_JAVA_NATIVE_INSTANCE->allRanges();
    for(unsigned int i = 0 ; i < count ; i ++) {
        jobject javaObject = rangeToJava(env, ranges[i]);
        env->CallBooleanMethod(javaVector, method, javaObject);
        env->DeleteLocalRef(javaObject);
    }
    MC_POOL_END;
    return javaVector;
}

JNIEXPORT jint JNICALL Java_com_libmailcore_IndexSet_rangesCount
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jint result = MC_JAVA_BRIDGE_GET_SCALAR(jint, rangesCount);
    MC_POOL_END;
    return result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_IndexSet_removeAllIndexes
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->removeAllIndexes();
    MC_POOL_END;
}

MC_JAVA_BRIDGE
