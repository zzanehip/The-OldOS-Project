//
//  MCNNTPPostOperation.h
//  mailcore2
//
//  Created by Daryle Walker on 2/21/16.
//  Copyright © 2016 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCNNTPPOSTOPERATION_H

#define MAILCORE_MCNNTPPOSTOPERATION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCAbstract.h>
#include <MailCore/MCNNTPOperation.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT NNTPPostOperation : public NNTPOperation {
    public:
        NNTPPostOperation();
        virtual ~NNTPPostOperation();
        
        virtual void setMessageData(Data * data);
        virtual Data * messageData();
        
        virtual void setMessageFilepath(String * path);
        virtual String * messageFilepath();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        Data * mMessageData;
        String * mMessageFilepath;
    };
    
}

#endif

#endif
