//
//  MCSMTPNoopOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 9/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCSMTPNOOPOPERATION_H

#define MAILCORE_MCSMTPNOOPOPERATION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCAbstract.h>
#include <MailCore/MCSMTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT SMTPNoopOperation : public SMTPOperation {
    public:
        SMTPNoopOperation();
        virtual ~SMTPNoopOperation();
        
    public: // subclass behavior
        virtual void main();
    };
    	
}

#endif

#endif
