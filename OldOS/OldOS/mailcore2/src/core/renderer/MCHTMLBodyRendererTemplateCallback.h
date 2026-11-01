//
//  MCHTMLBodyRendererTemplateCallback.h
//  mailcore2
//
//  Created by Paul Young on 02/07/2013.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCHTMLBODYRENDERERTEMPLATECALLBACK_H

#define MAILCORE_MCHTMLBODYRENDERERTEMPLATECALLBACK_H

#include <MailCore/MCHTMLRendererCallback.h>
#include <MailCore/MCUtils.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT HTMLBodyRendererTemplateCallback : public Object, public HTMLRendererTemplateCallback {
    public:
        virtual String * templateForMainHeader(MessageHeader * header);
    };
    
}

#endif

#endif
