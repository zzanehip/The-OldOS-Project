#include "MCIMAPSearchExpression.h"

using namespace mailcore;

void IMAPSearchExpression::init()
{
    mKind = IMAPSearchKindNone;
    mHeader = NULL;
    mValue = NULL;
    mLongNumber = 0;
    mUids  = NULL;
    mNumbers = NULL;
    mLeftExpression = NULL;
    mRightExpression = NULL;
}

IMAPSearchExpression::IMAPSearchExpression()
{
    init();
}

IMAPSearchExpression::IMAPSearchExpression(IMAPSearchExpression * other)
{
    init();
    mKind = other->mKind;
    mLongNumber = other->mLongNumber;
    MC_SAFE_REPLACE_COPY(String, mHeader, other->mHeader);
    MC_SAFE_REPLACE_COPY(String, mValue, other->mValue);
    MC_SAFE_REPLACE_COPY(IndexSet, mUids, other->mUids);
    MC_SAFE_REPLACE_COPY(IndexSet, mNumbers, other->mNumbers);
    MC_SAFE_REPLACE_COPY(IMAPSearchExpression, mLeftExpression, other->mLeftExpression);
    MC_SAFE_REPLACE_COPY(IMAPSearchExpression, mRightExpression, other->mRightExpression);
}

IMAPSearchExpression::~IMAPSearchExpression()
{
    MC_SAFE_RELEASE(mHeader);
    MC_SAFE_RELEASE(mValue);
    MC_SAFE_RELEASE(mUids);
    MC_SAFE_RELEASE(mNumbers);
    MC_SAFE_RELEASE(mLeftExpression);
    MC_SAFE_RELEASE(mRightExpression);
}

String * IMAPSearchExpression::description()
{
    switch (mKind) {
        default:
        case IMAPSearchKindNone:
        return String::stringWithUTF8Format("<%s:%p None>", MCUTF8(className()), this);
        case IMAPSearchKindAll:
        return String::stringWithUTF8Format("<%s:%p ALL>", MCUTF8(className()), this);
        case IMAPSearchKindFrom:
        return String::stringWithUTF8Format("<%s:%p From %s>", MCUTF8(className()), this,
            MCUTF8(mValue->description()));
        case IMAPSearchKindTo:
        return String::stringWithUTF8Format("<%s:%p To %s>", MCUTF8(className()), this,
            MCUTF8(mValue->description()));
        case IMAPSearchKindCc:
        return String::stringWithUTF8Format("<%s:%p Cc %s>", MCUTF8(className()), this,
            MCUTF8(mValue->description()));
        case IMAPSearchKindBcc:
        return String::stringWithUTF8Format("<%s:%p Bcc %s>", MCUTF8(className()), this,
            MCUTF8(mValue->description()));
        case IMAPSearchKindRecipient:
        return String::stringWithUTF8Format("<%s:%p Recipient %s>", MCUTF8(className()), this,
            MCUTF8(mValue->description()));
        case IMAPSearchKindSubject:
        return String::stringWithUTF8Format("<%s:%p Subject %s>", MCUTF8(className()), this,
            MCUTF8(mValue->description()));
        case IMAPSearchKindUIDs:
            return String::stringWithUTF8Format("<%s:%p UIDs %s>", MCUTF8(className()), this,
                                                MCUTF8(mUids->description()));
        case IMAPSearchKindNumbers:
            return String::stringWithUTF8Format("<%s:%p Numbers %s>", MCUTF8(className()), this,
                                                MCUTF8(mNumbers->description()));
        case IMAPSearchKindContent:
        return String::stringWithUTF8Format("<%s:%p Content %s>", MCUTF8(className()), this,
            MCUTF8(mValue->description()));
        case IMAPSearchKindHeader:
        return String::stringWithUTF8Format("<%s:%p Header %s %s>", MCUTF8(className()), this,
            MCUTF8(mHeader->description()), MCUTF8(mValue->description()));
        case IMAPSearchKindGmailThreadID:
        return String::stringWithUTF8Format("<%s:%p X-GM-THRID %llu>", MCUTF8(className()), this,
             mLongNumber);
        case IMAPSearchKindOr:
        return String::stringWithUTF8Format("<%s:%p Or %s %s>", MCUTF8(className()), this,
            MCUTF8(mLeftExpression->description()), MCUTF8(mRightExpression->description()));
        case IMAPSearchKindAnd:
        return String::stringWithUTF8Format("<%s:%p And %s %s>", MCUTF8(className()), this,
            MCUTF8(mLeftExpression->description()), MCUTF8(mRightExpression->description()));
    }
}

Object * IMAPSearchExpression::copy()
{
    return new IMAPSearchExpression(this);
}

IMAPSearchExpression * IMAPSearchExpression::searchFrom(String * value)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindFrom;
    MC_SAFE_REPLACE_COPY(String, expr->mValue, value);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchTo(String * value)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindTo;
    MC_SAFE_REPLACE_COPY(String, expr->mValue, value);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchCc(String * value)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindCc;
    MC_SAFE_REPLACE_COPY(String, expr->mValue, value);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchBcc(String * value)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindBcc;
    MC_SAFE_REPLACE_COPY(String, expr->mValue, value);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchRecipient(String * value)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindRecipient;
    MC_SAFE_REPLACE_COPY(String, expr->mValue, value);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchAll()
{
    IMAPSearchExpression *expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindAll;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchSubject(String * value)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindSubject;
    MC_SAFE_REPLACE_COPY(String, expr->mValue, value);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchContent(String * value)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindContent;
    MC_SAFE_REPLACE_COPY(String, expr->mValue, value);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchBody(String * value)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindBody;
    MC_SAFE_REPLACE_COPY(String, expr->mValue, value);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchUIDs(IndexSet * uids)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindUIDs;
    MC_SAFE_REPLACE_COPY(IndexSet, expr->mUids, uids);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchNumbers(IndexSet * numbers)
{
	IMAPSearchExpression * expr = new IMAPSearchExpression();
	expr->mKind = IMAPSearchKindNumbers;
	MC_SAFE_REPLACE_COPY(IndexSet, expr->mNumbers, numbers);
	return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchHeader(String * header, String * value)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindHeader;
    MC_SAFE_REPLACE_COPY(String, expr->mHeader, header);
    MC_SAFE_REPLACE_COPY(String, expr->mValue, value);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchRead()
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindRead;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchUnread()
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindUnread;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchFlagged()
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindFlagged;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchUnflagged()
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindUnflagged;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchAnswered()
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindAnswered;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchUnanswered()
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindUnanswered;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchDraft()
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindDraft;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchUndraft()
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindUndraft;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchDeleted()
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindDeleted;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchSpam()
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindSpam;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchBeforeDate(time_t date)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindBeforeDate;
    expr->mLongNumber = (uint64_t) date;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchOnDate(time_t date)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindOnDate;
    expr->mLongNumber = (uint64_t) date;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchSinceDate(time_t date)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindSinceDate;
    expr->mLongNumber = (uint64_t) date;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchBeforeReceivedDate(time_t date)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindBeforeReceivedDate;
    expr->mLongNumber = (uint64_t) date;
    return (IMAPSearchExpression *) expr->autorelease();
}
IMAPSearchExpression * IMAPSearchExpression::searchOnReceivedDate(time_t date)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindOnReceivedDate;
    expr->mLongNumber = (uint64_t) date;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchSinceReceivedDate(time_t date)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindSinceReceivedDate;
    expr->mLongNumber = (uint64_t) date;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchSizeLarger(uint32_t size)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindSizeLarger;
    expr->mLongNumber = size;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchSizeSmaller(uint32_t size)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindSizeSmaller;
    expr->mLongNumber = size;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchGmailThreadID(uint64_t number)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindGmailThreadID;
    expr->mLongNumber = number;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchGmailMessageID(uint64_t number)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindGmailMessageID;
    expr->mLongNumber = number;
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchGmailRaw(String * searchExpr)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindGmailRaw;
    MC_SAFE_REPLACE_COPY(String, expr->mValue, searchExpr);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchAnd(IMAPSearchExpression * left, IMAPSearchExpression * right)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindAnd;
    MC_SAFE_REPLACE_RETAIN(IMAPSearchExpression, expr->mLeftExpression, left);
    MC_SAFE_REPLACE_RETAIN(IMAPSearchExpression, expr->mRightExpression, right);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchOr(IMAPSearchExpression * left, IMAPSearchExpression * right)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindOr;
    MC_SAFE_REPLACE_RETAIN(IMAPSearchExpression, expr->mLeftExpression, left);
    MC_SAFE_REPLACE_RETAIN(IMAPSearchExpression, expr->mRightExpression, right);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchExpression * IMAPSearchExpression::searchNot(IMAPSearchExpression * notExpr)
{
    IMAPSearchExpression * expr = new IMAPSearchExpression();
    expr->mKind = IMAPSearchKindNot;
    MC_SAFE_REPLACE_RETAIN(IMAPSearchExpression, expr->mLeftExpression, notExpr);
    return (IMAPSearchExpression *) expr->autorelease();
}

IMAPSearchKind IMAPSearchExpression::kind()
{
    return mKind;
}

String * IMAPSearchExpression::header()
{
    return mHeader;
}

String * IMAPSearchExpression::value()
{
    return mValue;
}

uint64_t IMAPSearchExpression::longNumber()
{
    return mLongNumber;
}

time_t IMAPSearchExpression::date()
{
    return (time_t) mLongNumber;
}

IndexSet * IMAPSearchExpression::uids()
{
    return mUids;
}

IndexSet * IMAPSearchExpression::numbers()
{
    return mNumbers;
}

IMAPSearchExpression * IMAPSearchExpression::leftExpression()
{
    return mLeftExpression;
}

IMAPSearchExpression * IMAPSearchExpression::rightExpression()
{
    return mRightExpression;
}


