//
//  MCSMTPNoopOperation.cc
//  mailcore2
//
//  Created by Robert Widmann on 9/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCSMTPNoopOperation.h"

#include "MCSMTPAsyncSession.h"
#include "MCSMTPSession.h"

using namespace mailcore;

SMTPNoopOperation::SMTPNoopOperation()
{
}

SMTPNoopOperation::~SMTPNoopOperation()
{
}

void SMTPNoopOperation::main()
{
    ErrorCode error;
    session()->session()->noop(&error);
    setError(error);
}
