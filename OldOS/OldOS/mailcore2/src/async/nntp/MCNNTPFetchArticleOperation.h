//
//  MCNNTPFetchArticleOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNNTPFETCHARTICLEOPERATION_H

#define MAILCORE_MCNNTPFETCHARTICLEOPERATION_H

#include <MailCore/MCNNTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    class MAILCORE_EXPORT NNTPFetchArticleOperation : public NNTPOperation {
    public:
        NNTPFetchArticleOperation();
        virtual ~NNTPFetchArticleOperation();
        
        virtual void setGroupName(String * groupName);
        virtual String * groupName();
        
        virtual void setMessageID(String * groupName);
        virtual String * messageID();
        
        virtual void setMessageIndex(unsigned int messageIndex);
        virtual unsigned int messageIndex();
        
        virtual Data * data();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        String * mGroupName;
        String * mMessageID;
        unsigned int mMessageIndex;
        Data * mData;
        
    };
    
}

#endif

#endif
