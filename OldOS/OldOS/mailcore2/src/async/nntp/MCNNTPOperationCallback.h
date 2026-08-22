//
//  MCNNTPOperationCallback.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNNTPOPERATIONCALLBACK_H

#define MAILCORE_MCNNTPOPERATIONCALLBACK_H

#include <MailCore/MCUtils.h>

#ifdef __cplusplus

namespace mailcore {
    
    class NNTPOperation;
    
    class MAILCORE_EXPORT NNTPOperationCallback {
    public:
        virtual void bodyProgress(NNTPOperation * session, unsigned int current, unsigned int maximum) {};
    };
    
}

#endif

#endif
