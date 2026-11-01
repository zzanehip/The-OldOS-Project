//
//  IMAPFetchParsedContentOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPFetchParsedContentOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPFetchParsedContentOperation::IMAPFetchParsedContentOperation()
{
    mUid = 0;
    mNumber = 0;
    mEncoding = Encoding7Bit;
    mParser = NULL;
}

IMAPFetchParsedContentOperation::~IMAPFetchParsedContentOperation()
{
    MC_SAFE_RELEASE(mParser);
}

void IMAPFetchParsedContentOperation::setUid(uint32_t uid)
{
    mUid = uid;
}

uint32_t IMAPFetchParsedContentOperation::uid()
{
    return mUid;
}

void IMAPFetchParsedContentOperation::setNumber(uint32_t value)
{
    mNumber = value;
}

uint32_t IMAPFetchParsedContentOperation::number()
{
    return mNumber;
}

void IMAPFetchParsedContentOperation::setEncoding(Encoding encoding)
{
    mEncoding = encoding;
}

Encoding IMAPFetchParsedContentOperation::encoding()
{
    return mEncoding;
}

MessageParser * IMAPFetchParsedContentOperation::parser()
{
    return mParser;
}

void IMAPFetchParsedContentOperation::main()
{
    ErrorCode error;
    Data * data;
    if (mUid != 0) {
        data = session()->session()->fetchMessageByUID(folder(), mUid, this, &error);
    }
    else {
        data = session()->session()->fetchMessageByNumber(folder(), mNumber, this, &error);
    }
    if (data) {
        mParser = new mailcore::MessageParser(data);
    }
    setError(error);
}

