#include "com_libmailcore_IMAPFolderStatus.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPFolderStatus.h"

using namespace mailcore;

#define nativeType IMAPFolderStatus
#define javaType nativeType

MC_JAVA_SYNTHESIZE_SCALAR(jlong, uint32_t, setUnseenCount, unseenCount)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, uint32_t, setMessageCount, messageCount)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, uint32_t, setRecentCount, recentCount)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, uint32_t, setUidNext, uidNext)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, uint32_t, setUidValidity, uidValidity)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, uint64_t, setHighestModSeqValue, highestModSeqValue)

MC_JAVA_BRIDGE
