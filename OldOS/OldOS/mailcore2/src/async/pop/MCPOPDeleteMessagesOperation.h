//
//  MCPOPDeleteMessagesOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/16/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCPOPDELETEMESSAGESOPERATION_H

#define MAILCORE_MCPOPDELETEMESSAGESOPERATION_H

#include <MailCore/MCPOPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT POPDeleteMessagesOperation : public POPOperation {
    public:
        POPDeleteMessagesOperation();
        virtual ~POPDeleteMessagesOperation();
        
        virtual void setMessageIndexes(IndexSet * indexes);
        virtual IndexSet * messageIndexes();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        IndexSet * mMessageIndexes;
        
    };
    
}

#endif

#endif
