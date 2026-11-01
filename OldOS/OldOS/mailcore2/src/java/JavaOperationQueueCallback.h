#ifndef MAILCORE_JAVA_OPERATION_QUEUE_CALLBACK_H

#define MAILCORE_JAVA_OPERATION_QUEUE_CALLBACK_H

#include <jni.h>
#include "MCBaseTypes.h"
#include "MCOperationQueueCallback.h"

namespace mailcore {

class JavaOperationQueueCallback : public Object, public OperationQueueCallback {
public:
    JavaOperationQueueCallback(JNIEnv * env, jobject listener);
    
    virtual void queueStartRunning();
    virtual void queueStoppedRunning();
    
private:
    jobject mListener;
    JNIEnv * mEnv;
};

}

#endif
