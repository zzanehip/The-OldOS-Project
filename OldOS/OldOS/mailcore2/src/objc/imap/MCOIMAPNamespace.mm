//
//  MCOIMAPNamespace.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPNamespace.h"

#include "MCIMAP.h"

#import "MCOUtils.h"

@implementation MCOIMAPNamespace {
    mailcore::IMAPNamespace * _nativeNamespace;
}

#define nativeType mailcore::IMAPNamespace

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

- (id) copyWithZone:(NSZone *)zone
{
    nativeType * nativeObject = (nativeType *) [self mco_mcObject]->copy();
    id result = [[self class] mco_objectWithMCObject:nativeObject];
    MC_SAFE_RELEASE(nativeObject);
    return [result retain];
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::IMAPNamespace * ns = (mailcore::IMAPNamespace *) object;
    return [[[self alloc] initWithMCNamespace:ns] autorelease];
}

- (instancetype) init
{
    mailcore::IMAPNamespace * ns = new mailcore::IMAPNamespace();
    self = [self initWithMCNamespace:ns];
    ns->release();
    
    return self;
}

- (instancetype) initWithMCNamespace:(mailcore::IMAPNamespace *)ns
{
    self = [super init];
    
    _nativeNamespace = ns;
    _nativeNamespace->retain();
    
    return self;
}

- (void) dealloc
{
    MC_SAFE_RELEASE(_nativeNamespace);
    [super dealloc];
}

- (mailcore::Object *) mco_mcObject
{
    return _nativeNamespace;
}

- (NSString *) description
{
    return MCO_OBJC_BRIDGE_GET(description);
}

+ (MCOIMAPNamespace *) namespaceWithPrefix:(NSString *)prefix delimiter:(char)delimiter
{
    return MCO_TO_OBJC(mailcore::IMAPNamespace::namespaceWithPrefix([prefix mco_mcString], delimiter));
}

- (NSString *) mainPrefix
{
    return MCO_OBJC_BRIDGE_GET(mainPrefix);
}

- (char) mainDelimiter
{
    return MCO_NATIVE_INSTANCE->mainDelimiter();
}

- (NSArray<NSString *> *) prefixes
{
    return MCO_OBJC_BRIDGE_GET(prefixes);
}

- (NSString *) pathForComponents:(NSArray<NSString *> *)components
{
    mailcore::Array * mcComponents = MCO_FROM_OBJC(mailcore::Array, components);
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->pathForComponents(mcComponents));
}

- (NSString *) pathForComponents:(NSArray<NSString *> *)components prefix:(NSString *)prefix
{
    mailcore::Array * mcComponents = MCO_FROM_OBJC(mailcore::Array, components);
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->pathForComponentsAndPrefix(mcComponents, [prefix mco_mcString]));
}

- (NSArray<NSString *> *) componentsFromPath:(NSString *)path
{
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->componentsFromPath([path mco_mcString]));
}

- (BOOL) containsFolderPath:(NSString *)path
{
    return MCO_NATIVE_INSTANCE->containsFolderPath([path mco_mcString]);
}

@end
