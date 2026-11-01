//
//  MCOPOPMessageInfo.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/30/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOPOPMessageInfo.h"

#include "MCAsyncPOP.h"
#include "MCPOP.h"

#import "MCOUtils.h"

@implementation MCOPOPMessageInfo {
    mailcore::POPMessageInfo * _nativeInfo;
}

#define nativeType mailcore::POPMessageInfo

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
    mailcore::POPMessageInfo * folder = (mailcore::POPMessageInfo *) object;
    return [[[self alloc] initWithMCPOPMessageInfo:folder] autorelease];
}

- (mailcore::Object *) mco_mcObject
{
    return _nativeInfo;
}

- (NSString *) description
{
    return MCO_OBJC_BRIDGE_GET(description);
}

- (instancetype) initWithMCPOPMessageInfo:(mailcore::POPMessageInfo *)info
{
    self = [super init];
    
    _nativeInfo = info;
    _nativeInfo->retain();
    
    return self;
}

- (void) dealloc
{
    MC_SAFE_RELEASE(_nativeInfo);
    [super dealloc];
}

MCO_OBJC_SYNTHESIZE_SCALAR(unsigned int, unsigned int, setIndex, index)
MCO_OBJC_SYNTHESIZE_SCALAR(unsigned int, unsigned int, setSize, size)
MCO_OBJC_SYNTHESIZE_STRING(setUid, uid)

@end
