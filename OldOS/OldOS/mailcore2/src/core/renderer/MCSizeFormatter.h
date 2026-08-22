//
//  MCSizeFormatter.h
//  testUI
//
//  Created by DINH Viêt Hoà on 1/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCSIZEFORMATTER_H

#define MAILCORE_MCSIZEFORMATTER_H

#include <MailCore/MCBaseTypes.h>

#ifdef __cplusplus

namespace mailcore {
    
    class String;
    
    class MAILCORE_EXPORT SizeFormatter : public Object {
    public:
        static String * stringWithSize(unsigned int size);
    };
    
}

#endif

#endif
