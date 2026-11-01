#include "MCDataStreamDecoder.h"

#include "MCString.h"
#include "MCUtils.h"
#include "MCDataDecoderUtils.h"

using namespace mailcore;

DataStreamDecoder::DataStreamDecoder()
{
    mFilename = NULL;
    mEncoding = Encoding7Bit;
    mRemainingData = NULL;
    mFile = NULL;
}

DataStreamDecoder::~DataStreamDecoder()
{
    MC_SAFE_RELEASE(mRemainingData);
    MC_SAFE_RELEASE(mFilename);
    if (mFile != NULL) {
        fclose(mFile);
        mFile = NULL;
    }
}

void DataStreamDecoder::setEncoding(Encoding encoding)
{
    mEncoding = encoding;
}

void DataStreamDecoder::setFilename(String * filename)
{
    MC_SAFE_REPLACE_COPY(String, mFilename, filename);
}

ErrorCode DataStreamDecoder::appendData(Data * data)
{
    Data * dataForDecode;
    if (mRemainingData && mRemainingData->length()) {
        // the data remains from previous append
        dataForDecode = (Data *) MC_SAFE_COPY(mRemainingData);
        dataForDecode->appendData(data);
    } else {
        dataForDecode = (Data *) MC_SAFE_RETAIN(data);
    }

    Data * remainingData = NULL;
    Data * decodedData = MCDecodeData(dataForDecode, mEncoding, true, &remainingData);

    ErrorCode errorCode = appendDecodedData(decodedData);

    if (errorCode == ErrorNone) {
        MC_SAFE_REPLACE_RETAIN(Data, mRemainingData, remainingData);
    }

    MC_SAFE_RELEASE(dataForDecode);
    return errorCode;
}

ErrorCode DataStreamDecoder::flushData()
{
    if (mRemainingData == NULL || mRemainingData->length() == 0) {
        return ErrorNone;
    }

    Data * unused = NULL;
    Data * decodedData = MCDecodeData(mRemainingData, mEncoding, false, &unused);

    ErrorCode errorCode = appendDecodedData(decodedData);

    if (errorCode == ErrorNone) {
        if (mFile != NULL) {
            if (fclose(mFile) != 0) {
                return ErrorFile;
            }
        }

        MC_SAFE_RELEASE(mRemainingData);
    }

    return errorCode;
}

ErrorCode DataStreamDecoder::appendDecodedData(Data * decodedData)
{
    if (mFilename == NULL) {
        return ErrorFile;
    }

    if (decodedData->length() == 0) {
        return ErrorNone;
    }

    if (mFile == NULL) {
        mFile = fopen(mFilename->fileSystemRepresentation(), "wb");

        if (mFile == NULL) {
            return ErrorFile;
        }
    }

    size_t result = fwrite(decodedData->bytes(), decodedData->length(), 1, mFile);
    if (result == 0) {
        return ErrorFile;
    }

    return ErrorNone;
}
