#include "JavaIMAPOperationCallback.h"

using namespace mailcore;

static bool isIMAPOperationProgressListener(JNIEnv * env, jobject obj)
{
    jclass cls = env->FindClass("com/libmailcore/IMAPOperationProgressListener");
    return env->IsInstanceOf(obj, cls);
}

static bool isIMAPOperationItemProgressListener(JNIEnv * env, jobject obj)
{
    jclass cls = env->FindClass("com/libmailcore/IMAPOperationItemProgressListener");
    return env->IsInstanceOf(obj, cls);
}

JavaIMAPOperationCallback::JavaIMAPOperationCallback(JNIEnv * env, jobject listener)
{
    mEnv = env;
    mListener = listener;
}

void JavaIMAPOperationCallback::bodyProgress(IMAPOperation * session, unsigned int current, unsigned int maximum)
{
    if (!isIMAPOperationProgressListener(mEnv, mListener)) {
        return;
    }

    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mListener);
    jmethodID mid = mEnv->GetMethodID(cls, "bodyProgress", "(JJ)V");
    mEnv->CallVoidMethod(mListener, mid, (jlong) current, (jlong) maximum);
}

void JavaIMAPOperationCallback::itemProgress(IMAPOperation * session, unsigned int current, unsigned int maximum)
{
    if (!isIMAPOperationItemProgressListener(mEnv, mListener)) {
        return;
    }

    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mListener);
    jmethodID mid = mEnv->GetMethodID(cls, "itemProgress", "(JJ)V");
    mEnv->CallVoidMethod(mListener, mid, (jlong) current, (jlong) maximum);
}
