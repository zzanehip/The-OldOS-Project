//
//  MCIMAPFolderStatusOperation.h
//  mailcore2
//
//  Created by Sebastian on 6/5/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//


#ifndef MAILCORE_MCIMAPFOLDERSTATUSOPERATION_H

#define MAILCORE_MCIMAPFOLDERSTATUSOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class IMAPFolderStatus;
    
    class MAILCORE_EXPORT IMAPFolderStatusOperation : public IMAPOperation {
    public:
        IMAPFolderStatusOperation();
        virtual ~IMAPFolderStatusOperation();
        
        // Results.
        virtual IMAPFolderStatus * status();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        IMAPFolderStatus * mStatus;
    };
    
}

#endif

#endif
