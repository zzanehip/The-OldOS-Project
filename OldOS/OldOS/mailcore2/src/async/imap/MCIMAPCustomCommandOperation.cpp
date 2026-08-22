//
//  MCIMAPCustomCommandOperation.cpp
//  mailcore2
//
//  Created by Libor Huspenina on 18/10/2015.
//  Copyright © 2015 MailCore. All rights reserved.
//

#include "MCIMAPCustomCommandOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPCustomCommandOperation::IMAPCustomCommandOperation()
{
    mCustomCommand = NULL;
    mResponse = NULL;
}

IMAPCustomCommandOperation::~IMAPCustomCommandOperation()
{
    MC_SAFE_RELEASE(mCustomCommand);
    MC_SAFE_RELEASE(mResponse);
}

void IMAPCustomCommandOperation::setCustomCommand(String * command)
{
    MC_SAFE_REPLACE_COPY(String, mCustomCommand, command);
}

String * IMAPCustomCommandOperation::response()
{
    return mResponse;
}

void IMAPCustomCommandOperation::main()
{
    ErrorCode error;
    mResponse = session()->session()->customCommand(mCustomCommand, &error);
    MC_SAFE_RETAIN(mResponse);
    setError(error);
}
