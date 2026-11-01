//
//  IMAPIdentityOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPIdentityOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"
#include "MCIMAPIdentity.h"

using namespace mailcore;

IMAPIdentityOperation::IMAPIdentityOperation()
{
    mClientIdentity = NULL;
    mServerIdentity = NULL;
}

IMAPIdentityOperation::~IMAPIdentityOperation()
{
    MC_SAFE_RELEASE(mClientIdentity);
    MC_SAFE_RELEASE(mServerIdentity);
}

void IMAPIdentityOperation::setClientIdentity(IMAPIdentity * identity)
{
    MC_SAFE_REPLACE_COPY(IMAPIdentity, mClientIdentity, identity);
}

IMAPIdentity * IMAPIdentityOperation::clientIdentity()
{
    return mClientIdentity;
}

IMAPIdentity * IMAPIdentityOperation::serverIdentity()
{
    return mServerIdentity;
}

void IMAPIdentityOperation::main()
{
    ErrorCode error;
    mServerIdentity = session()->session()->identity(mClientIdentity, &error);
    MC_SAFE_RETAIN(mServerIdentity);
    setError(error);
}

