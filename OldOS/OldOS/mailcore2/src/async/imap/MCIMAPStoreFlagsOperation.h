//
//  MCIMAPStoreFlagsOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPSTOREFLAGSOPERATION_H

#define MAILCORE_MCIMAPSTOREFLAGSOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {

    class MAILCORE_EXPORT IMAPStoreFlagsOperation : public IMAPOperation {
    public:
        IMAPStoreFlagsOperation();
        virtual ~IMAPStoreFlagsOperation();
        
        virtual void setUids(IndexSet * uids);
        virtual IndexSet * uids();
        
        virtual void setNumbers(IndexSet * numbers);
        virtual IndexSet * numbers();
        
        virtual void setKind(IMAPStoreFlagsRequestKind kind);
        virtual IMAPStoreFlagsRequestKind kind();
        
        virtual void setFlags(MessageFlag flags);
        virtual MessageFlag flags();
        
        virtual void setCustomFlags(Array * customFlags);
        virtual Array * customFlags();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        IndexSet * mUids;
        IndexSet * mNumbers;
        IMAPStoreFlagsRequestKind mKind;
        MessageFlag mFlags;
        Array * mCustomFlags;
    };
    
}

#endif

#endif
