#include  "com_libmailcore_Log.h"

#include "MCLog.h"

JNIEXPORT void JNICALL Java_com_libmailcore_Log_setEnabled
  (JNIEnv * env, jclass cls, jboolean enabled)
{
    MCLogEnabled = true;
}

JNIEXPORT jboolean JNICALL Java_com_libmailcore_Log_isEnabled
  (JNIEnv * env, jclass cls)
{
    return MCLogEnabled;
}
