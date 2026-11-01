//
//  MCIMAPSyncResult.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/3/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPSYNCRESULT_H

#define MAILCORE_MCIMAPSYNCRESULT_H

#include <MailCore/MCBaseTypes.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPSyncResult : public Object {
    public:
        IMAPSyncResult();
        virtual ~IMAPSyncResult();
        
        virtual void setModifiedOrAddedMessages(Array * /* IMAPMessage */ messages);
        virtual Array * /* IMAPMessage */ modifiedOrAddedMessages();
        
        virtual void setVanishedMessages(IndexSet * vanishedMessages);
        virtual IndexSet * vanishedMessages();
        
    private:
        Array * /* IMAPMessage */ mModifiedOrAddedMessages;
        IndexSet * mVanishedMessages;
    };
    
}

#endif

#endif
