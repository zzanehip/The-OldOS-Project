//
//  MCIMAPCopyMessagesOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPCopyMessagesOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPCopyMessagesOperation::IMAPCopyMessagesOperation()
{
    mUids = NULL;
    mDestFolder = NULL;
    mUidMapping = NULL;
}

IMAPCopyMessagesOperation::~IMAPCopyMessagesOperation()
{
    MC_SAFE_RELEASE(mUidMapping);
    MC_SAFE_RELEASE(mUids);
    MC_SAFE_RELEASE(mDestFolder);
}

void IMAPCopyMessagesOperation::setUids(IndexSet * uids)
{
    MC_SAFE_REPLACE_RETAIN(IndexSet, mUids, uids);
}

IndexSet * IMAPCopyMessagesOperation::uids()
{
    return mUids;
}

HashMap * IMAPCopyMessagesOperation::uidMapping()
{
    return mUidMapping;
}

void IMAPCopyMessagesOperation::setDestFolder(String * destFolder)
{
    MC_SAFE_REPLACE_COPY(String, mDestFolder, destFolder);
}

String * IMAPCopyMessagesOperation::destFolder()
{
    return mDestFolder;
}

void IMAPCopyMessagesOperation::main()
{
    ErrorCode error;
    session()->session()->copyMessages(folder(), mUids, mDestFolder, &mUidMapping, &error);
    MC_SAFE_RETAIN(mUidMapping);
    setError(error);
}
