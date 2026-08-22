#ifndef MAILCORE_JAVA_CONNECTION_LOGGER_H

#define MAILCORE_JAVA_CONNECTION_LOGGER_H

#include <jni.h>
#include "MCConnectionLogger.h"
#include "MCBaseTypes.h"

namespace mailcore {

class JavaConnectionLogger : public Object, public ConnectionLogger {
public:
    JavaConnectionLogger(JNIEnv * env, jobject logger);
    
    virtual void log(void * sender, ConnectionLogType logType, Data * buffer);
    
private:
    jobject mLogger;
    JNIEnv * mEnv;
};

}

#endif
