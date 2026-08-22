//
//  IMAPFetchContentOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPFetchContentOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPFetchContentOperation::IMAPFetchContentOperation()
{
    mUid = 0;
    mNumber = 0;
    mPartID = NULL;
    mEncoding = Encoding7Bit;
    mData = NULL;
}

IMAPFetchContentOperation::~IMAPFetchContentOperation()
{
    MC_SAFE_RELEASE(mPartID);
    MC_SAFE_RELEASE(mData);
}

void IMAPFetchContentOperation::setUid(uint32_t uid)
{
    mUid = uid;
}

uint32_t IMAPFetchContentOperation::uid()
{
    return mUid;
}

void IMAPFetchContentOperation::setNumber(uint32_t value)
{
    mNumber = value;
}

uint32_t IMAPFetchContentOperation::number()
{
    return mNumber;
}

void IMAPFetchContentOperation::setPartID(String * partID)
{
    MC_SAFE_REPLACE_COPY(String, mPartID, partID);
}

String * IMAPFetchContentOperation::partID()
{
    return mPartID;
}

void IMAPFetchContentOperation::setEncoding(Encoding encoding)
{
    mEncoding = encoding;
}

Encoding IMAPFetchContentOperation::encoding()
{
    return mEncoding;
}

Data * IMAPFetchContentOperation::data()
{
    return mData;
}

void IMAPFetchContentOperation::main()
{
    ErrorCode error;
    if (mUid != 0) {
        if (mPartID != NULL) {
            mData = session()->session()->fetchMessageAttachmentByUID(folder(), mUid, mPartID, mEncoding, this, &error);
        }
        else {
            mData = session()->session()->fetchMessageByUID(folder(), mUid, this, &error);
        }
    }
    else {
        if (mPartID != NULL) {
            mData = session()->session()->fetchMessageAttachmentByNumber(folder(), mNumber, mPartID, mEncoding, this, &error);
        }
        else {
            mData = session()->session()->fetchMessageByNumber(folder(), mNumber, this, &error);
        }
    }
    MC_SAFE_RETAIN(mData);
    setError(error);
}

