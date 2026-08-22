#include "com_libmailcore_IMAPFolder.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPFolder.h"

using namespace mailcore;

#define nativeType IMAPFolder
#define javaType nativeType

MC_JAVA_SYNTHESIZE_STRING(setPath, path)
MC_JAVA_SYNTHESIZE_SCALAR(jchar, char, setDelimiter, delimiter)
MC_JAVA_SYNTHESIZE_SCALAR(jint, IMAPFolderFlag, setFlags, flags)

MC_JAVA_BRIDGE
