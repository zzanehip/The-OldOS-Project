//
//  NNTPFetchOverviewOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 10/21/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNNTPFETCHOVERVIEWOPERATION_H

#define MAILCORE_MCNNTPFETCHOVERVIEWOPERATION_H

#include <MailCore/MCNNTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT NNTPFetchOverviewOperation : public NNTPOperation {
    public:
        NNTPFetchOverviewOperation();
        virtual ~NNTPFetchOverviewOperation();
        
        virtual void setIndexes(IndexSet * indexes);
        virtual IndexSet * indexes();
        
        virtual void setGroupName(String * groupName);
        virtual String * groupName();
        
        virtual Array * articles();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        IndexSet * mIndexes;
        String * mGroupName;
        Array * /* MessageHeader */ mArticles;
    };
    
}

#endif

#endif
