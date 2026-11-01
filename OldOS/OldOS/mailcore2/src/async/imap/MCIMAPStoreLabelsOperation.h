//
//  MCIMAPStoreLabelsOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPSTORELABELSOPERATION_H

#define MAILCORE_MCIMAPSTORELABELSOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPStoreLabelsOperation : public IMAPOperation {
    public:
        IMAPStoreLabelsOperation();
        virtual ~IMAPStoreLabelsOperation();
        
        virtual void setUids(IndexSet * uids);
        virtual IndexSet * uids();
        
        virtual void setNumbers(IndexSet * numbers);
        virtual IndexSet * numbers();
        
        virtual void setKind(IMAPStoreFlagsRequestKind kind);
        virtual IMAPStoreFlagsRequestKind kind();
        
        virtual void setLabels(Array * /* String */ labels);
        virtual Array * /* String */ labels();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        IndexSet * mUids;
        IndexSet * mNumbers;
        IMAPStoreFlagsRequestKind mKind;
        Array * /* String */ mLabels;
        
    };
    
}

#endif

#endif
