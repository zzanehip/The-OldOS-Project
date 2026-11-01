//
//  MCIMAPExpungeOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPExpungeOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPExpungeOperation::IMAPExpungeOperation()
{
}

IMAPExpungeOperation::~IMAPExpungeOperation()
{
}

void IMAPExpungeOperation::main()
{
    ErrorCode error;
    session()->session()->expunge(folder(), &error);
    setError(error);
}
