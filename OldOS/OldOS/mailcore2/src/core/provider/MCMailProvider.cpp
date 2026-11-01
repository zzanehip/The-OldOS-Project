//
//  MCMailProvider.cpp
//  mailcore2
//
//  Created by Robert Widmann on 4/28/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCMailProvider.h"
#include "MCNetService.h"
#include "MCIterator.h"
#include "MCJSON.h"

#ifdef _MSC_VER
#include <unicode/uregex.h>
#include <unicode/utext.h>
#include <unicode/utypes.h>
#include <unicode/localpointer.h>
#include <unicode/parseerr.h>
#else
#include <regex.h>
#endif

using namespace mailcore;

void MailProvider::init()
{
    mIdentifier = NULL;
    mImapServices = new Array();
    mSmtpServices = new Array();
    mPopServices = new Array();
    mDomainMatch = new Array();
    mDomainExclude = new Array();
    mMxMatch = new Array();
    mMailboxPaths = NULL;
}

MailProvider::MailProvider()
{
    init();
}

MailProvider::MailProvider(MailProvider * other)
{
    init();
    MC_SAFE_REPLACE_COPY(String, mIdentifier, other->mIdentifier);
    MC_SAFE_REPLACE_COPY(Array, mImapServices, other->mImapServices);
    MC_SAFE_REPLACE_COPY(Array, mSmtpServices, other->mSmtpServices);
    MC_SAFE_REPLACE_COPY(Array, mPopServices, other->mPopServices);
    MC_SAFE_REPLACE_COPY(Array, mDomainMatch, other->mDomainMatch);
    MC_SAFE_REPLACE_COPY(Array, mDomainExclude, other->mDomainExclude);
    MC_SAFE_REPLACE_COPY(Array, mMxMatch, other->mMxMatch);
    MC_SAFE_REPLACE_COPY(HashMap, mMailboxPaths, other->mMailboxPaths);
}

MailProvider::~MailProvider()
{
    MC_SAFE_RELEASE(mImapServices);
    MC_SAFE_RELEASE(mSmtpServices);
    MC_SAFE_RELEASE(mPopServices);
    MC_SAFE_RELEASE(mMxMatch);
    MC_SAFE_RELEASE(mDomainMatch);
    MC_SAFE_RELEASE(mDomainExclude);
    MC_SAFE_RELEASE(mMailboxPaths);
    MC_SAFE_RELEASE(mIdentifier);
}

MailProvider * MailProvider::providerWithInfo(HashMap * info)
{
    MailProvider * provider = new MailProvider();
    provider->fillWithInfo(info);
    provider->autorelease();
    return provider;
}

void MailProvider::fillWithInfo(HashMap * info)
{
    Array * imapInfos;
    Array * smtpInfos;
    Array * popInfos;
    HashMap * serverInfo;
    
    MC_SAFE_RELEASE(mDomainMatch);
    if (info->objectForKey(MCSTR("domain-match")) != NULL) {
        mDomainMatch = (Array *) info->objectForKey(MCSTR("domain-match"))->retain();
    }
    MC_SAFE_RELEASE(mDomainExclude);
    if (info->objectForKey(MCSTR("domain-exclude")) != NULL) {
        mDomainExclude = (Array *) info->objectForKey(MCSTR("domain-exclude"))->retain();
    }
    MC_SAFE_RELEASE(mMailboxPaths);
    if (info->objectForKey(MCSTR("mailboxes")) != NULL) {
        mMailboxPaths = (HashMap *) info->objectForKey(MCSTR("mailboxes"))->retain();
    }
    MC_SAFE_RELEASE(mMxMatch);
    if (info->objectForKey(MCSTR("mx-match")) != NULL) {
        mMxMatch = (Array *) info->objectForKey(MCSTR("mx-match"))->retain();
    }
    
    serverInfo = (HashMap *) info->objectForKey(MCSTR("servers"));
    if (serverInfo == NULL) {
        MCLog("servers key missing from provider %s", MCUTF8DESC(info));
    }
    MCAssert(serverInfo != NULL);
    imapInfos = (Array *) serverInfo->objectForKey(MCSTR("imap"));
    smtpInfos = (Array *) serverInfo->objectForKey(MCSTR("smtp"));
    popInfos = (Array *) serverInfo->objectForKey(MCSTR("pop"));
    
    mImapServices->removeAllObjects();
    mc_foreacharray(HashMap, imapInfo, imapInfos) {
        NetService * service = NetService::serviceWithInfo(imapInfo);
        mImapServices->addObject(service);
    }
    
    mSmtpServices->removeAllObjects();
    mc_foreacharray(HashMap, smtpInfo, smtpInfos) {
        NetService * service = NetService::serviceWithInfo(smtpInfo);
        mSmtpServices->addObject(service);
    }
    
    mPopServices->removeAllObjects();
    mc_foreacharray(HashMap, popInfo, popInfos) {
        NetService * service = NetService::serviceWithInfo(popInfo);
        mPopServices->addObject(service);
    }
}

void MailProvider::setIdentifier(String * identifier)
{
    MC_SAFE_REPLACE_COPY(String, mIdentifier, identifier);
}

String * MailProvider::identifier()
{
    return mIdentifier;
}

Array * MailProvider::imapServices()
{
    return mImapServices;
}

Array * MailProvider::smtpServices()
{
    return mSmtpServices;
}

Array * MailProvider::popServices()
{
    return mPopServices;
}

bool MailProvider::matchEmail(String * email)
{
    Array * components;
    String * domain;
    
    components = email->componentsSeparatedByString(MCSTR("@"));
    if (components->count() < 2)
        return false;
    
    domain = (String *) components->lastObject();

    bool matchExcludeDomain = false;
    mc_foreacharray(String, exclude, mDomainExclude) {
        if (matchDomain(exclude, domain)){
            matchExcludeDomain = true;;
            break;
        }
    }
    if (matchExcludeDomain) {
        return false;
    }

    bool matchValidDomain = false;
    mc_foreacharray(String, match, mDomainMatch) {
        if (matchDomain(match, domain)){
            matchValidDomain = true;
            break;
        }
    }
    if (matchValidDomain) {
        return true;
    }

    return false;
}

bool MailProvider::matchMX(String * hostname)
{
    bool result = false;
    mc_foreacharray(String, match, mMxMatch) {
        if (matchDomain(match, hostname)){
            result = true;
            break;
        }
    }

    return result;
}

bool MailProvider::matchDomain(String * match, String * domain)
{
#ifdef _MSC_VER
    UParseError error;
    UErrorCode code = U_ZERO_ERROR;
    URegularExpression * r = uregex_open(match->unicodeCharacters(), match->length(), UREGEX_CASE_INSENSITIVE, &error, &code);
    if (code != U_ZERO_ERROR) {
        uregex_close(r);
        return false;
    }
    uregex_setText(r, domain->unicodeCharacters(), domain->length(), &code);
    if (code != U_ZERO_ERROR) {
        uregex_close(r);
        return false;
    }

	bool matched = uregex_matches(r, 0, &code);
    if (code != U_ZERO_ERROR) {
        uregex_close(r);
        return false;
    }

    uregex_close(r);

    return matched;
#else
    const char * cDomain;
    regex_t r;
    bool matched;  

    cDomain = domain->UTF8Characters();
    match = String::stringWithUTF8Format("^%s$", match->UTF8Characters());
    matched = false;

    if (regcomp(&r, match->UTF8Characters(), REG_EXTENDED | REG_ICASE | REG_NOSUB) != 0){
        return matched;
    }

    if (regexec(&r, cDomain, 0, NULL, 0) == 0) {
        matched = true;
    }

    regfree(&r);

    return matched;
#endif
}

String * MailProvider::sentMailFolderPath()
{
    if (mMailboxPaths == NULL)
        return NULL;
    return (String *) mMailboxPaths->objectForKey(MCSTR("sentmail"));
}

String * MailProvider::starredFolderPath()
{
    if (mMailboxPaths == NULL)
        return NULL;
    return (String *) mMailboxPaths->objectForKey(MCSTR("starred"));
}

String * MailProvider::allMailFolderPath()
{
    if (mMailboxPaths == NULL)
        return NULL;
    return (String *) mMailboxPaths->objectForKey(MCSTR("allmail"));
}

String * MailProvider::trashFolderPath()
{
    if (mMailboxPaths == NULL)
        return NULL;
    return (String *) mMailboxPaths->objectForKey(MCSTR("trash"));
}

String * MailProvider::draftsFolderPath()
{
    if (mMailboxPaths == NULL)
        return NULL;
    return (String *) mMailboxPaths->objectForKey(MCSTR("drafts"));
}

String * MailProvider::spamFolderPath()
{
    if (mMailboxPaths == NULL)
        return NULL;
    return (String *) mMailboxPaths->objectForKey(MCSTR("spam"));
}

String * MailProvider::importantFolderPath()
{
    if (mMailboxPaths == NULL)
        return NULL;
    return (String *) mMailboxPaths->objectForKey(MCSTR("important"));
}

bool MailProvider::isMainFolder(String * folderPath, String * prefix)
{
    bool result = false;
    mc_foreachhashmapValue(String, path, mMailboxPaths) {
        String * fullPath;
        
        if (prefix != NULL) {
            fullPath = prefix->stringByAppendingString((String *) path);
        }
        else {
            fullPath = path;
        }
        
        if (fullPath->isEqual(folderPath)) {
            result = true;
            break;
        }
    }
    
    return result;
}

String * MailProvider::description()
{
    return String::stringWithUTF8Format("<%s:%p, %s>", className()->UTF8Characters(), this, MCUTF8(mIdentifier));
}

Object * MailProvider::copy()
{
    return new MailProvider(this);
}

