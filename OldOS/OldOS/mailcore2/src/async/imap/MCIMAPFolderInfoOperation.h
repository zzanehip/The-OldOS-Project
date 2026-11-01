//
//  MCIMAPFolderInfoOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/13/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPFOLDERINFOOPERATION_H

#define MAILCORE_MCIMAPFOLDERINFOOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {

    class IMAPFolderInfo;
    
    class MAILCORE_EXPORT IMAPFolderInfoOperation : public IMAPOperation {
    public:
        IMAPFolderInfoOperation();
        virtual ~IMAPFolderInfoOperation();

        IMAPFolderInfo * info();

    public: // subclass behavior
        virtual void main();
        
    private:

        IMAPFolderInfo * mInfo;

    };

}

#endif

#endif
