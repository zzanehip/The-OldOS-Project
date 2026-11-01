//
//  MCIMAPFolderStatus.h
//  mailcore2
//
//  Created by Sebastian on 6/11/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPFOLDERSTATUS_H

#define MAILCORE_MCIMAPFOLDERSTATUS_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPFolderStatus : public Object {
    public:
        IMAPFolderStatus();
        virtual ~IMAPFolderStatus();
        
        virtual void setUnseenCount(uint32_t unseen);
        virtual uint32_t unseenCount();
        
        virtual void setMessageCount(uint32_t messages);
        virtual uint32_t messageCount();
        
        virtual void setRecentCount(uint32_t recent);
        virtual uint32_t recentCount();
        
        virtual void setUidNext(uint32_t uidNext);
        virtual uint32_t uidNext();
        
        virtual void setUidValidity(uint32_t uidValidity);
        virtual uint32_t uidValidity();
        
        virtual void setHighestModSeqValue(uint64_t highestModSeqValue);
        virtual uint64_t highestModSeqValue();
        
    public: // subclass behavior
        IMAPFolderStatus(IMAPFolderStatus * other);
        virtual Object * copy();		
        virtual String * description();
        
    private:
        uint32_t mUnseenCount;
        uint32_t mMessageCount;
        uint32_t mRecentCount;
        uint32_t mUidNext;
        uint32_t mUidValidity;
        uint64_t mHighestModSeqValue;
        
        void init();
    };
    
}

#endif

#endif

