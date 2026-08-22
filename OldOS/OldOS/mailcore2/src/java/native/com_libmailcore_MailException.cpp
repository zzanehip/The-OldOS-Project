#include "com_libmailcore_MailException.h"

#include "MCBaseTypes.h"
#include "MCErrorMessage.h"
#include "TypesUtils.h"

using namespace mailcore;

JNIEXPORT jstring JNICALL Java_com_libmailcore_MailException_messageForErrorCode
  (JNIEnv * env, jclass cls, jint errorCode)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(mailcore::errorMessageWithErrorCode((ErrorCode) errorCode));
    MC_POOL_END;
    return (jstring) result;
}
