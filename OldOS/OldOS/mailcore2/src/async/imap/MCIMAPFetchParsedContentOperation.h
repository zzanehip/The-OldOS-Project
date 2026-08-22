//
//  IMAPFetchParsedContentOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_IMAPFETCHPARSEDCONTENTOPERATION_H

#define MAILCORE_IMAPFETCHPARSEDCONTENTOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#include <MailCore/MCRFC822.h>

#ifdef __cplusplus

namespace mailcore {

    class MAILCORE_EXPORT IMAPFetchParsedContentOperation : public IMAPOperation {
    public:
        IMAPFetchParsedContentOperation();
        virtual ~IMAPFetchParsedContentOperation();
        
        virtual void setUid(uint32_t uid);
        virtual uint32_t uid();
        
        virtual void setNumber(uint32_t value);
        virtual uint32_t number();
        
        virtual void setEncoding(Encoding encoding);
        virtual Encoding encoding();
        
        // Result.
        virtual MessageParser * parser();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        uint32_t mUid;
        uint32_t mNumber;
        Encoding mEncoding;
        MessageParser * mParser;
        
    };
    
}

#endif

#endif
