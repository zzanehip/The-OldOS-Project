//
//  MCPOPFetchMessageOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/16/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCPOPFetchMessageOperation.h"

#include "MCPOPAsyncSession.h"
#include "MCPOPSession.h"

using namespace mailcore;

POPFetchMessageOperation::POPFetchMessageOperation()
{
    mMessageIndex = 0;
    mData = NULL;
}

POPFetchMessageOperation::~POPFetchMessageOperation()
{
    MC_SAFE_RELEASE(mData);
}

void POPFetchMessageOperation::setMessageIndex(unsigned int messageIndex)
{
    mMessageIndex = messageIndex;
}

unsigned int POPFetchMessageOperation::messageIndex()
{
    return mMessageIndex;
}

Data * POPFetchMessageOperation::data()
{
    return mData;
}

void POPFetchMessageOperation::main()
{
    ErrorCode error;
    mData = session()->session()->fetchMessage(mMessageIndex, this, &error);
    MC_SAFE_RETAIN(mData);
    setError(error);
}

