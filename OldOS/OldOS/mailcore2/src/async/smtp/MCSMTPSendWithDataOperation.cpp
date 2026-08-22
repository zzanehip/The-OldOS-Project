//
//  SMTPSendWithDataOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/10/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCSMTPSendWithDataOperation.h"

#include "MCSMTPAsyncSession.h"
#include "MCSMTPSession.h"

using namespace mailcore;

SMTPSendWithDataOperation::SMTPSendWithDataOperation()
{
    mMessageData = NULL;
    mMessageFilepath = NULL;
    mFrom = NULL;
    mRecipients = NULL;
}

SMTPSendWithDataOperation::~SMTPSendWithDataOperation()
{
    MC_SAFE_RELEASE(mFrom);
    MC_SAFE_RELEASE(mRecipients);
    MC_SAFE_RELEASE(mMessageFilepath);
    MC_SAFE_RELEASE(mMessageData);
}

void SMTPSendWithDataOperation::setMessageData(Data * data)
{
    MC_SAFE_REPLACE_RETAIN(Data, mMessageData, data);
}

Data * SMTPSendWithDataOperation::messageData()
{
    return mMessageData;
}

void SMTPSendWithDataOperation::setMessageFilepath(String * path)
{
    MC_SAFE_REPLACE_RETAIN(String, mMessageFilepath, path);
}

String * SMTPSendWithDataOperation::messageFilepath()
{
    return mMessageFilepath;
}

void SMTPSendWithDataOperation::setFrom(Address * from)
{
    MC_SAFE_REPLACE_COPY(Address, mFrom, from);
}

Address * SMTPSendWithDataOperation::from()
{
    return mFrom;
}

void SMTPSendWithDataOperation::setRecipients(Array * recipients)
{
    MC_SAFE_REPLACE_COPY(Array, mRecipients, recipients);
}

Array * SMTPSendWithDataOperation::recipients()
{
    return mRecipients;
}

void SMTPSendWithDataOperation::main()
{
    ErrorCode error;
    if (mMessageFilepath != NULL) {
        session()->session()->sendMessage(mFrom, mRecipients, mMessageFilepath, this, &error);
    }
    else
    if ((mFrom != NULL) && (mRecipients != NULL)) {
        session()->session()->sendMessage(mFrom, mRecipients, mMessageData, this, &error);
    }
    else {
        session()->session()->sendMessage(mMessageData, this, &error);
    }
    setError(error);
}

void SMTPSendWithDataOperation::cancel()
{
    SMTPOperation::cancel();
    session()->session()->cancelMessageSending();
}
