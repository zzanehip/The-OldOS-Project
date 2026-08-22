//
//  MCIMAPIdentity.cpp
//  mailcore2
//
//  Created by Hoa V. DINH on 8/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPIdentity.h"

using namespace mailcore;

IMAPIdentity::IMAPIdentity()
{
    init();
}

IMAPIdentity::IMAPIdentity(IMAPIdentity * identity)
{
    init();
    mc_foreachhashmapKeyAndValue(String, key, String, value, identity->mValues) {
        mValues->setObjectForKey(key, value);
    }
}

void IMAPIdentity::init()
{
    mValues = new HashMap();
}

IMAPIdentity::~IMAPIdentity()
{
    MC_SAFE_RELEASE(mValues);
}

void IMAPIdentity::setVendor(String * vendor)
{
    setInfoForKey(MCSTR("vendor"), vendor);
}

String * IMAPIdentity::vendor()
{
    return infoForKey(MCSTR("vendor"));
}

void IMAPIdentity::setName(String * name)
{
    setInfoForKey(MCSTR("name"), name);
}

String * IMAPIdentity::name()
{
    return infoForKey(MCSTR("name"));
}

void IMAPIdentity::setVersion(String * version)
{
    setInfoForKey(MCSTR("version"), version);
}

String * IMAPIdentity::version()
{
    return infoForKey(MCSTR("version"));
}

Array * IMAPIdentity::allInfoKeys()
{
    return mValues->allKeys();
}

String * IMAPIdentity::infoForKey(String * key)
{
    return (String *) mValues->objectForKey(key);
}

void IMAPIdentity::setInfoForKey(String * key, String * value)
{
    if (value != NULL) {
        mValues->setObjectForKey(key, value->copy()->autorelease());
    }
    else {
        mValues->removeObjectForKey(key);
    }
}

void IMAPIdentity::removeAllInfos()
{
    mValues->removeAllObjects();
}

Object * IMAPIdentity::copy()
{
    return new IMAPIdentity(this);
}

String * IMAPIdentity::description()
{
    return String::stringWithUTF8Format("<%s:%p %s>", className()->UTF8Characters(), this, MCUTF8DESC(mValues));
}



