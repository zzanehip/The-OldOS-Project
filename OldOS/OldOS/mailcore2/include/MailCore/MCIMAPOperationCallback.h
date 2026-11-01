//
//  MCIMAPOperationCallback.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPOPERATIONCALLBACK_H

#define MAILCORE_MCIMAPOPERATIONCALLBACK_H

#include <MailCore/MCUtils.h>

#ifdef __cplusplus

namespace mailcore {
    
    class IMAPOperation;
    
    class MAILCORE_EXPORT IMAPOperationCallback {
    public:
        virtual void bodyProgress(IMAPOperation * session, unsigned int current, unsigned int maximum) {};
        virtual void itemProgress(IMAPOperation * session, unsigned int current, unsigned int maximum) {};
    };
    
}

#endif

#endif
