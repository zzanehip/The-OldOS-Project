#include "com_libmailcore_Address.h"

#include "TypesUtils.h"
#include "JavaHandle.h"
#include "MCAddress.h"
#include "MCDefines.h"

using namespace mailcore;

#define nativeType Address
#define javaType nativeType

JNIEXPORT jobject JNICALL Java_com_libmailcore_Address_addressWithDisplayName
  (JNIEnv * env, jclass cls, jstring displayName, jstring mailbox)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Address::addressWithDisplayName(MC_FROM_JAVA(String, displayName),
        MC_FROM_JAVA(String, mailbox)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Address_addressWithMailbox
  (JNIEnv * env, jclass cls, jstring mailbox)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Address::addressWithMailbox(MC_FROM_JAVA(String, mailbox)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Address_addressWithRFC822String
  (JNIEnv * env, jclass cls, jstring rfc822String)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Address::addressWithRFC822String(MC_FROM_JAVA(String, rfc822String)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Address_addressWithNonEncodedRFC822String
  (JNIEnv * env, jclass cls, jstring rfc822String)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Address::addressWithNonEncodedRFC822String(MC_FROM_JAVA(String, rfc822String)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Address_addressesWithRFC822String
  (JNIEnv * env, jclass cls, jstring rfc822String)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Address::addressesWithRFC822String(MC_FROM_JAVA(String, rfc822String)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_Address_addressesWithNonEncodedRFC822String
  (JNIEnv * env, jclass cls, jstring rfc822String)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(Address::addressesWithNonEncodedRFC822String(MC_FROM_JAVA(String, rfc822String)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_Address_RFC822StringForAddresses
  (JNIEnv * env, jclass cls, jobject addresses)
{
    MC_POOL_BEGIN;
    jobject result = (jstring) MC_TO_JAVA(Address::RFC822StringForAddresses(MC_FROM_JAVA(Array, addresses)));
    MC_POOL_END;
    return (jstring) result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_Address_nonEncodedRFC822StringForAddresses
  (JNIEnv * env, jclass cls, jobject addresses)
{
    MC_POOL_BEGIN;
    jobject result = (jstring) MC_TO_JAVA(Address::nonEncodedRFC822StringForAddresses(MC_FROM_JAVA(Array, addresses)));
    MC_POOL_END;
    return (jstring) result;
}

MC_JAVA_SYNTHESIZE_STRING(setDisplayName, displayName)
MC_JAVA_SYNTHESIZE_STRING(setMailbox, mailbox)

JNIEXPORT jstring JNICALL Java_com_libmailcore_Address_RFC822String
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jstring result = MC_JAVA_BRIDGE_GET_STRING(RFC822String);
    MC_POOL_END;
    return result;
}

JNIEXPORT jstring JNICALL Java_com_libmailcore_Address_nonEncodedRFC822String
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jstring result = MC_JAVA_BRIDGE_GET_STRING(nonEncodedRFC822String);
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
