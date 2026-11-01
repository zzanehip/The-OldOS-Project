#ifndef MAILCORE_JAVA_IMAP_OPERATION_CALLBACK_H

#define MAILCORE_JAVA_IMAP_OPERATION_CALLBACK_H

#include <jni.h>
#include "MCBaseTypes.h"
#include "MCIMAPOperationCallback.h"

#ifdef __cplusplus

namespace mailcore {
    
    class JavaIMAPOperationCallback : public Object, public IMAPOperationCallback {
    public:
        JavaIMAPOperationCallback(JNIEnv * env, jobject listener);
        
        virtual void bodyProgress(IMAPOperation * session, unsigned int current, unsigned int maximum);
        virtual void itemProgress(IMAPOperation * session, unsigned int current, unsigned int maximum);
        
    private:
        JNIEnv * mEnv;
        jobject mListener;
    };
    
}

#endif

#endif
