//
//  MCIMAPNoopOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 9/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPNOOPOPERATION_H

#define MAILCORE_MCIMAPNOOPOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPNoopOperation : public IMAPOperation {
    public:
        IMAPNoopOperation();
        virtual ~IMAPNoopOperation();
        
    public: // subclass behavior
        virtual void main();
    };
    
}

#endif

#endif
