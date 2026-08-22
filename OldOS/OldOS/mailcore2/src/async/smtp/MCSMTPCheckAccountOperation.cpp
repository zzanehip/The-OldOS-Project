//
//  MCSMTPCheckAccountOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCSMTPCheckAccountOperation.h"

#include "MCSMTPAsyncSession.h"
#include "MCSMTPSession.h"

using namespace mailcore;

SMTPCheckAccountOperation::SMTPCheckAccountOperation()
{
    mFrom = NULL;
}

SMTPCheckAccountOperation::~SMTPCheckAccountOperation()
{
    MC_SAFE_RELEASE(mFrom);
}

void SMTPCheckAccountOperation::setFrom(Address * from)
{
    MC_SAFE_REPLACE_RETAIN(Address, mFrom, from);
}

Address * SMTPCheckAccountOperation::from()
{
    return mFrom;
}

void SMTPCheckAccountOperation::main()
{
    ErrorCode error;
    
    session()->session()->checkAccount(mFrom, &error);
    setError(error);
}
