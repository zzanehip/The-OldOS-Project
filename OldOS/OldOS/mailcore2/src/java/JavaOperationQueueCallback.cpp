#include "JavaOperationQueueCallback.h"

using namespace mailcore;

JavaOperationQueueCallback::JavaOperationQueueCallback(JNIEnv * env, jobject listener)
{
    mListener = listener;
    mEnv = env;
}

void JavaOperationQueueCallback::queueStartRunning()
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mListener);
    jmethodID mid = mEnv->GetMethodID(cls, "queueStartRunning", "()V");
    mEnv->CallVoidMethod(mListener, mid);
}

void JavaOperationQueueCallback::queueStoppedRunning()
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mListener);
    jmethodID mid = mEnv->GetMethodID(cls, "queueStoppedRunning", "()V");
    mEnv->CallVoidMethod(mListener, mid);
}
