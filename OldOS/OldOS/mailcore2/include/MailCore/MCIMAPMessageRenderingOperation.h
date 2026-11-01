//
//  MCIMAPMessageRenderingOperation.h
//  mailcore2
//
//  Created by Paul Young on 27/06/2013.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPMessageRenderingOperation_H

#define MAILCORE_MCIMAPMessageRenderingOperation_H

#include <MailCore/MCIMAPOperation.h>
#include <MailCore/MCIMAPMessage.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPMessageRenderingOperation : public IMAPOperation {
    public:
        IMAPMessageRenderingOperation();
        virtual ~IMAPMessageRenderingOperation();
        
        virtual void setRenderingType(IMAPMessageRenderingType type);
        virtual IMAPMessageRenderingType renderingType();
        
        virtual void setMessage(IMAPMessage * message);
        virtual IMAPMessage * message();
        
        // Result.
        virtual String * result();
        
    public: // subclass behavior
        virtual void main();
    
    private:
        IMAPMessageRenderingType mRenderingType;
        String * mResult;
        IMAPMessage * mMessage;
        
    };
    
}

#endif

#endif
