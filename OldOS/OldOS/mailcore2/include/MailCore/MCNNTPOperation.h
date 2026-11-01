//
//  MCNNTPOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNNTPOPERATION_H

#define MAILCORE_MCNNTPOPERATION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCNNTPProgressCallback.h>

#ifdef __cplusplus

namespace mailcore {
    
    class NNTPAsyncSession;
    class NNTPOperationCallback;
    
    class MAILCORE_EXPORT NNTPOperation : public Operation, public NNTPProgressCallback {
    public:
        NNTPOperation();
        virtual ~NNTPOperation();
        
        virtual void setSession(NNTPAsyncSession * session);
        virtual NNTPAsyncSession * session();
        
        virtual void setNNTPCallback(NNTPOperationCallback * callback);
        virtual NNTPOperationCallback * nntpCallback();
        
        virtual void setError(ErrorCode error);
        virtual ErrorCode error();
        
        virtual void start();
        
    private:
        NNTPAsyncSession * mSession;
        NNTPOperationCallback * mPopCallback;
        ErrorCode mError;
    private:
        virtual void bodyProgress(NNTPSession * session, unsigned int current, unsigned int maximum);
        virtual void bodyProgressOnMainThread(void * context);
        
    };
    
}

#endif

#endif
