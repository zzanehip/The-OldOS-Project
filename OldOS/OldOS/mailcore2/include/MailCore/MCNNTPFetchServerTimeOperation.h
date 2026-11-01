//
//  MCNNTPFetchServerTimeOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 10/21/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNNTPFETCHSERVERTIMEOPERATION_H

#define MAILCORE_MCNNTPFETCHSERVERTIMEOPERATION_H

#include <MailCore/MCNNTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT NNTPFetchServerTimeOperation : public NNTPOperation {
    public:
        NNTPFetchServerTimeOperation();
        virtual ~NNTPFetchServerTimeOperation();
        
        virtual time_t time();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        time_t mTime;
    };
    
}

#endif

#endif
