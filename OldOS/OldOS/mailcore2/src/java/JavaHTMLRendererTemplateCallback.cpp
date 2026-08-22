#include "JavaHTMLRendererTemplateCallback.h"

#include "TypesUtils.h"

using namespace mailcore;

bool JavaHTMLRendererTemplateCallback::canPreviewPart(AbstractPart * part)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "canPreviewPart", "(Lcom/libmailcore/AbstractPart;)Z");
    return (bool) mEnv->CallBooleanMethod(mCallback, mid, MC_TO_JAVA(part));
}
    
bool JavaHTMLRendererTemplateCallback::shouldShowPart(AbstractPart * part)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "shouldShowPart", "(Lcom/libmailcore/AbstractPart;)Z");
    return (bool) mEnv->CallBooleanMethod(mCallback, mid, MC_TO_JAVA(part));
}
    
HashMap * JavaHTMLRendererTemplateCallback::templateValuesForHeader(MessageHeader * header)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "templateValuesForHeader", "(Lcom/libmailcore/MessageHeader;)Ljava/util/Map;");
    return MC_FROM_JAVA(HashMap, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(header)));
}
    
HashMap * JavaHTMLRendererTemplateCallback::templateValuesForPart(AbstractPart * part)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "templateValuesForPart", "(Lcom/libmailcore/AbstractPart;)Ljava/util/Map;");
    return MC_FROM_JAVA(HashMap, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(part)));
}
    
String * JavaHTMLRendererTemplateCallback::templateForMainHeader(MessageHeader * header)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "templateForMainHeader", "(Lcom/libmailcore/MessageHeader;)Ljava/lang/String;");
    return MC_FROM_JAVA(String, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(header)));
}
    
String * JavaHTMLRendererTemplateCallback::templateForImage(AbstractPart * part)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "templateForImage", "(Lcom/libmailcore/AbstractPart;)Ljava/lang/String;");
    return MC_FROM_JAVA(String, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(part)));
}
    
String * JavaHTMLRendererTemplateCallback::templateForAttachment(AbstractPart * part)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "templateForAttachment", "(Lcom/libmailcore/AbstractPart;)Ljava/lang/String;");
    return MC_FROM_JAVA(String, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(part)));
}
    
String * JavaHTMLRendererTemplateCallback::templateForMessage(AbstractMessage * message)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "templateForMessage", "(Lcom/libmailcore/AbstractMessage;)Ljava/lang/String;");
    return MC_FROM_JAVA(String, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(message)));
}
    
String * JavaHTMLRendererTemplateCallback::templateForEmbeddedMessage(AbstractMessagePart * part)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "templateForEmbeddedMessage", "(Lcom/libmailcore/AbstractMessagePart;)Ljava/lang/String;");
    return MC_FROM_JAVA(String, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(part)));
}
    
String * JavaHTMLRendererTemplateCallback::templateForEmbeddedMessageHeader(MessageHeader * header)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "templateForEmbeddedMessageHeader", "(Lcom/libmailcore/MessageHeader;)Ljava/lang/String;");
    return MC_FROM_JAVA(String, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(header)));
}
    
String * JavaHTMLRendererTemplateCallback::templateForAttachmentSeparator()
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "templateForAttachmentSeparator", "()Ljava/lang/String;");
    return MC_FROM_JAVA(String, mEnv->CallObjectMethod(mCallback, mid));
}
    
String * JavaHTMLRendererTemplateCallback::cleanHTMLForPart(String * html)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "cleanHTMLForPart", "(Ljava/lang/String;)Ljava/lang/String;");
    return MC_FROM_JAVA(String, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(html)));
}

String * JavaHTMLRendererTemplateCallback::filterHTMLForPart(String * html)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "filterHTMLForPart", "(Ljava/lang/String;)Ljava/lang/String;");
    return MC_FROM_JAVA(String, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(html)));
}
    
String * JavaHTMLRendererTemplateCallback::filterHTMLForMessage(String * html)
{
    JNIEnv * env = mEnv;
    jclass cls = mEnv->GetObjectClass(mCallback);
    jmethodID mid = mEnv->GetMethodID(cls, "filterHTMLForMessage", "(Ljava/lang/String;)Ljava/lang/String;");
    return MC_FROM_JAVA(String, mEnv->CallObjectMethod(mCallback, mid, MC_TO_JAVA(html)));
}
    
JavaHTMLRendererTemplateCallback::JavaHTMLRendererTemplateCallback(JNIEnv * env, jobject callback)
{
    mCallback = callback;
    mEnv = env;
}
