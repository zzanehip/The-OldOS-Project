//
//  MCIMAPFolderStatusOperation.cc
//  mailcore2
//
//  Created by Sebastian on 6/5/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPFolderStatusOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"
#include "MCIMAPFolderStatus.h"

using namespace mailcore;

IMAPFolderStatusOperation::IMAPFolderStatusOperation()
{
    mStatus = NULL;
}

IMAPFolderStatusOperation::~IMAPFolderStatusOperation()
{
    MC_SAFE_RELEASE(mStatus);
}

void IMAPFolderStatusOperation::main()
{
    ErrorCode error;
    
    session()->session()->loginIfNeeded(&error);
    if (error != ErrorNone) {
        setError(error);
        return;
    }
    
    IMAPFolderStatus *status = session()->session()->folderStatus(folder(), &error);
    if (error != ErrorNone) {
        setError(error);
        return;
    }
    
    MC_SAFE_REPLACE_RETAIN(IMAPFolderStatus, mStatus, status);
    setError(error);
}

IMAPFolderStatus * IMAPFolderStatusOperation::status()
{
    return mStatus;
}

