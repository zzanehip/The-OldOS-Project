//
//  IMAPMoveMessagesOperation.cpp
//  mailcore2
//
//  Created by Nikolay Morev on 02/02/16.
//  Copyright © 2016 MailCore. All rights reserved.
//

#include "MCIMAPMoveMessagesOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPMoveMessagesOperation::IMAPMoveMessagesOperation()
{
    mUids = NULL;
    mDestFolder = NULL;
    mUidMapping = NULL;
}

IMAPMoveMessagesOperation::~IMAPMoveMessagesOperation()
{
    MC_SAFE_RELEASE(mUidMapping);
    MC_SAFE_RELEASE(mUids);
    MC_SAFE_RELEASE(mDestFolder);
}

void IMAPMoveMessagesOperation::setUids(IndexSet * uids)
{
    MC_SAFE_REPLACE_RETAIN(IndexSet, mUids, uids);
}

IndexSet * IMAPMoveMessagesOperation::uids()
{
    return mUids;
}

HashMap * IMAPMoveMessagesOperation::uidMapping()
{
    return mUidMapping;
}

void IMAPMoveMessagesOperation::setDestFolder(String * destFolder)
{
    MC_SAFE_REPLACE_COPY(String, mDestFolder, destFolder);
}

String * IMAPMoveMessagesOperation::destFolder()
{
    return mDestFolder;
}

void IMAPMoveMessagesOperation::main()
{
    ErrorCode error;
    session()->session()->moveMessages(folder(), mUids, mDestFolder, &mUidMapping, &error);
    MC_SAFE_RETAIN(mUidMapping);
    setError(error);
}
