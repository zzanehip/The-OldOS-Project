//
//  IMAPFetchContentToFileOperation.cpp
//  mailcore2
//
//  Created by Dmitry Isaikin on 2/08/16.
//  Copyright (c) 2016 MailCore. All rights reserved.
//

#include "MCIMAPFetchContentToFileOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPFetchContentToFileOperation::IMAPFetchContentToFileOperation()
{
    mUid = 0;
    mPartID = NULL;
    mEncoding = Encoding7Bit;
    mFilename = NULL;
    mLoadingByChunksEnabled = false;
    mChunksSize = 2*1024*1024;
    mEstimatedSize = 0;
}

IMAPFetchContentToFileOperation::~IMAPFetchContentToFileOperation()
{
    MC_SAFE_RELEASE(mPartID);
    MC_SAFE_RELEASE(mFilename);
}

void IMAPFetchContentToFileOperation::setUid(uint32_t uid)
{
    mUid = uid;
}

void IMAPFetchContentToFileOperation::setPartID(String * partID)
{
    MC_SAFE_REPLACE_COPY(String, mPartID, partID);
}

void IMAPFetchContentToFileOperation::setEncoding(Encoding encoding)
{
    mEncoding = encoding;
}

void IMAPFetchContentToFileOperation::setFilename(String * filename)
{
    MC_SAFE_REPLACE_COPY(String, mFilename, filename);
}

void IMAPFetchContentToFileOperation::setLoadingByChunksEnabled(bool loadingByChunksEnabled)
{
    mLoadingByChunksEnabled = loadingByChunksEnabled;
}

bool IMAPFetchContentToFileOperation::isLoadingByChunksEnabled()
{
    return mLoadingByChunksEnabled;
}

void IMAPFetchContentToFileOperation::setChunksSize(uint32_t chunksSize)
{
    mChunksSize = chunksSize;
}

uint32_t IMAPFetchContentToFileOperation::chunksSize()
{
    return mChunksSize;
}

void IMAPFetchContentToFileOperation::setEstimatedSize(uint32_t estimatedSize)
{
    mEstimatedSize = estimatedSize;
}

uint32_t IMAPFetchContentToFileOperation::estimatedSize()
{
    return mEstimatedSize;
}

void IMAPFetchContentToFileOperation::main()
{
    ErrorCode error = ErrorNone;
    if (mLoadingByChunksEnabled) {
      session()->session()->fetchMessageAttachmentToFileByChunksByUID(folder(), mUid, mPartID,
                                                              mEstimatedSize, mEncoding,
                                                              mFilename, mChunksSize,
                                                              this, &error);
    } else {
      session()->session()->fetchMessageAttachmentToFileByUID(folder(), mUid, mPartID,
                                                              mEncoding, mFilename,
                                                              this, &error);
    }
    setError(error);
}
