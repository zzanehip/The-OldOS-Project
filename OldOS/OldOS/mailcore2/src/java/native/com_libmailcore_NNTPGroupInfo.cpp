#include "com_libmailcore_NNTPGroupInfo.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCNNTPGroupInfo.h"

using namespace mailcore;

#define nativeType NNTPGroupInfo
#define javaType nativeType

MC_JAVA_SYNTHESIZE_STRING(setName, name)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, uint32_t, setMessageCount, messageCount)

MC_JAVA_BRIDGE
