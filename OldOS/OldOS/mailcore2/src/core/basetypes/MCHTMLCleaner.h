//
//  HTMLCleaner.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 2/3/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_HTMLCLEANER_H

#define MAILCORE_HTMLCLEANER_H

#include <MailCore/MCString.h>
#include <MailCore/MCUtils.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT HTMLCleaner {
    public:
        static String * cleanHTML(String * input);
    };
    
}

#endif

#endif
