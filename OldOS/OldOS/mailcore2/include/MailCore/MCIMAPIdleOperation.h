//
//  IMAPIdleOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPIDLEOPERATION_H

#define MAILCORE_MCIMAPIDLEOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPIdleOperation : public IMAPOperation {
    public:
        IMAPIdleOperation();
        virtual ~IMAPIdleOperation();
        
        virtual void setLastKnownUID(uint32_t uid);
        virtual uint32_t lastKnownUID();
        
        virtual void interruptIdle();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        uint32_t mLastKnownUid;
        bool mSetupSuccess;
        bool mInterrupted;
        pthread_mutex_t mLock;
        void prepare(void * data);
        void unprepare(void * data);
        bool isInterrupted();
    };
    
}

#endif

#endif
