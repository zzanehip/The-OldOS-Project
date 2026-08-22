//
//  MCIMAPRenameFolderOperation.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPRenameFolderOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPRenameFolderOperation::IMAPRenameFolderOperation()
{
    mOtherName = NULL;
}

IMAPRenameFolderOperation::~IMAPRenameFolderOperation()
{
    MC_SAFE_RELEASE(mOtherName);
}

void IMAPRenameFolderOperation::setOtherName(String * otherName)
{
    MC_SAFE_REPLACE_COPY(String, mOtherName, otherName);
}

String * IMAPRenameFolderOperation::otherName()
{
    return mOtherName;
}

void IMAPRenameFolderOperation::main()
{
    ErrorCode error;
    session()->session()->renameFolder(folder(), mOtherName, &error);
    setError(error);
}

