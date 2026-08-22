#include "com_libmailcore_IMAPMultipart.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPMultipart.h"

using namespace mailcore;

#define nativeType IMAPMultipart
#define javaType nativeType

MC_JAVA_SYNTHESIZE_STRING(setPartID, partID)

MC_JAVA_BRIDGE
