//
//  MCHTMLRendererIMAPDataCallback.h
//  mailcore2
//
//  Created by Paul Young on 06/07/2013.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCHTMLRENDERERIMAPDATACALLBACK_H

#define MAILCORE_MCHTMLRENDERERIMAPDATACALLBACK_H

#include "MCHTMLRendererCallback.h"
#include <MailCore/MCUtils.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT HTMLRendererIMAPDataCallback : public Object, public HTMLRendererIMAPCallback {
    public:
        HTMLRendererIMAPDataCallback(IMAPSession * session, uint32_t uid);
        
        virtual Data * dataForIMAPPart(String * folder, IMAPPart * part);
        virtual ErrorCode error();
    
    private:
        IMAPSession * mSession;
        uint32_t mUid;
        ErrorCode mError;
    };
    
}

#endif

#endif
