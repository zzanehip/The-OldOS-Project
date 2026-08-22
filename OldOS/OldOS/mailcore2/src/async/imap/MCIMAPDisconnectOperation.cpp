//
//  MCIMAPDisconnectOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 6/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPDisconnectOperation.h"

#include "MCIMAPAsyncConnection.h"
#include "MCIMAPSession.h"

using namespace mailcore;

IMAPDisconnectOperation::IMAPDisconnectOperation()
{
}

IMAPDisconnectOperation::~IMAPDisconnectOperation()
{
}

void IMAPDisconnectOperation::main()
{
    session()->session()->disconnect();
    setError(ErrorNone);
}
