#include "com_libmailcore_AbstractMessagePart.h"

#include "TypesUtils.h"
#include "JavaHandle.h"
#include "MCMessageHeader.h"
#include "MCAbstractMessagePart.h"

using namespace mailcore;

#define nativeType AbstractMessagePart
#define javaType nativeType

MC_JAVA_SYNTHESIZE(MessageHeader, setHeader, header)
MC_JAVA_SYNTHESIZE(AbstractPart, setMainPart, mainPart)
