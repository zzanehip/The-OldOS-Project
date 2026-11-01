//
//  MCIMAPStoreFlagsOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPStoreFlagsOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPStoreFlagsOperation::IMAPStoreFlagsOperation()
{
    mUids = NULL;
    mNumbers = NULL;
    mKind = IMAPStoreFlagsRequestKindAdd;
    mFlags = MessageFlagNone;
    mCustomFlags = NULL;
}

IMAPStoreFlagsOperation::~IMAPStoreFlagsOperation()
{
    MC_SAFE_RELEASE(mNumbers);
    MC_SAFE_RELEASE(mUids);
    MC_SAFE_RELEASE(mCustomFlags);
}

void IMAPStoreFlagsOperation::setUids(IndexSet * uids)
{
    MC_SAFE_REPLACE_RETAIN(IndexSet, mUids, uids);
}

IndexSet * IMAPStoreFlagsOperation::uids()
{
    return mUids;
}

void IMAPStoreFlagsOperation::setNumbers(IndexSet * numbers)
{
    MC_SAFE_REPLACE_RETAIN(IndexSet, mNumbers, numbers);
}

IndexSet * IMAPStoreFlagsOperation::numbers()
{
    return mNumbers;
}

void IMAPStoreFlagsOperation::setKind(IMAPStoreFlagsRequestKind kind)
{
    mKind = kind;
}

IMAPStoreFlagsRequestKind IMAPStoreFlagsOperation::kind()
{
    return mKind;
}

void IMAPStoreFlagsOperation::setFlags(MessageFlag flags)
{
    mFlags = flags;
}

MessageFlag IMAPStoreFlagsOperation::flags()
{
    return mFlags;
}

void IMAPStoreFlagsOperation::setCustomFlags(Array * customFlags)
{
    MC_SAFE_REPLACE_RETAIN(Array, mCustomFlags, customFlags);
}

Array * IMAPStoreFlagsOperation::customFlags()
{
    return mCustomFlags;
}

void IMAPStoreFlagsOperation::main()
{
    ErrorCode error;
    if (mUids != NULL) {
        session()->session()->storeFlagsAndCustomFlagsByUID(folder(), mUids, mKind, mFlags, mCustomFlags, &error);
    }
    else {
        session()->session()->storeFlagsAndCustomFlagsByNumber(folder(), mNumbers, mKind, mFlags, mCustomFlags, &error);
    }
    setError(error);
}
