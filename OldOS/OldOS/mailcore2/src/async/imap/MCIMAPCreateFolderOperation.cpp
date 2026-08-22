//
//  MCIMAPCreateFolderOperation.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPCreateFolderOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPCreateFolderOperation::IMAPCreateFolderOperation()
{
}

IMAPCreateFolderOperation::~IMAPCreateFolderOperation()
{
}

void IMAPCreateFolderOperation::main()
{
    ErrorCode error;
    session()->session()->createFolder(folder(), &error);
    setError(error);
}
