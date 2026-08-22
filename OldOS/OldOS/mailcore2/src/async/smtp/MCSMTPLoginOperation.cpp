//
//  MCSMTPLoginOperation.cc
//  mailcore2
//
//  Created by Hironori Yoshida on 10/29/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCSMTPLoginOperation.h"

#include "MCSMTPAsyncSession.h"
#include "MCSMTPSession.h"

using namespace mailcore;

SMTPLoginOperation::SMTPLoginOperation()
{
}

SMTPLoginOperation::~SMTPLoginOperation()
{
}

void SMTPLoginOperation::main()
{
    ErrorCode error;
    session()->session()->loginIfNeeded(&error);
    setError(error);
}
