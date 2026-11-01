//
//  MCNNTPFetchHeaderOperation.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNNTPFETCHHEADEROPERATION_H

#define MAILCORE_MCNNTPFETCHHEADEROPERATION_H

#include <MailCore/MCNNTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MessageHeader;
    
    class MAILCORE_EXPORT NNTPFetchHeaderOperation : public NNTPOperation {
    public:
        NNTPFetchHeaderOperation();
        virtual ~NNTPFetchHeaderOperation();
        
        virtual void setGroupName(String * groupName);
        virtual String * groupName();
        
        virtual void setMessageIndex(unsigned int messageIndex);
        virtual unsigned int messageIndex();
        
        virtual MessageHeader * header();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        String * mGroupName;
        unsigned int mMessageIndex;
        MessageHeader * mHeader;
        
    };
    
}

#endif

#endif
