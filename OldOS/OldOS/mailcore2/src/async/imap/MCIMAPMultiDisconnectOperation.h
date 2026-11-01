//
//  MCIMAPMultiDisconnectOperation.h
//  mailcore2
//
//  Created by Hoa V. DINH on 11/7/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPMULTIDISCONNECTOPERATION_H

#define MAILCORE_MCIMAPMULTIDISCONNECTOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPMultiDisconnectOperation : public IMAPOperation, public OperationCallback {
    public:
        IMAPMultiDisconnectOperation();
        virtual ~IMAPMultiDisconnectOperation();
        
        virtual void addOperation(IMAPOperation * op);
        
    public: // subclass behavior
        virtual void start();
        
    public: // OperationCallback
        virtual void operationFinished(Operation * op);
        
    private:
        Array * _operations;
        unsigned int _count;
    };
    
}

#endif

#endif