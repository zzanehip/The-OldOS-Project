//
//  MCNNTPPostOperation.cpp
//  mailcore2
//
//  Created by Daryle Walker on 2/21/16.
//  Copyright © 2016 MailCore. All rights reserved.
//

#include "MCNNTPPostOperation.h"

#include "MCNNTPAsyncSession.h"
#include "MCNNTPSession.h"

using namespace mailcore;

NNTPPostOperation::NNTPPostOperation()
{
    mMessageData = NULL;
    mMessageFilepath = NULL;
}

NNTPPostOperation::~NNTPPostOperation()
{
    MC_SAFE_RELEASE(mMessageFilepath);
    MC_SAFE_RELEASE(mMessageData);
}

void NNTPPostOperation::setMessageData(Data * data)
{
    MC_SAFE_REPLACE_RETAIN(Data, mMessageData, data);
}

Data * NNTPPostOperation::messageData()
{
    return mMessageData;
}

void NNTPPostOperation::setMessageFilepath(String * path)
{
    MC_SAFE_REPLACE_RETAIN(String, mMessageFilepath, path);
}

String * NNTPPostOperation::messageFilepath()
{
    return mMessageFilepath;
}

void NNTPPostOperation::main()
{
    ErrorCode error;
    if (mMessageFilepath != NULL) {
        session()->session()->postMessage(mMessageFilepath, this, &error);
    }
    else {
        session()->session()->postMessage(mMessageData, this, &error);
    }
    setError(error);
}
