//
//  ResolveProviderUsingMXRecordAsync.h
//  mailcore2
//
//  Created by Christopher Hockley on 29/01/15.
//  Copyright (c) 2015 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCFETCHASYNCMXRECORD_H

#define MAILCORE_MCFETCHASYNCMXRECORD_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT MXRecordResolverOperation : public Operation {
    public:
        MXRecordResolverOperation();
        virtual ~MXRecordResolverOperation();
        
        virtual void setHostname(String * hostname);
        virtual String * hostname();
        
        virtual Array * mxRecords();
        
    public: // subclass behavior
        virtual void main();
        
    private:
        Array * mMXRecords;
        String * mHostname;
    };
}

#endif

#endif
