//
//  MCIMAPCheckAccountOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPCheckAccountOperation.h"

#include "MCIMAPAsyncConnection.h"
#include "MCIMAPSession.h"

using namespace mailcore;

IMAPCheckAccountOperation::IMAPCheckAccountOperation()
{
    mLoginResponse = NULL;
    mLoginUnparsedResponseData = NULL;
}

IMAPCheckAccountOperation::~IMAPCheckAccountOperation()
{
    MC_SAFE_RELEASE(mLoginResponse);
    MC_SAFE_RELEASE(mLoginUnparsedResponseData);
}

void IMAPCheckAccountOperation::main()
{
    ErrorCode error;
    session()->session()->loginIfNeeded(&error);
    if (error != ErrorNone) {
        MC_SAFE_REPLACE_COPY(String, mLoginResponse, session()->session()->loginResponse());
        MC_SAFE_REPLACE_COPY(Data, mLoginUnparsedResponseData, session()->session()->unparsedResponseData());
    }
    setError(error);
}

String * IMAPCheckAccountOperation::loginResponse()
{
    return mLoginResponse;
}

Data * IMAPCheckAccountOperation::loginUnparsedResponseData()
{
    return mLoginUnparsedResponseData;
}
