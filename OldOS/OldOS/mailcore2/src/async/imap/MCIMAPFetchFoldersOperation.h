//
//  MCIMAPFetchFoldersOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPFETCHFOLDERSOPERATION_H

#define MAILCORE_MCIMAPFETCHFOLDERSOPERATION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPFetchFoldersOperation : public IMAPOperation {
    public:
        IMAPFetchFoldersOperation();
        virtual ~IMAPFetchFoldersOperation();
        
        virtual void setFetchSubscribedEnabled(bool enabled);
        virtual bool isFetchSubscribedEnabled();
        
        // Result.
        virtual Array * /* IMAPFolder */ folders();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        bool mFetchSubscribedEnabled;
        Array * mFolders;
        
    };
    
}

#endif

#endif
