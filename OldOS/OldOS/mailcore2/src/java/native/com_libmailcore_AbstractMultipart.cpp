#include "com_libmailcore_AbstractMultipart.h"

#include "TypesUtils.h"
#include "JavaHandle.h"
#include "MCAbstractMultipart.h"

using namespace mailcore;

#define nativeType AbstractMultipart
#define javaType nativeType

MC_JAVA_SYNTHESIZE(Array, setParts, parts)
