//
//  IMAPFetchNamespaceOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPFETCHNAMESPACEOPERATION_H

#define MAILCORE_MCIMAPFETCHNAMESPACEOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPFetchNamespaceOperation : public IMAPOperation {
    public:
        IMAPFetchNamespaceOperation();
        virtual ~IMAPFetchNamespaceOperation();
        
        // Result.
        virtual HashMap * namespaces();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        HashMap * mNamespaces;
        
    };
    
}

#endif

#endif
