//
//  MCIMAPCreateFolderOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPCREATEFOLDEROPERATION_H

#define MAILCORE_MCIMAPCREATEFOLDEROPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPCreateFolderOperation : public IMAPOperation {
    public:
        IMAPCreateFolderOperation();
        virtual ~IMAPCreateFolderOperation();
        
    public: // subclass behavior
        virtual void main();
    };
    
}

#endif

#endif
