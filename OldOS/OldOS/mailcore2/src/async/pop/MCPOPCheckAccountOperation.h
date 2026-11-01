//
//  MCPOPCheckAccountOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 4/6/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCPOPCHECKACCOUNTOPERATION_H

#define MAILCORE_MCPOPCHECKACCOUNTOPERATION_H

#include <MailCore/MCPOPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT POPCheckAccountOperation : public POPOperation {
    public:
        POPCheckAccountOperation();
        virtual ~POPCheckAccountOperation();
        
    public: // subclass behavior
        virtual void main();
    };
    
}

#endif

#endif
