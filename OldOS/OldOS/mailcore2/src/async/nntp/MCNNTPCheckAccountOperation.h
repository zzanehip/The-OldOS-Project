//
//  MCNNTPCheckAccountOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNNTPCHECKACCOUNTOPERATION_H

#define MAILCORE_MCNNTPCHECKACCOUNTOPERATION_H

#include <MailCore/MCNNTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT NNTPCheckAccountOperation : public NNTPOperation {
    public:
        NNTPCheckAccountOperation();
        virtual ~NNTPCheckAccountOperation();
        
    public: // subclass behavior
        virtual void main();
    };
    
}

#endif

#endif
