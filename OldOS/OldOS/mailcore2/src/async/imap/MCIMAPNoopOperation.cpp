//
//  MCIMAPNoopOperation.cpp
//  mailcore2
//
//  Created by Robert Widmann on 9/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPNoopOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPNoopOperation::IMAPNoopOperation()
{
}

IMAPNoopOperation::~IMAPNoopOperation()
{
}

void IMAPNoopOperation::main()
{
    ErrorCode error;
    session()->session()->noop(&error);
    setError(error);
}
