//
//  MCNNTPListNewsgroupsMessagesOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNNTPLISTNEWSGROUPSOPERATION_H

#define MAILCORE_MCNNTPLISTNEWSGROUPSOPERATION_H

#include <MailCore/MCNNTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT NNTPListNewsgroupsOperation : public NNTPOperation {
    public:
        NNTPListNewsgroupsOperation();
        virtual ~NNTPListNewsgroupsOperation();
        
        virtual void setListsSubscribed(bool listsSubscribed);
        virtual bool listsSubscribed();
        
        virtual Array * groups();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        bool mListsSuscribed;
        Array * /* NNTPGroupInfo */ mGroups;
    };
    
}

#endif

#endif
