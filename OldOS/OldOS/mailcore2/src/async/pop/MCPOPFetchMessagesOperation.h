//
//  MCPOPFetchMessagesOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/16/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCPOPFETCHMESSAGESOPERATION_H

#define MAILCORE_MCPOPFETCHMESSAGESOPERATION_H

#include <MailCore/MCPOPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT POPFetchMessagesOperation : public POPOperation {
    public:
        POPFetchMessagesOperation();
        virtual ~POPFetchMessagesOperation();
        
        virtual Array * /* POPMessageInfo */ messages();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        Array * /* POPMessageInfo */ mMessages;
    };
    
}

#endif

#endif
