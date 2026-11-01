#include "com_libmailcore_Operation.h"

#include "TypesUtils.h"
#include "JavaHandle.h"
#include "MCOperation.h"
#include "MCDefines.h"

using namespace mailcore;

#define nativeType Operation
#define javaType nativeType

class JavaOperationCallback : public Object, public OperationCallback {
public:
    JavaOperationCallback(JNIEnv * env, jobject obj) {
        mEnv = env;
        mGlobalRef = env->NewGlobalRef(obj);
    }
    
    virtual ~JavaOperationCallback() {
        if (mGlobalRef != NULL) {
            mEnv->DeleteGlobalRef(mGlobalRef);
            mGlobalRef = NULL;
        }
    }
    
    virtual void operationFinished(Operation * op)
    {
        jclass cls = mEnv->GetObjectClass(mGlobalRef);
        jmethodID mid = mEnv->GetMethodID(cls, "callCallback", "()V");
        mEnv->CallVoidMethod(mGlobalRef, mid);
        
        mEnv->DeleteGlobalRef(mGlobalRef);
        mGlobalRef = NULL;
        
        this->release();
    }
    
private:
    JNIEnv * mEnv;
    jobject mGlobalRef;
};

JNIEXPORT void JNICALL Java_com_libmailcore_Operation_cancel
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    MC_JAVA_NATIVE_INSTANCE->cancel();
    MC_POOL_END;
}

JNIEXPORT jboolean JNICALL Java_com_libmailcore_Operation_isCancelled
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    jboolean result = MC_JAVA_BRIDGE_GET_SCALAR(jboolean, isCancelled);
    MC_POOL_END;
    return result;
}

JNIEXPORT void JNICALL Java_com_libmailcore_Operation_nativeStart
  (JNIEnv * env, jobject obj)
{
    MC_POOL_BEGIN;
    JavaOperationCallback * callback = new JavaOperationCallback(env, obj);
    MC_JAVA_NATIVE_INSTANCE->setCallback(callback);
    MC_JAVA_NATIVE_INSTANCE->start();
    MC_POOL_END;
}

MC_JAVA_BRIDGE
