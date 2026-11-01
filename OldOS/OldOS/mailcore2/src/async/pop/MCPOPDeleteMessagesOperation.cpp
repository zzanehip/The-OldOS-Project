//
//  MCPOPDeleteMessagesOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/16/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCPOPDeleteMessagesOperation.h"

#include "MCPOPAsyncSession.h"
#include "MCPOPSession.h"

using namespace mailcore;

POPDeleteMessagesOperation::POPDeleteMessagesOperation()
{
    mMessageIndexes = NULL;
}

POPDeleteMessagesOperation::~POPDeleteMessagesOperation()
{
    MC_SAFE_RELEASE(mMessageIndexes);
}

void POPDeleteMessagesOperation::setMessageIndexes(IndexSet * indexes)
{
    MC_SAFE_REPLACE_RETAIN(IndexSet, mMessageIndexes, indexes);
}

IndexSet * POPDeleteMessagesOperation::messageIndexes()
{
    return mMessageIndexes;
}

void POPDeleteMessagesOperation::main()
{
    if (mMessageIndexes == NULL)
        return;
    
    ErrorCode error;
    mc_foreachindexset(index, mMessageIndexes) {
        session()->session()->deleteMessage((unsigned int) index, &error);
        if (error != ErrorNone) {
            setError(error);
            break;
        }
    }
    session()->session()->disconnect();
}

