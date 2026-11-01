//
//  IMAPFetchContentToFileOperation.h
//  mailcore2
//
//  Created by Dmitry Isaikin on 2/08/16.
//  Copyright (c) 2016 MailCore. All rights reserved.
//

#ifndef MAILCORE_IMAPFETCHCONTENTTOFILEOPERATION_H

#define MAILCORE_IMAPFETCHCONTENTTOFILEOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {

    class MAILCORE_EXPORT IMAPFetchContentToFileOperation : public IMAPOperation {
    public:
        IMAPFetchContentToFileOperation();
        virtual ~IMAPFetchContentToFileOperation();

        virtual void setUid(uint32_t uid);
        virtual void setPartID(String * partID);
        virtual void setEncoding(Encoding encoding);
        virtual void setFilename(String * filename);

        virtual void setLoadingByChunksEnabled(bool loadingByChunksEnabled);
        virtual bool isLoadingByChunksEnabled();
        virtual void setChunksSize(uint32_t chunksSize);
        virtual uint32_t chunksSize();
        virtual void setEstimatedSize(uint32_t estimatedSize);
        virtual uint32_t estimatedSize();

    public: // subclass behavior
        virtual void main();

    private:
        uint32_t mUid;
        String * mPartID;
        Encoding mEncoding;
        String * mFilename;
        bool mLoadingByChunksEnabled;
        uint32_t mChunksSize;
        uint32_t mEstimatedSize;
    };

}

#endif

#endif
