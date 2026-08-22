//
//  MCOMailProvider.m
//  mailcore2
//
//  Created by Robert Widmann on 4/28/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOMailProvider.h"

#include <typeinfo>

#include "MCMailProvider.h"

#import "NSDictionary+MCO.h"
#import "NSArray+MCO.h"
#import "NSString+MCO.h"
#import "NSObject+MCO.h"

@implementation MCOMailProvider {
    mailcore::MailProvider * _provider;
}

#define nativeType mailcore::MailProvider

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

- (mailcore::Object *) mco_mcObject
{
    return _provider;
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::MailProvider * provider = (mailcore::MailProvider *) object;
    return [[[self alloc] initWithMCProvider:provider] autorelease];
}

- (instancetype) initWithInfo:(NSDictionary *)info
{
    self = [super init];
    
    _provider = mailcore::MailProvider::providerWithInfo([info mco_mcHashMap]);
    _provider->retain();
    
    return self;
}

- (instancetype) initWithMCProvider:(mailcore::MailProvider *)provider
{
    self = [super init];
    
    _provider = provider;
    _provider->retain();
    
    return self;
}

MCO_OBJC_SYNTHESIZE_STRING(setIdentifier, identifier);

- (NSArray<MCONetService *> *) imapServices
{
    return MCO_OBJC_BRIDGE_GET(imapServices);
}

- (NSArray<MCONetService *> *) smtpServices
{
    return MCO_OBJC_BRIDGE_GET(smtpServices);
}

- (NSArray<MCONetService *> *) popServices
{
    return MCO_OBJC_BRIDGE_GET(popServices);
}

- (BOOL) matchEmail:(NSString *)email
{
    return _provider->matchEmail(email.mco_mcString);
}

- (BOOL) matchMX:(NSString *)hostname
{
    return _provider->matchMX(hostname.mco_mcString);
}

- (NSString *) sentMailFolderPath
{
    return MCO_OBJC_BRIDGE_GET(sentMailFolderPath);
}

- (NSString *) starredFolderPath
{
    return MCO_OBJC_BRIDGE_GET(starredFolderPath);
}

- (NSString *) allMailFolderPath
{
    return MCO_OBJC_BRIDGE_GET(allMailFolderPath);
}

- (NSString *) trashFolderPath
{
    return MCO_OBJC_BRIDGE_GET(trashFolderPath);
}

- (NSString *) draftsFolderPath
{
    return MCO_OBJC_BRIDGE_GET(draftsFolderPath);
}

- (NSString *) spamFolderPath
{
    return MCO_OBJC_BRIDGE_GET(spamFolderPath);
}

- (NSString *) importantFolderPath
{
    return MCO_OBJC_BRIDGE_GET(importantFolderPath);
}

- (BOOL) isMainFolder:(NSString *)folderPath prefix:(NSString *)prefix
{
    return _provider->isMainFolder(folderPath.mco_mcString, prefix.mco_mcString);
}

@end
