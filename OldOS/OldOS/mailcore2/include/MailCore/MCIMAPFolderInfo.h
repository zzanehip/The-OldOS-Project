//
//  MCIMAPFolderInfo.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 12/6/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPFolderInfo_H

#define MAILCORE_MCIMAPFolderInfo_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPFolderInfo : public Object {
    public:
        IMAPFolderInfo();
        virtual ~IMAPFolderInfo();
        
        virtual void setUidNext(uint32_t uidNext);
        virtual uint32_t uidNext();
        
        virtual void setUidValidity(uint32_t uidValidity);
        virtual uint32_t uidValidity();
        
        virtual void setModSequenceValue(uint64_t modSequenceValue);
        virtual uint64_t modSequenceValue();
        
        virtual void setMessageCount(int messageCount);
        virtual int messageCount();
        
        virtual void setFirstUnseenUid(uint32_t firstUnseenUid);
        virtual uint32_t firstUnseenUid();
        
        virtual void setAllowsNewPermanentFlags(bool allowsNewPermanentFlags);
        virtual bool allowsNewPermanentFlags();
        
    public: // subclass behavior
        IMAPFolderInfo(IMAPFolderInfo * other);
        virtual Object * copy();		
        
    private:
        uint32_t mUidNext;
        uint32_t mUidValidity;
        uint64_t mModSequenceValue;
        int mMessageCount;
        uint32_t mFirstUnseenUid;
        bool mAllowsNewPermanentFlags;
        
        void init();
    };
    
}

#endif

#endif

