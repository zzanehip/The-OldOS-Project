//
//  MCIMAPSyncResult.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/3/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPSyncResult.h"

#include "MCUtils.h"

using namespace mailcore;

IMAPSyncResult::IMAPSyncResult()
{
    mModifiedOrAddedMessages = NULL;
    mVanishedMessages = NULL;
}

IMAPSyncResult::~IMAPSyncResult()
{
    MC_SAFE_RELEASE(mModifiedOrAddedMessages);
    MC_SAFE_RELEASE(mVanishedMessages);
}

void IMAPSyncResult::setModifiedOrAddedMessages(Array * /* IMAPMessage */ messages)
{
    MC_SAFE_REPLACE_RETAIN(Array, mModifiedOrAddedMessages, messages);
}

Array * /* IMAPMessage */ IMAPSyncResult::modifiedOrAddedMessages()
{
    return mModifiedOrAddedMessages;
}

void IMAPSyncResult::setVanishedMessages(IndexSet * messages)
{
    MC_SAFE_REPLACE_RETAIN(IndexSet, mVanishedMessages, messages);
}

IndexSet * IMAPSyncResult::vanishedMessages()
{
    return mVanishedMessages;
}

