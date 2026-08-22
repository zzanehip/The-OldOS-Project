//
//  MCIMAPFolderStatus.cc
//  mailcore2
//
//  Created by Sebastian on 6/11/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPFolderStatus.h"

using namespace mailcore;

void IMAPFolderStatus::init()
{
    mUnseenCount = 0;
    mMessageCount = 0;
    mRecentCount = 0;
    mUidNext = 0;
    mUidValidity = 0;
    mHighestModSeqValue = 0;
}

IMAPFolderStatus::IMAPFolderStatus()
{
    init();
}


IMAPFolderStatus::IMAPFolderStatus(IMAPFolderStatus * other)
{
    init();
    setUnseenCount(other->unseenCount());
    setMessageCount(other->messageCount());
    setRecentCount(other->recentCount());
    setUidNext(other->uidNext());
    setUidValidity(other->uidValidity());
    setHighestModSeqValue(other->highestModSeqValue());
}

IMAPFolderStatus::~IMAPFolderStatus()
{
}

Object * IMAPFolderStatus::copy()
{
    return new IMAPFolderStatus(this);
}

void IMAPFolderStatus::setUnseenCount(uint32_t unseen)
{
    mUnseenCount = unseen;
}

uint32_t IMAPFolderStatus::unseenCount()
{
    return mUnseenCount;
}

void IMAPFolderStatus::setMessageCount(uint32_t messages)
{
    mMessageCount = messages;
}

uint32_t IMAPFolderStatus::messageCount()
{
    return mMessageCount;
}

void IMAPFolderStatus::setRecentCount(uint32_t recent)
{
    mRecentCount = recent;
}

uint32_t IMAPFolderStatus::recentCount()
{
    return mRecentCount;
}

void IMAPFolderStatus::setUidNext(uint32_t uidNext)
{
    mUidNext = uidNext;
}

uint32_t IMAPFolderStatus::uidNext()
{
    return mUidNext;
}

void IMAPFolderStatus::setUidValidity(uint32_t uidValidity)
{
    mUidValidity = uidValidity;
}

uint32_t IMAPFolderStatus::uidValidity()
{
    return mUidValidity;
}

void IMAPFolderStatus::setHighestModSeqValue(uint64_t highestModSeqValue)
{
    mHighestModSeqValue = highestModSeqValue;
}

uint64_t IMAPFolderStatus::highestModSeqValue()
{
    return mHighestModSeqValue;
}

String * IMAPFolderStatus::description()
{
    String * result = String::string();
    result->appendUTF8Format("<%s:%p msg_count: %u, unseen_count: %u, recent_count: %u, uid_next: %u, uid_validity: %u, highestmodseqvalue :%llu>",
                             className()->UTF8Characters(),
                             this,
                             (unsigned int) messageCount(),
                             (unsigned int) unseenCount(),
                             (unsigned int) recentCount(),
                             (unsigned int) uidNext(),
                             (unsigned int) uidValidity(),
                             (unsigned long long) highestModSeqValue());
    return result;
}
