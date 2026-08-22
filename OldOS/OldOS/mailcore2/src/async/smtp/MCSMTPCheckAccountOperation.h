//
//  MCSMTPCheckAccountOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCSMTPCHECKACCOUNTOPERATION_H

#define MAILCORE_MCSMTPCHECKACCOUNTOPERATION_H

#include <MailCore/MCSMTPOperation.h>
#include <MailCore/MCAbstract.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT SMTPCheckAccountOperation : public SMTPOperation {
    public:
        SMTPCheckAccountOperation();
        virtual ~SMTPCheckAccountOperation();
        
        virtual void setFrom(Address * from);
        virtual Address * from();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        Address * mFrom;
        
    };

}

#endif

#endif
