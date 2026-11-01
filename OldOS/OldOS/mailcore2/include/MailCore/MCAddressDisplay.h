//
//  MCAddressDisplay.h
//  testUI
//
//  Created by DINH Viêt Hoà on 1/27/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCADDRESSDISPLAY_H

#define MAILCORE_MCADDRESSDISPLAY_H

#include <MailCore/MCAbstract.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT AddressDisplay {
    public:
        static String * sanitizeDisplayName(String * displayName);

        static String * displayStringForAddress(Address * address);
        static String * shortDisplayStringForAddress(Address * address);
        static String * veryShortDisplayStringForAddress(Address * address);
        
        static String * displayStringForAddresses(Array * /* Address */ addresses);
        static String * shortDisplayStringForAddresses(Array * /* Address */ addresses);
        static String * veryShortDisplayStringForAddresses(Array * /* Address */ addresses);
    };
    
};

#endif

#endif
