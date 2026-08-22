//
//  MCIMAPDisconnectOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 6/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPDISCONNECTOPERATION_H

#define MAILCORE_MCIMAPDISCONNECTOPERATION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCAbstract.h>
#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPDisconnectOperation : public IMAPOperation {
    public:
        IMAPDisconnectOperation();
        virtual ~IMAPDisconnectOperation();
        
    public: // subclass behavior
        virtual void main();
    };
    
}

#endif

#endif