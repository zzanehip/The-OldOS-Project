#include "com_libmailcore_IMAPFolderInfo.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPFolderInfo.h"

using namespace mailcore;

#define nativeType IMAPFolderInfo
#define javaType nativeType

MC_JAVA_SYNTHESIZE_SCALAR(jlong, uint32_t, setUidNext, uidNext)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, uint32_t, setUidValidity, uidValidity)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, uint64_t, setModSequenceValue, modSequenceValue)
MC_JAVA_SYNTHESIZE_SCALAR(jint, int, setMessageCount, messageCount)
MC_JAVA_SYNTHESIZE_SCALAR(jlong, uint32_t, setFirstUnseenUid, firstUnseenUid)
MC_JAVA_SYNTHESIZE_SCALAR(jboolean, bool, setAllowsNewPermanentFlags, allowsNewPermanentFlags)

MC_JAVA_BRIDGE
