//
//  MCAddressDisplay.cpp
//  testUI
//
//  Created by DINH Viêt Hoà on 1/27/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCAddressDisplay.h"

using namespace mailcore;

String * AddressDisplay::sanitizeDisplayName(String * displayName)
{
    if (displayName->hasPrefix(MCSTR("\"")) && displayName->hasSuffix(MCSTR("\""))) {
        String * unquotedDisplayName = displayName->substringWithRange(RangeMake(1, displayName->length() - 2));
        if (unquotedDisplayName->locationOfString(MCSTR("\"")) != -1) {
            return displayName;
        }
        else {
            return unquotedDisplayName;
        }
    }
    else {
        return displayName;
    }
}

String * AddressDisplay::displayStringForAddress(Address * address)
{
    if (address->displayName() != NULL) {
        return String::stringWithUTF8Format("%s <%s>",
                                            MCUTF8(AddressDisplay::sanitizeDisplayName(address->displayName())),
                                            MCUTF8(address->mailbox()));
    }
    else {
        return address->mailbox();
    }
}

String * AddressDisplay::shortDisplayStringForAddress(Address * address)
{
    if ((address->displayName() != NULL) && (address->displayName()->length() > 0)) {
        return sanitizeDisplayName(address->displayName());
    }
    else if (address->mailbox()) {
        return address->mailbox();
    }
    else {
        return MCSTR("invalid");
    }
}

String * AddressDisplay::veryShortDisplayStringForAddress(Address * address)
{
    if ((address->displayName() != NULL) && (address->displayName()->length() > 0)) {
        Array * components;
        String * senderName;
        
        senderName = sanitizeDisplayName(address->displayName());
        senderName = (String *) senderName->copy()->autorelease();
        
        senderName->replaceOccurrencesOfString(MCSTR(","), MCSTR(" "));
        senderName->replaceOccurrencesOfString(MCSTR("'"), MCSTR(" "));
        senderName->replaceOccurrencesOfString(MCSTR("\""), MCSTR(" "));
        components = senderName->componentsSeparatedByString(MCSTR(" "));
        if (components->count() == 0) {
            return MCLOCALIZEDSTRING(MCSTR("invalid"));
        }
        return (String *) components->objectAtIndex(0);
    }
    else if (address->mailbox()) {
        Array * components = address->mailbox()->componentsSeparatedByString(MCSTR("@"));
        if (components->count() == 0) {
            return MCSTR("");
        }
        return (String *) components->objectAtIndex(0);
    }
    else {
        return MCLOCALIZEDSTRING(MCSTR("invalid"));
    }
}

String * AddressDisplay::displayStringForAddresses(Array * addresses)
{
    String * result = String::string();
    if (addresses == NULL) {
        return result;
    }
    for(unsigned int i = 0 ; i < addresses->count() ; i ++) {
        Address * address = (Address *) addresses->objectAtIndex(i);
        if (i != 0) {
            result->appendString(MCSTR(", "));
        }
        result->appendString(AddressDisplay::displayStringForAddress(address));
    }
    return result;
}

String * AddressDisplay::shortDisplayStringForAddresses(Array * addresses)
{
    String * result = String::string();
    for(unsigned int i = 0 ; i < addresses->count() ; i ++) {
        Address * address = (Address *) addresses->objectAtIndex(i);
        if (i != 0) {
            result->appendString(MCSTR(", "));
        }
        result->appendString(shortDisplayStringForAddress(address));
    }
    return result;
}

String * AddressDisplay::veryShortDisplayStringForAddresses(Array * addresses)
{
    String * result = String::string();
    for(unsigned int i = 0 ; i < addresses->count() ; i ++) {
        Address * address = (Address *) addresses->objectAtIndex(i);
        if (i != 0) {
            result->appendString(MCSTR(", "));
        }
        result->appendString(veryShortDisplayStringForAddress(address));
    }
    return result;
}
