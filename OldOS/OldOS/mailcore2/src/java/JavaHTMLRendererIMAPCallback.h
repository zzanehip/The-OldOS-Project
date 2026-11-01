#ifndef MAILCORE_JAVA_HTML_RENDERER_IMAP_CALLBACK_H

#define MAILCORE_JAVA_HTML_RENDERER_IMAP_CALLBACK_H

#include <jni.h>

#include "MCBaseTypes.h"
#include "MCHTMLRendererCallback.h"

namespace mailcore {

class JavaHTMLRendererIMAPCallback : public Object, public HTMLRendererIMAPCallback {
public:
    JavaHTMLRendererIMAPCallback(JNIEnv * env, jobject callback);
    
    virtual Data * dataForIMAPPart(String * folder, IMAPPart * part);
    virtual void prefetchAttachmentIMAPPart(String * folder, IMAPPart * part);
    virtual void prefetchImageIMAPPart(String * folder, IMAPPart * part);
    
private:
    jobject mCallback;
    JNIEnv * mEnv;
};

}

#endif
