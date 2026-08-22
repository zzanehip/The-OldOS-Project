//
//  MCIMAPDeleteFolderOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPDeleteFolderOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPDeleteFolderOperation::IMAPDeleteFolderOperation()
{
}

IMAPDeleteFolderOperation::~IMAPDeleteFolderOperation()
{
}

void IMAPDeleteFolderOperation::main()
{
    ErrorCode error;
    session()->session()->deleteFolder(folder(), &error);
    setError(error);
}
