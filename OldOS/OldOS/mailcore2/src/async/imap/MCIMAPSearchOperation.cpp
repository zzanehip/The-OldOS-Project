//
//  IMAPSearchOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPSearchOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"
#include "MCIMAPSearchExpression.h"

using namespace mailcore;

IMAPSearchOperation::IMAPSearchOperation()
{
    mKind = IMAPSearchKindNone;
    mSearchString = NULL;
    mExpression = NULL;
    mUids = NULL;
}

IMAPSearchOperation::~IMAPSearchOperation()
{
    MC_SAFE_RELEASE(mSearchString);
    MC_SAFE_RELEASE(mExpression);
    MC_SAFE_RELEASE(mUids);
}

void IMAPSearchOperation::setSearchKind(IMAPSearchKind kind)
{
    mKind = kind;
}

IMAPSearchKind IMAPSearchOperation::searchKind()
{
    return mKind;
}

void IMAPSearchOperation::setSearchString(String * searchString)
{
    MC_SAFE_REPLACE_COPY(String, mSearchString, searchString);
}

String * IMAPSearchOperation::searchString()
{
    return mSearchString;
}

void IMAPSearchOperation::setSearchExpression(IMAPSearchExpression * expression)
{
    MC_SAFE_REPLACE_RETAIN(IMAPSearchExpression, mExpression, expression);
}

IMAPSearchExpression * IMAPSearchOperation::searchExpression()
{
    return mExpression;
}

IndexSet * IMAPSearchOperation::uids()
{
    return mUids;
}

void IMAPSearchOperation::main()
{
    ErrorCode error;
    if (mExpression != NULL) {
        mUids = session()->session()->search(folder(), mExpression, &error);
    }
    else {
        mUids = session()->session()->search(folder(), mKind, mSearchString, &error);
    }
    MC_SAFE_RETAIN(mUids);
    setError(error);
}

