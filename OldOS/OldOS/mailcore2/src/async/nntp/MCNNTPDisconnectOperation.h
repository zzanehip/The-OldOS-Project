//
//  MCNNTPDisconnectOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNNTPDISCONNECTOPERATION_H

#define MAILCORE_MCNNTPDISCONNECTOPERATION_H

#include <MailCore/MCNNTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT NNTPDisconnectOperation : public NNTPOperation {
    public:
        NNTPDisconnectOperation();
        virtual ~NNTPDisconnectOperation();
        
    public: // subclass behavior
        virtual void main();
    };
    
}

#endif

#endif
