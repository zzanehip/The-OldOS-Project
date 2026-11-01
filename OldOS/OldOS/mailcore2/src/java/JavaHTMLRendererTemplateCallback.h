#ifndef MAILCORE_JAVA_HTML_RENDERER_TEMPLATE_CALLBACK_H

#define MAILCORE_JAVA_HTML_RENDERER_TEMPLATE_CALLBACK_H

#include <jni.h>

#include "MCBaseTypes.h"
#include "MCHTMLRendererCallback.h"

namespace mailcore {

class JavaHTMLRendererTemplateCallback : public Object, public HTMLRendererTemplateCallback {
public:
    JavaHTMLRendererTemplateCallback(JNIEnv * env, jobject listener);
    
    virtual bool canPreviewPart(AbstractPart * part);
    virtual bool shouldShowPart(AbstractPart * part);
    virtual HashMap * templateValuesForHeader(MessageHeader * header);
    virtual HashMap * templateValuesForPart(AbstractPart * part);
    virtual String * templateForMainHeader(MessageHeader * header);
    virtual String * templateForImage(AbstractPart * part);
    virtual String * templateForAttachment(AbstractPart * part);
    virtual String * templateForMessage(AbstractMessage * message);
    virtual String * templateForEmbeddedMessage(AbstractMessagePart * part);
    virtual String * templateForEmbeddedMessageHeader(MessageHeader * header);
    virtual String * templateForAttachmentSeparator();
    virtual String * cleanHTMLForPart(String * html);
    virtual String * filterHTMLForPart(String * html);
    virtual String * filterHTMLForMessage(String * html);
    
private:
    jobject mCallback;
    JNIEnv * mEnv;
};

}

#endif
