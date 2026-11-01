//
//  MCNull.h
//  hermes
//
//  Created by DINH Viêt Hoà on 4/9/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNULL_H

#define MAILCORE_MCNULL_H

#include <MailCore/MCObject.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT Null : public Object {
    public:
        static Null * null();
    };
    
}

#endif

#endif
