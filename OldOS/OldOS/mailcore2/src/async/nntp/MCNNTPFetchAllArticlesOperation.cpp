//
//  MCNNTPFetchAllArticlesOperation.cpp
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCNNTPFetchAllArticlesOperation.h"

#include "MCNNTPAsyncSession.h"
#include "MCNNTPSession.h"

using namespace mailcore;

NNTPFetchAllArticlesOperation::NNTPFetchAllArticlesOperation()
{
    mGroupName = NULL;
    mArticles = NULL;
}

NNTPFetchAllArticlesOperation::~NNTPFetchAllArticlesOperation()
{
    MC_SAFE_RELEASE(mGroupName);
    MC_SAFE_RELEASE(mArticles);
}

void NNTPFetchAllArticlesOperation::setGroupName(String * groupname)
{
    MC_SAFE_REPLACE_COPY(String, mGroupName, groupname);
}

String * NNTPFetchAllArticlesOperation::groupName()
{
    return mGroupName;
}

IndexSet * NNTPFetchAllArticlesOperation::articles()
{
    return mArticles;
}

void NNTPFetchAllArticlesOperation::main()
{
    ErrorCode error;
    mArticles = session()->session()->fetchAllArticles(mGroupName, &error);
    setError(error);
    MC_SAFE_RETAIN(mArticles);
}
