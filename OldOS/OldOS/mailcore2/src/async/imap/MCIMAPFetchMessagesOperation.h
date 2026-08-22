//
//  IMAPFetchMessagesOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPFETCHMESSAGESOPERATION_H

#define MAILCORE_MCIMAPFETCHMESSAGESOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPFetchMessagesOperation : public IMAPOperation {
    public:
        IMAPFetchMessagesOperation();
        virtual ~IMAPFetchMessagesOperation();
        
        virtual void setFetchByUidEnabled(bool enabled);
        virtual bool isFetchByUidEnabled();
        
        virtual void setIndexes(IndexSet * indexes);
        virtual IndexSet * indexes();
        
        virtual void setModSequenceValue(uint64_t modseq);
        virtual uint64_t modSequenceValue();
        
        virtual void setKind(IMAPMessagesRequestKind kind);
        virtual IMAPMessagesRequestKind kind();
        
        virtual void setExtraHeaders(Array * extraHeaders);
        virtual Array * extraHeaders();
        
        // Result.
        virtual Array * /* IMAPMessage */ messages();
        virtual IndexSet * vanishedMessages();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        bool mFetchByUidEnabled;
        IndexSet * mIndexes;
        IMAPMessagesRequestKind mKind;
        Array * /* String */ mExtraHeaders;
        Array * /* IMAPMessage */ mMessages;
        IndexSet * mVanishedMessages;
        uint64_t mModSequenceValue;
        
    };
    
}

#endif

#endif
