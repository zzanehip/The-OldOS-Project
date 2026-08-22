#include "JavaHTMLRendererIMAPCallback.h"

#include "TypesUtils.h"

using namespace mailcore;

JavaHTMLRendererIMAPCallback::JavaHTMLRendererIMAPCallback(JNIEnv * env, jobject callback)
{
    mCallback = callback;
    mEnv = env;
}

Data * JavaHTMLRendererIMAPCallback::dataForIMAPPart(String * folder, IMAPPart * part)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "dataForIMAPPart", "(Ljava/lang/String;Lcom/libmailcore/IMAPPart;)[B");
    return MC_FROM_JAVA(Data, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(folder), MC_TO_JAVA(part)));
}

void JavaHTMLRendererIMAPCallback::prefetchAttachmentIMAPPart(String * folder, IMAPPart * part)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "prefetchAttachmentIMAPPart", "(Ljava/lang/String;Lcom/libmailcore/IMAPPart;)V");
    mEnv->CallVoidMethod(mCallback, mid, MC_TO_JAVA(folder), MC_TO_JAVA(part));
}

void JavaHTMLRendererIMAPCallback::prefetchImageIMAPPart(String * folder, IMAPPart * part)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "prefetchImageIMAPPart", "(Ljava/lang/String;Lcom/libmailcore/IMAPPart;)V");
    mEnv->CallVoidMethod(mCallback, mid, MC_TO_JAVA(folder), MC_TO_JAVA(part));
}
