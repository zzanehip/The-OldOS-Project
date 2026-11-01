//
//  MCNNTPFetchArticleOperation.cpp
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCNNTPFetchArticleOperation.h"

#include "MCNNTPAsyncSession.h"
#include "MCNNTPSession.h"

using namespace mailcore;

NNTPFetchArticleOperation::NNTPFetchArticleOperation()
{
    mMessageIndex = 0;
    mData = NULL;
    mGroupName = NULL;
    mMessageID = NULL;
}

NNTPFetchArticleOperation::~NNTPFetchArticleOperation()
{
    MC_SAFE_RELEASE(mMessageID);
    MC_SAFE_RELEASE(mGroupName);
    MC_SAFE_RELEASE(mData);
}

void NNTPFetchArticleOperation::setGroupName(String * groupName) {
    MC_SAFE_REPLACE_COPY(String, mGroupName, groupName);
}

String * NNTPFetchArticleOperation::groupName() {
    return mGroupName;
}

void NNTPFetchArticleOperation::setMessageID(String * groupName) {
    MC_SAFE_REPLACE_COPY(String, mMessageID, groupName);
}

String * NNTPFetchArticleOperation::messageID() {
    return mMessageID;
}

void NNTPFetchArticleOperation::setMessageIndex(unsigned int messageIndex)
{
    mMessageIndex = messageIndex;
}

unsigned int NNTPFetchArticleOperation::messageIndex()
{
    return mMessageIndex;
}

Data * NNTPFetchArticleOperation::data()
{
    return mData;
}

void NNTPFetchArticleOperation::main()
{
    ErrorCode error;
    if (mMessageID == NULL) {
        mData = session()->session()->fetchArticle(mGroupName, mMessageIndex, this, &error);
    } else {
        mData = session()->session()->fetchArticleByMessageID(mMessageID, &error);
    }
    MC_SAFE_RETAIN(mData);
    setError(error);
}

