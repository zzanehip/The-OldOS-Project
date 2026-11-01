//
//  MCNNTPListNewsgroupsMessagesOperation.cpp
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCNNTPListNewsgroupsOperation.h"

#include "MCNNTPAsyncSession.h"
#include "MCNNTPSession.h"

using namespace mailcore;

NNTPListNewsgroupsOperation::NNTPListNewsgroupsOperation()
{
    mListsSuscribed = false;
    mGroups = NULL;
}

NNTPListNewsgroupsOperation::~NNTPListNewsgroupsOperation()
{
}

void NNTPListNewsgroupsOperation::setListsSubscribed(bool listsSubscribed) 
{
    mListsSuscribed = listsSubscribed;
}

bool NNTPListNewsgroupsOperation::listsSubscribed()
{
    return mListsSuscribed;
}

Array * NNTPListNewsgroupsOperation::groups() {
    return mGroups;
}

void NNTPListNewsgroupsOperation::main()
{
    ErrorCode error;
    
    if (mListsSuscribed) {
        mGroups = session()->session()->listDefaultNewsgroups(&error);
    } else {
        mGroups = session()->session()->listAllNewsgroups(&error);
    }
    MC_SAFE_RETAIN(mGroups);
    setError(error);
}
