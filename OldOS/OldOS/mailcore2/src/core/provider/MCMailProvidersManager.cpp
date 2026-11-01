//
//  MCMailProvidersManager.cpp
//  mailcore2
//
//  Created by Robert Widmann on 4/28/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCMailProvidersManager.h"
#include "MCMailProvider.h"
#include "MCJSON.h"

using namespace mailcore;

void MailProvidersManager::init()
{
    mProviders = new HashMap();
}

MailProvidersManager::MailProvidersManager() {
    init();
}

MailProvidersManager::~MailProvidersManager() {
    MC_SAFE_RELEASE(mProviders);
}

MailProvidersManager * MailProvidersManager::sharedManager()
{
    static MailProvidersManager * instance = new MailProvidersManager();
    return instance;
}


MailProvider * MailProvidersManager::providerForEmail(String * email)
{
    MailProvider * result = NULL;
    mc_foreachhashmapValue(MailProvider, provider, mProviders) {
        if (provider->matchEmail(email)) {
            result = provider;
            break;
        }
    }
    
    return result;
}

MailProvider * MailProvidersManager::providerForMX(String * hostname)
{
    MailProvider * result = NULL;
    mc_foreachhashmapValue(MailProvider, provider, mProviders) {
        if (provider->matchMX(hostname)) {
            result = provider;
            break;
        }
    }

    return result;
}

MailProvider * MailProvidersManager::providerForIdentifier(String * identifier)
{
    return (MailProvider *) mProviders->objectForKey(identifier);
}

void MailProvidersManager::registerProviders(HashMap * providers)
{
    mc_foreachhashmapKeyAndValue(String, identifier, HashMap, providerInfo, providers) {
        MailProvider * provider = MailProvider::providerWithInfo(providerInfo);
        provider->setIdentifier(identifier);
        mProviders->setObjectForKey(identifier, provider);
    }
}

void MailProvidersManager::registerProvidersWithFilename(String * filename)
{
    HashMap * providersInfos;
    
    providersInfos = (HashMap *) JSON::objectFromJSONData(Data::dataWithContentsOfFile(filename));
    registerProviders(providersInfos);
}
