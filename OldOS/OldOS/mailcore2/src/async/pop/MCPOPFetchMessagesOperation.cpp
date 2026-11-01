//
//  MCPOPFetchMessagesOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/16/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCPOPFetchMessagesOperation.h"

#include "MCPOPAsyncSession.h"
#include "MCPOPSession.h"

using namespace mailcore;

POPFetchMessagesOperation::POPFetchMessagesOperation()
{
    mMessages = NULL;
}

POPFetchMessagesOperation::~POPFetchMessagesOperation()
{
    MC_SAFE_RELEASE(mMessages);
}

Array * POPFetchMessagesOperation::messages()
{
    return mMessages;
}

void POPFetchMessagesOperation::main()
{
    ErrorCode error;
    mMessages = session()->session()->fetchMessages(&error);
    setError(error);
    MC_SAFE_RETAIN(mMessages);
}
