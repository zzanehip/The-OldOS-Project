//
//  MCPOPOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/16/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCPOPOPERATION_H

#define MAILCORE_MCPOPOPERATION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCPOPProgressCallback.h>

#ifdef __cplusplus

namespace mailcore {
    
    class POPAsyncSession;
    class POPOperationCallback;
    
    class MAILCORE_EXPORT POPOperation : public Operation, public POPProgressCallback {
    public:
        POPOperation();
        virtual ~POPOperation();
        
        virtual void setSession(POPAsyncSession * session);
        virtual POPAsyncSession * session();
        
        virtual void setPopCallback(POPOperationCallback * callback);
        virtual POPOperationCallback * popCallback();
        
        virtual void setError(ErrorCode error);
        virtual ErrorCode error();
        
        virtual void start();
        
    private:
        POPAsyncSession * mSession;
        POPOperationCallback * mPopCallback;
        ErrorCode mError;
    private:
        virtual void bodyProgress(POPSession * session, unsigned int current, unsigned int maximum);
        virtual void bodyProgressOnMainThread(void * context);
        
    };
    
}

#endif

#endif
