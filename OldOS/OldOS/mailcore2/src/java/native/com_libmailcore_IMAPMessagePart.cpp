#include "com_libmailcore_IMAPMessagePart.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPMessagePart.h"

using namespace mailcore;

#define nativeType IMAPMessagePart
#define javaType nativeType

MC_JAVA_SYNTHESIZE_STRING(setPartID, partID)

MC_JAVA_BRIDGE
