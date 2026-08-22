#include "JavaConnectionLogger.h"

#include "TypesUtils.h"

using namespace mailcore;

JavaConnectionLogger::JavaConnectionLogger(JNIEnv * env, jobject logger)
{
    mLogger = logger;
    mEnv = env;
}

void JavaConnectionLogger::log(void * sender, ConnectionLogType logType, Data * buffer)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mLogger);
    jmethodID mid = mEnv->GetMethodID(cls, "log", "(JI[B)V");
    mEnv->CallVoidMethod(mLogger, mid, (jlong) sender, (jint) logType, MC_TO_JAVA(buffer));
}
