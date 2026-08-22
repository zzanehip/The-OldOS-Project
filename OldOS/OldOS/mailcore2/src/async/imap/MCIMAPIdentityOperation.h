//
//  IMAPIdentityOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPIDENTITYOPERATION_H

#define MAILCORE_MCIMAPIDENTITYOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class IMAPIdentity;
    
    class MAILCORE_EXPORT IMAPIdentityOperation : public IMAPOperation {
    public:
        IMAPIdentityOperation();
        virtual ~IMAPIdentityOperation();
        
        virtual void setClientIdentity(IMAPIdentity * identity);
        virtual IMAPIdentity * clientIdentity();
        
        // Result.
        virtual IMAPIdentity * serverIdentity();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        IMAPIdentity * mClientIdentity;
        IMAPIdentity * mServerIdentity;
        
    };
    
}

#endif

#endif
