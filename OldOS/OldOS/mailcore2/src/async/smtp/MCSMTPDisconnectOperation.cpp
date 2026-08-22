//
//  SMTPDisconnectOperation.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 6/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCSMTPDisconnectOperation.h"

#include "MCSMTPAsyncSession.h"
#include "MCSMTPSession.h"

using namespace mailcore;

SMTPDisconnectOperation::SMTPDisconnectOperation()
{
}

SMTPDisconnectOperation::~SMTPDisconnectOperation()
{
}

void SMTPDisconnectOperation::main()
{
    session()->session()->disconnect();
    setError(ErrorNone);
}
