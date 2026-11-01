//
//  MCIMAPFolderInfoOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/13/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPFolderInfoOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"
#include "MCIMAPFolderInfo.h"

using namespace mailcore;

IMAPFolderInfoOperation::IMAPFolderInfoOperation()
{
    mInfo = NULL;
}

IMAPFolderInfoOperation::~IMAPFolderInfoOperation()
{
    MC_SAFE_RELEASE(mInfo);
}

IMAPFolderInfo * IMAPFolderInfoOperation::info()
{
    return mInfo;
}

void IMAPFolderInfoOperation::main()
{
    ErrorCode error;
    
    session()->session()->loginIfNeeded(&error);
    if (error != ErrorNone) {
        setError(error);
        return;
    }
    
    session()->session()->select(folder(), &error);
    if (error != ErrorNone) {
        setError(error);
        return;
    }
    
    mInfo = new IMAPFolderInfo();
    mInfo->setUidNext(session()->session()->uidNext());
    mInfo->setUidValidity(session()->session()->uidValidity());
    mInfo->setModSequenceValue(session()->session()->modSequenceValue());
    mInfo->setMessageCount(session()->session()->lastFolderMessageCount());
    mInfo->setFirstUnseenUid(session()->session()->firstUnseenUid());
    mInfo->setAllowsNewPermanentFlags(session()->session()->allowsNewPermanentFlags());

    setError(error);
}

