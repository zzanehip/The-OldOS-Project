//
//  MCIMAPIdentity.h
//  mailcore2
//
//  Created by Hoa V. DINH on 8/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPIDENTITY_H

#define MAILCORE_MCIMAPIDENTITY_H

#include <MailCore/MCBaseTypes.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPIdentity : public Object {
    public:
        
        IMAPIdentity();
        virtual ~IMAPIdentity();

        virtual void setVendor(String * vendor);
        virtual String * vendor();
        
        virtual void setName(String * name);
        virtual String * name();
        
        virtual void setVersion(String * version);
        virtual String * version();

        virtual void removeAllInfos();
        
        virtual Array * allInfoKeys();
        virtual String * infoForKey(String * key);
        virtual void setInfoForKey(String * key, String * value);
        
    public: // subclass behavior
        IMAPIdentity(IMAPIdentity * identity);
        virtual Object * copy();
        virtual String * description();
        
    private:
        HashMap * mValues;
        
        void init();
    };
    
}

#endif

#endif

