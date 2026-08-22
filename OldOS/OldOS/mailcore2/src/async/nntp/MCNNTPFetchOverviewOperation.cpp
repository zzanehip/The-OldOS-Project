//
//  NNTPFetchOverviewOperation.cpp
//  mailcore2
//
//  Created by Robert Widmann on 10/21/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCNNTPFetchOverviewOperation.h"

#include "MCNNTPAsyncSession.h"
#include "MCNNTPSession.h"

using namespace mailcore;

NNTPFetchOverviewOperation::NNTPFetchOverviewOperation()
{
    mArticles = NULL;
    mIndexes = NULL;
    mGroupName = NULL;
}

NNTPFetchOverviewOperation::~NNTPFetchOverviewOperation()
{
    MC_SAFE_RELEASE(mIndexes);
    MC_SAFE_RELEASE(mGroupName);
}

void NNTPFetchOverviewOperation::setIndexes(IndexSet * indexes)
{
    MC_SAFE_REPLACE_RETAIN(IndexSet, mIndexes, indexes);
}

IndexSet * NNTPFetchOverviewOperation::indexes()
{
    return mIndexes;
}

void NNTPFetchOverviewOperation::setGroupName(String * groupname)
{
    MC_SAFE_REPLACE_COPY(String, mGroupName, groupname);
}

String * NNTPFetchOverviewOperation::groupName()
{
    return mGroupName;
}

Array * NNTPFetchOverviewOperation::articles() {
    return mArticles;
}

void NNTPFetchOverviewOperation::main()
{
    ErrorCode error = ErrorNone;
    mArticles = Array::array();
    for(unsigned int i = 0 ; i < mIndexes->rangesCount() ; i ++) {
        Range range = mIndexes->allRanges()[i];
        Array * articles = session()->session()->fetchOverArticlesInRange(range, mGroupName, &error);
        if (error != ErrorNone) {
            setError(error);
            return;
        }
        mArticles->addObjectsFromArray(articles);
    }
    
    setError(error);
}
