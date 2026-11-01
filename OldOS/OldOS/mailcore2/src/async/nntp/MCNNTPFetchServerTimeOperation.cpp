//
//  MCNNTPFetchServerTimeOperation.cpp
//  mailcore2
//
//  Created by Robert Widmann on 10/21/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCNNTPFetchServerTimeOperation.h"

#include "MCNNTPAsyncSession.h"
#include "MCNNTPSession.h"

using namespace mailcore;

NNTPFetchServerTimeOperation::NNTPFetchServerTimeOperation()
{
    mTime = -1;
}

NNTPFetchServerTimeOperation::~NNTPFetchServerTimeOperation()
{
}

time_t NNTPFetchServerTimeOperation::time()
{
    return mTime;
}

void NNTPFetchServerTimeOperation::main()
{
    ErrorCode error;
    mTime = session()->session()->fetchServerDate(&error);
    setError(error);
}
