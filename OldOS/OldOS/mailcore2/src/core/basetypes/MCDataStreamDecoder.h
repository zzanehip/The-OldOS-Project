//
//  DataStreamDecoder.hpp
//  mailcore2
//
//  Copyright © 2016 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCDATASTREAMDECODER_H

#define MAILCORE_MCDATASTREAMDECODER_H

#include <stdio.h>
#include <stdlib.h>

#include <MailCore/MCObject.h>
#include <MailCore/MCData.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {

    class DataStreamDecoder : public Object {
    public:
        DataStreamDecoder();
        virtual ~DataStreamDecoder();

        virtual void setEncoding(Encoding encoding);
        // output filename
        virtual void setFilename(String * filename);

        // when data are received, decode them and add them to the file.
        virtual ErrorCode appendData(Data * data);

        // end of data received.
        virtual ErrorCode flushData();

    private: // impl
        virtual ErrorCode appendDecodedData(Data * decodedData);

    private:
        String * mFilename;
        Encoding mEncoding;
        Data * mRemainingData;
        FILE * mFile;
    };

}

#endif

#endif
