#include "com_libmailcore_IMAPSearchExpression.h"

#include "MCBaseTypes.h"
#include "JavaHandle.h"
#include "TypesUtils.h"
#include "MCIMAPSearchExpression.h"

using namespace mailcore;

#define nativeType IMAPSearchExpression
#define javaType nativeType

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchAll
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchAll());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchFrom
  (JNIEnv * env, jclass cls, jstring value)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchFrom(MC_FROM_JAVA(String, value)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchTo
  (JNIEnv * env, jclass cls, jstring value)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchTo(MC_FROM_JAVA(String, value)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchCc
  (JNIEnv * env, jclass cls, jstring value)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchCc(MC_FROM_JAVA(String, value)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchBcc
  (JNIEnv * env, jclass cls, jstring value)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchBcc(MC_FROM_JAVA(String, value)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchRecipient
  (JNIEnv * env, jclass cls, jstring value)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchRecipient(MC_FROM_JAVA(String, value)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchSubject
  (JNIEnv * env, jclass cls, jstring value)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchSubject(MC_FROM_JAVA(String, value)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchContent
  (JNIEnv * env, jclass cls, jstring value)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchContent(MC_FROM_JAVA(String, value)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchBody
  (JNIEnv * env, jclass cls, jstring value)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchBody(MC_FROM_JAVA(String, value)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchHeader
  (JNIEnv * env, jclass cls, jstring header, jstring value)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchHeader(MC_FROM_JAVA(String, header), MC_FROM_JAVA(String, value)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchUIDs
  (JNIEnv * env, jclass cls, jobject uids)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchUIDs(MC_FROM_JAVA(IndexSet, uids)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchRead
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchRead());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchUnread
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchUnread());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchFlagged
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchFlagged());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchUnflagged
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchUnflagged());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchAnswered
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchAnswered());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchUnanswered
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchUnanswered());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchDraft
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchDraft());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchUndraft
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchUndraft());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchDeleted
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchDeleted());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchSpam
  (JNIEnv * env, jclass cls)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchSpam());
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchBeforeDate
  (JNIEnv * env, jclass cls, jobject date)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchBeforeDate(javaDateToTime(env, date)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchOnDate
  (JNIEnv * env, jclass cls, jobject date)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchOnDate(javaDateToTime(env, date)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchSinceDate
  (JNIEnv * env, jclass cls, jobject date)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchSinceDate(javaDateToTime(env, date)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchBeforeReceivedDate
  (JNIEnv * env, jclass cls, jobject date)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchBeforeDate(javaDateToTime(env, date)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchOnReceivedDate
  (JNIEnv * env, jclass cls, jobject date)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchOnReceivedDate(javaDateToTime(env, date)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchSinceReceivedDate
  (JNIEnv * env, jclass cls, jobject date)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchSinceReceivedDate(javaDateToTime(env, date)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchSizeLarger
  (JNIEnv * env, jclass cls, jlong size)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchSizeLarger((uint32_t) size));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchSizeSmaller
  (JNIEnv * env, jclass cls, jlong size)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchSizeSmaller((uint32_t) size));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchGmailThreadID
  (JNIEnv * env, jclass cls, jlong threadID)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchGmailThreadID((uint64_t) threadID));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchGmailMessageID
  (JNIEnv * env, jclass cls, jlong messageID)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchGmailMessageID((uint64_t) messageID));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchGmailRaw
  (JNIEnv * env, jclass cls, jstring searchString)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchGmailRaw(MC_FROM_JAVA(String, searchString)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchAnd
  (JNIEnv * env, jclass cls, jobject expr1, jobject expr2)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchAnd(MC_FROM_JAVA(IMAPSearchExpression, expr1), MC_FROM_JAVA(IMAPSearchExpression, expr2)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchOr
  (JNIEnv * env, jclass cls, jobject expr1, jobject expr2)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchOr(MC_FROM_JAVA(IMAPSearchExpression, expr1), MC_FROM_JAVA(IMAPSearchExpression, expr2)));
    MC_POOL_END;
    return result;
}

JNIEXPORT jobject JNICALL Java_com_libmailcore_IMAPSearchExpression_searchNot
  (JNIEnv * env, jclass cls, jobject expr)
{
    MC_POOL_BEGIN;
    jobject result = MC_TO_JAVA(IMAPSearchExpression::searchNot(MC_FROM_JAVA(IMAPSearchExpression, expr)));
    MC_POOL_END;
    return result;
}

MC_JAVA_BRIDGE
