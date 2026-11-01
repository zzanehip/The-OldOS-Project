//
//  MCOIMAPNamespaceItem.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPNamespaceItem.h"

#include "MCIMAP.h"

#import "MCOUtils.h"

@implementation MCOIMAPNamespaceItem {
    mailcore::IMAPNamespaceItem * _nativeItem;
}

#define nativeType mailcore::IMAPNamespaceItem

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
    mailcore::IMAPNamespaceItem * item = (mailcore::IMAPNamespaceItem *) object;
    return [[[self alloc] initWithMCNamespaceItem:item] autorelease];
}

- (instancetype) init
{
    mailcore::IMAPNamespaceItem * item = new mailcore::IMAPNamespaceItem();
    self = [self initWithMCNamespaceItem:item];
    item->release();
    
    return self;
}

- (instancetype) initWithMCNamespaceItem:(mailcore::IMAPNamespaceItem *)item
{
    self = [super init];
    
    _nativeItem = item;
    _nativeItem->retain();
    
    return self;
}

- (void) dealloc
{
    MC_SAFE_RELEASE(_nativeItem);
    [super dealloc];
}

- (mailcore::Object *) mco_mcObject
{
    return _nativeItem;
}

- (NSString *) description
{
    return MCO_OBJC_BRIDGE_GET(description);
}

MCO_OBJC_SYNTHESIZE_STRING(setPrefix, prefix)
MCO_OBJC_SYNTHESIZE_SCALAR(char, char, setDelimiter, delimiter)

- (NSString *) pathForComponents:(NSArray<NSString *> *)components
{
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->pathForComponents(MCO_FROM_OBJC(mailcore::Array, components)));
}

- (NSArray<NSString *> *) componentsForPath:(NSString *)path
{
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->componentsForPath([path mco_mcString]));
}

- (BOOL) containsFolder:(NSString *)folder
{
    return MCO_NATIVE_INSTANCE->containsFolder([folder mco_mcString]);
}

@end
