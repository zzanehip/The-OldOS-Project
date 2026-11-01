#include "com_libmailcore_POPMessageInfo.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCPOPMessageInfo.h"

using namespace mailcore;

#define nativeType POPMessageInfo
#define javaType nativeType

MC_JAVA_SYNTHESIZE_SCALAR(jint, unsigned int, setIndex, index)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, unsigned int, setSize, size)
MC_JAVA_SYNTHESIZE_STRING(setUid, uid)

MC_JAVA_BRIDGE
