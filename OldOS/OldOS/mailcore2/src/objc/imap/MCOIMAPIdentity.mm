//
//  MCOIMAPIdentity.m
//  mailcore2
//
//  Created by Hoa V. DINH on 8/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPIdentity.h"
#import "NSObject+MCO.h"
#import "NSString+MCO.h"

#include "MCIMAPIdentity.h"

#define nativeType mailcore::IMAPIdentity

@implementation MCOIMAPIdentity {
	mailcore::IMAPIdentity * _nativeIdentity;
}

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

- (instancetype) init
{
    mailcore::IMAPIdentity * identity = new mailcore::IMAPIdentity();
    self = [self initWithMCIdentity:identity];
    identity->release();

    return self;
}

- (instancetype) initWithMCIdentity:(mailcore::IMAPIdentity *)identity
{
    self = [super init];
    
    identity->retain();
    _nativeIdentity = identity;
    
    return self;
}

- (void) dealloc
{
    MC_SAFE_RELEASE(_nativeIdentity);
    [super dealloc];
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::IMAPIdentity * identity = (mailcore::IMAPIdentity *) object;
    return [[[self alloc] initWithMCIdentity:identity] autorelease];
}

- (mailcore::Object *) mco_mcObject
{
    return _nativeIdentity;
}

- (id) copyWithZone:(NSZone *)zone
{
    nativeType * nativeObject = (nativeType *) [self mco_mcObject]->copy();
    id result = [[self class] mco_objectWithMCObject:nativeObject];
    MC_SAFE_RELEASE(nativeObject);
    return [result retain];
}

- (NSString *) description
{
    return MCO_OBJC_BRIDGE_GET(description);
}

MCO_OBJC_SYNTHESIZE_STRING(setVendor, vendor)
MCO_OBJC_SYNTHESIZE_STRING(setName, name)
MCO_OBJC_SYNTHESIZE_STRING(setVersion, version)

- (NSArray<NSString *> *) allInfoKeys
{
    return MCO_OBJC_BRIDGE_GET(allInfoKeys);
}

- (NSString *) infoForKey:(NSString *)key
{
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->infoForKey([key mco_mcString]));
}

- (void) setInfo:(NSString *)value forKey:(NSString *)key
{
    MCO_NATIVE_INSTANCE->setInfoForKey([key mco_mcString], [value mco_mcString]);
}

- (void) removeAllInfos
{
    MCO_NATIVE_INSTANCE->removeAllInfos();
}

+ (MCOIMAPIdentity *) identityWithVendor:(NSString *)vendor
                                    name:(NSString *)name
                                 version:(NSString *)version
{
    MCOIMAPIdentity * identity = [[[MCOIMAPIdentity alloc] init] autorelease];
    [identity setVendor:vendor];
    [identity setName:name];
    [identity setVersion:version];
    return identity;
}

@end
