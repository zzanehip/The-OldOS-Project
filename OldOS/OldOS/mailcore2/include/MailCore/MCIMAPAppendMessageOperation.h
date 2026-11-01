//
//  MCIMAPAppendMessageOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPAPPENDMESSAGEOPERATION_H

#define MAILCORE_MCIMAPAPPENDMESSAGEOPERATION_H

#include <MailCore/MCIMAPOperation.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPAppendMessageOperation : public IMAPOperation {
    public:
        IMAPAppendMessageOperation();
        virtual ~IMAPAppendMessageOperation();
        
        virtual void setMessageData(Data * messageData);
        virtual Data * messageData();

        virtual void setMessageFilepath(String * path);
        virtual String * messageFilepath();

        virtual void setFlags(MessageFlag flags);
        virtual MessageFlag flags();
        
        virtual void setCustomFlags(Array * customFlags);
        virtual Array * customFlags();
        
        virtual void setDate(time_t date);
        virtual time_t date();
        
        virtual uint32_t createdUID();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        Data * mMessageData;
        String * mMessageFilepath;
        MessageFlag mFlags;
        Array * mCustomFlags;
        time_t mDate;
        uint32_t mCreatedUID;
        
    };
    
}

#endif

#endif
