//
//  MCPOPFetchHeaderOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/16/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCPOPFetchHeaderOperation.h"

#include "MCPOPAsyncSession.h"
#include "MCPOPSession.h"
#include "MCMessageHeader.h"

using namespace mailcore;

POPFetchHeaderOperation::POPFetchHeaderOperation()
{
    mMessageIndex = 0;
    mHeader = NULL;
}

POPFetchHeaderOperation::~POPFetchHeaderOperation()
{
    MC_SAFE_RELEASE(mHeader);
}

void POPFetchHeaderOperation::setMessageIndex(unsigned int messageIndex)
{
    mMessageIndex = messageIndex;
}

unsigned int POPFetchHeaderOperation::messageIndex()
{
    return mMessageIndex;
}

MessageHeader * POPFetchHeaderOperation::header()
{
    return mHeader;
}

void POPFetchHeaderOperation::main()
{
    ErrorCode error;
    mHeader = session()->session()->fetchHeader(mMessageIndex, &error);
    if (mHeader != NULL) {
        mHeader->retain();
    }
    setError(error);
}
