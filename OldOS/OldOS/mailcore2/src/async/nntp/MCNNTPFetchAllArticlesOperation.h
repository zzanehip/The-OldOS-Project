//
//  MCNNTPFetchAllArticlesOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNNTPFETCHARTICLESOPERATION_H

#define MAILCORE_MCNNTPFETCHARTICLESOPERATION_H

#include <MailCore/MCNNTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT NNTPFetchAllArticlesOperation : public NNTPOperation {
    public:
        NNTPFetchAllArticlesOperation();
        virtual ~NNTPFetchAllArticlesOperation();
        
        virtual void setGroupName(String * groupName);
        virtual String * groupName();
        
        virtual IndexSet * articles();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        String * mGroupName;
        IndexSet * mArticles;
    };
    
}

#endif

#endif
