//
//  MCIMAPCopyMessagesOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPCOPYMESSAGESOPERATION_H

#define MAILCORE_MCIMAPCOPYMESSAGESOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPCopyMessagesOperation : public IMAPOperation {
    public:
        IMAPCopyMessagesOperation();
        virtual ~IMAPCopyMessagesOperation();
        
        virtual void setDestFolder(String * destFolder);
        virtual String * destFolder();
        
        virtual void setUids(IndexSet * uids);
        virtual IndexSet * uids();
        
        // Result.
        virtual HashMap * uidMapping();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        IndexSet * mUids;
        String * mDestFolder;
        HashMap * mUidMapping;
    };
    
}

#endif

#endif
