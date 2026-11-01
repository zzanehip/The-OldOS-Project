//
//  SMTPSendWithDataOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/10/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCSMTPSENDWITHDATAOPERATION_H

#define MAILCORE_MCSMTPSENDWITHDATAOPERATION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCAbstract.h>
#include <MailCore/MCSMTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT SMTPSendWithDataOperation : public SMTPOperation {
    public:
        SMTPSendWithDataOperation();
        virtual ~SMTPSendWithDataOperation();
        
        virtual void setFrom(Address * from);
        virtual Address * from();
        
        virtual void setRecipients(Array * recipients);
        virtual Array * recipients();
        
        virtual void setMessageData(Data * data);
        virtual Data * messageData();

        virtual void setMessageFilepath(String * path);
        virtual String * messageFilepath();

    public: // subclass behavior
        virtual void main();
        virtual void cancel();
    private:
        Data * mMessageData;
        String * mMessageFilepath;
        Array * mRecipients;
        Address * mFrom;
    };
    
}

#endif

#endif
