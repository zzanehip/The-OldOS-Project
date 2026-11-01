//
//  IMAPSearchOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPSEARCHOPERATION_H

#define MAILCORE_MCIMAPSEARCHOPERATION_H

#include <MailCore/MCIMAPOperation.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {
    
    class IMAPSearchExpression;
    
    class MAILCORE_EXPORT IMAPSearchOperation : public IMAPOperation {
    public:
        IMAPSearchOperation();
        virtual ~IMAPSearchOperation();
        
        virtual void setSearchKind(IMAPSearchKind kind);
        virtual IMAPSearchKind searchKind();
        
        virtual void setSearchString(String * searchString);
        virtual String * searchString();
        
        virtual void setSearchExpression(IMAPSearchExpression * expression);
        virtual IMAPSearchExpression * searchExpression();
        
        // Result.
        virtual IndexSet * uids();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        IMAPSearchKind mKind;
        String * mSearchString;
        IMAPSearchExpression * mExpression;
        IndexSet * mUids;
        
    };
    
}

#endif

#endif
