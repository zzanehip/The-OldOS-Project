//
//  MCIMAPFolderInfo.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 12/6/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCIMAPFolderInfo.h"

using namespace mailcore;

void IMAPFolderInfo::init()
{
    mUidNext = 0;
    mUidValidity = 0;
    mMessageCount = 0;
    mModSequenceValue = 0;
    mFirstUnseenUid = 0;
    mAllowsNewPermanentFlags = false;
}

IMAPFolderInfo::IMAPFolderInfo()
{
    init();
}

IMAPFolderInfo::IMAPFolderInfo(IMAPFolderInfo * other)
{
    init();
    setUidNext(other->uidNext());
    setUidValidity(other->uidValidity());
    setModSequenceValue(other->modSequenceValue());
    setMessageCount(other->messageCount());
    setFirstUnseenUid(other->firstUnseenUid());
    setAllowsNewPermanentFlags(other->allowsNewPermanentFlags());
}

IMAPFolderInfo::~IMAPFolderInfo()
{
}

Object * IMAPFolderInfo::copy()
{
    return new IMAPFolderInfo(this);
}

void IMAPFolderInfo::setUidNext(uint32_t uidNext)
{
    mUidNext = uidNext;
}

uint32_t IMAPFolderInfo::uidNext()
{
    return mUidNext;
}

void IMAPFolderInfo::setUidValidity(uint32_t uidValidity)
{
    mUidValidity = uidValidity;
}

uint32_t IMAPFolderInfo::uidValidity()
{
    return mUidValidity;
}

void IMAPFolderInfo::setModSequenceValue(uint64_t modSequenceValue)
{
    mModSequenceValue = modSequenceValue;
}

uint64_t IMAPFolderInfo::modSequenceValue()
{
    return mModSequenceValue;
}

void IMAPFolderInfo::setMessageCount(int messageCount)
{
    mMessageCount = messageCount;
}

int IMAPFolderInfo::messageCount()
{
    return mMessageCount;
}

void IMAPFolderInfo::setFirstUnseenUid(uint32_t firstUnseenUid)
{
    mFirstUnseenUid = firstUnseenUid;
}

uint32_t IMAPFolderInfo::firstUnseenUid()
{
    return mFirstUnseenUid;
}

void IMAPFolderInfo::setAllowsNewPermanentFlags(bool allowsNewPermanentFlags)
{
    mAllowsNewPermanentFlags = allowsNewPermanentFlags;
}

bool IMAPFolderInfo::allowsNewPermanentFlags()
{
    return mAllowsNewPermanentFlags;
}
