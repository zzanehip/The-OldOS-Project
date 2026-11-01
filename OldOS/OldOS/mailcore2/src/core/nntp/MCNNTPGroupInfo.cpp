//
//  MCNNTPGroupInfo.cpp
//  mailcore2
//
//  Created by Robert Widmann on 3/6/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCNNTPGroupInfo.h"

using namespace mailcore;

void NNTPGroupInfo::init()
{
    mMessageCount = 0;
    mName = NULL;
}

NNTPGroupInfo::NNTPGroupInfo()
{
    MC_SAFE_RELEASE(mName);
    init();
}


NNTPGroupInfo::NNTPGroupInfo(NNTPGroupInfo * other)
{
    init();
    setMessageCount(other->messageCount());
    setName(other->name());
}

NNTPGroupInfo::~NNTPGroupInfo()
{
}

String * NNTPGroupInfo::description()
{
    return String::stringWithUTF8Format("<%s:%p> Group name: %s; Message count: %u",
                                        MCUTF8(className()), this, MCUTF8(mName), mMessageCount);
}

Object * NNTPGroupInfo::copy()
{
    return new NNTPGroupInfo(this);
}

void NNTPGroupInfo::setName(String * name) 
{
    MC_SAFE_REPLACE_COPY(String, mName, name);
}

String * NNTPGroupInfo::name()
{
    return mName;
}

void NNTPGroupInfo::setMessageCount(uint32_t messageCount)
{
    mMessageCount = messageCount;
}

uint32_t NNTPGroupInfo::messageCount()
{
    return mMessageCount;
}