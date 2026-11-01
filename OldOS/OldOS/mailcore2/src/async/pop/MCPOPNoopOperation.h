//
//  MCPOPNoopOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 9/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCPOPNOOPOPERATION_H

#define MAILCORE_MCPOPNOOPOPERATION_H

#include <MailCore/MCPOPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT POPNoopOperation : public POPOperation {
    public:
        POPNoopOperation();
        virtual ~POPNoopOperation();
        
    public: // subclass behavior
        virtual void main();
    };
    
}

#endif

#endif
