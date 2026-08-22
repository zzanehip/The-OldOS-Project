//
//  MCIMAPSubscribeFolderOperation.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPSubscribeFolderOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPSubscribeFolderOperation::IMAPSubscribeFolderOperation()
{
    mUnsubscribeEnabled = false;
}

IMAPSubscribeFolderOperation::~IMAPSubscribeFolderOperation()
{
}

void IMAPSubscribeFolderOperation::setUnsubscribeEnabled(bool enabled)
{
    mUnsubscribeEnabled = enabled;
}

bool IMAPSubscribeFolderOperation::isUnsubscribeEnabled()
{
    return mUnsubscribeEnabled;
}

void IMAPSubscribeFolderOperation::main()
{
    ErrorCode error;
    if (mUnsubscribeEnabled) {
        session()->session()->unsubscribeFolder(folder(), &error);
    }
    else {
        session()->session()->subscribeFolder(folder(), &error);
    }
    setError(error);
}
