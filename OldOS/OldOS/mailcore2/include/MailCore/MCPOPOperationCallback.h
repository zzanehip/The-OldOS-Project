//
//  MCPOPOperationCallback.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/16/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCPOPOPERATIONCALLBACK_H

#define MAILCORE_MCPOPOPERATIONCALLBACK_H

#include <MailCore/MCUtils.h>

#ifdef __cplusplus

namespace mailcore {
    
    class POPOperation;
    
    class MAILCORE_EXPORT POPOperationCallback {
    public:
        virtual void bodyProgress(POPOperation * session, unsigned int current, unsigned int maximum) {};
    };
    
}

#endif

#endif
