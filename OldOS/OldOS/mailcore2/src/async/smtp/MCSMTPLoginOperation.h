//
//  MCSMTPLoginOperation.h
//  mailcore2
//
//  Created by Hironori Yoshida on 10/29/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCSMTPLOGINOPERATION_H

#define MAILCORE_MCSMTPLOGINOPERATION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCAbstract.h>
#include <MailCore/MCSMTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT SMTPLoginOperation : public SMTPOperation {
    public:
        SMTPLoginOperation();
        virtual ~SMTPLoginOperation();
        
    public: // subclass behavior
        virtual void main();
    };
    	
}

#endif

#endif
