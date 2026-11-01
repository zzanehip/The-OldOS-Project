#include "com_libmailcore_Range.h"

#include "TypesUtils.h"
#include "JavaHandle.h"
#include "MCRange.h"
#include "MCDefines.h"

using namespace mailcore;

JNIEXPORT jobject JNICALL Java_com_libmailcore_Range_removeRange
  (JNIEnv * env, jobject obj, jobject range)
{
    MC_POOL_BEGIN;
    Range mcRange = rangeFromJava(env, obj);
    Range otherRange = rangeFromJava(env, range);
    jobject result = MC_TO_JAVA(RangeRemoveRange(mcRange, otherRange));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Range_union
  (JNIEnv * env, jobject obj, jobject range)
{
    MC_POOL_BEGIN;
    Range mcRange = rangeFromJava(env, obj);
    Range otherRange = rangeFromJava(env, range);
    jobject result = MC_TO_JAVA(RangeUnion(mcRange, otherRange));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Range_intersection
  (JNIEnv * env, jobject obj, jobject range)
{
    MC_POOL_BEGIN;
    Range mcRange = rangeFromJava(env, obj);
    Range otherRange = rangeFromJava(env, range);
    jobject result = rangeToJava(env, RangeIntersection(mcRange, otherRange));
    MC_POOL_END;
    return result;
}

JNIEXPORT jboolean JNICALL Java_com_libmailcore_Range_hasIntersection
  (JNIEnv * env, jobject obj, jobject range)
{
    MC_POOL_BEGIN;
    Range mcRange = rangeFromJava(env, obj);
    Range otherRange = rangeFromJava(env, range);
    jboolean result = (jboolean) RangeHasIntersection(mcRange, otherRange);
    MC_POOL_END;
    return result;
}

JNIEXPORT jlong JNICALL Java_com_libmailcore_Range_leftBound
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    Range mcRange = rangeFromJava(env, obj);
    jlong result = (jlong) RangeLeftBound(mcRange);
    MC_POOL_END;
    return result;
}

JNIEXPORT jlong JNICALL Java_com_libmailcore_Range_rightBound
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    Range mcRange = rangeFromJava(env, obj);
    jlong result = (jlong) RangeRightBound(mcRange);
    MC_POOL_END;
    return result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_Range_toString
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(RangeToString(rangeFromJava(env, obj)));
    MC_POOL_END;
    return (jstring) result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Range_rangeWithString
  (JNIEnv * env, jclass cls, jstring rangeString)
{
    MC_POOL_BEGIN;
    Range mcRange = RangeFromString(MC_FROM_JAVA(String, rangeString));
    jobject result = rangeToJava(env, mcRange);
    MC_POOL_END;
    return result;
}
