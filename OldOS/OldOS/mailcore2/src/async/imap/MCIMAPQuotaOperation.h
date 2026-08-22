//
//  MCIMAPQuotaOperation.h
//  mailcore2
//
//  Created by Petro Korenev on 8/2/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPQuotaOperation_H

#define MAILCORE_MCIMAPQuotaOperation_H

#include "MCIMAPOperation.h"

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPQuotaOperation : public IMAPOperation {
    public:
        IMAPQuotaOperation();
        virtual ~IMAPQuotaOperation();
        
        // Result.
        virtual uint32_t limit();
        virtual uint32_t usage();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        uint32_t mLimit;
        uint32_t mUsage;
    };
    
}

#endif

#endif
