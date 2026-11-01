//
//  MCIMAPDeleteFolderOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPDELETEFOLDEROPERATION_H

#define MAILCORE_MCIMAPDELETEFOLDEROPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPDeleteFolderOperation : public IMAPOperation {
    public:
        IMAPDeleteFolderOperation();
        virtual ~IMAPDeleteFolderOperation();
        
    public: // subclass behavior
        virtual void main();
    };
    
}

#endif

#endif
