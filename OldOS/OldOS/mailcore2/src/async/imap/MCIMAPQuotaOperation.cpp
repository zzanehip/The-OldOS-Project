//
//  MCIMAPQuotaOperation.cc
//  mailcore2
//
//  Created by Petro Korenev on 8/2/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPQuotaOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPQuotaOperation::IMAPQuotaOperation()
{
    mLimit = 0;
    mUsage = 0;
}

IMAPQuotaOperation::~IMAPQuotaOperation()
{
}

uint32_t IMAPQuotaOperation::limit()
{
    return mLimit;
}

uint32_t IMAPQuotaOperation::usage()
{
    return mUsage;
}

void IMAPQuotaOperation::main()
{
    ErrorCode error;
    session()->session()->loginIfNeeded(&error);
    if (error != ErrorNone) {
        setError(error);
        return;
    }
    
    session()->session()->getQuota(&mUsage, &mLimit, &error);
    setError(error);
}
