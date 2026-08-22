//
//  IMAPFetchContentOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_IMAPFETCHCONTENTOPERATION_H

#define MAILCORE_IMAPFETCHCONTENTOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPFetchContentOperation : public IMAPOperation {
    public:
        IMAPFetchContentOperation();
        virtual ~IMAPFetchContentOperation();
        
        virtual void setUid(uint32_t uid);
        virtual uint32_t uid();
        
        virtual void setNumber(uint32_t value);
        virtual uint32_t number();
        
        virtual void setPartID(String * partID);
        virtual String * partID();
        
        virtual void setEncoding(Encoding encoding);
        virtual Encoding encoding();
        
        // Result.
        virtual Data * data();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        uint32_t mUid;
        uint32_t mNumber;
        String * mPartID;
        Encoding mEncoding;
        Data * mData;
        
    };
    
}

#endif

#endif
