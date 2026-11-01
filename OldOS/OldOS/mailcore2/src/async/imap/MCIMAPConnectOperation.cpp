//
//  MCIMAPConnectOperation.cc
//  mailcore2
//
//  Created by Ryan Walklin on 6/09/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPConnectOperation.h"

#include "MCIMAPAsyncConnection.h"
#include "MCIMAPSession.h"

using namespace mailcore;

void IMAPConnectOperation::main()
{
    ErrorCode error;
    session()->session()->connectIfNeeded(&error);
    setError(error);
}
