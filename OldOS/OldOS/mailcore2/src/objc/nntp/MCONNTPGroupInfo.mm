//
//  MCONNTPGroupInfo.m
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import "MCONNTPGroupInfo.h"

#include "MCAsyncNNTP.h"
#include "MCNNTP.h"

#import "MCOUtils.h"

@implementation MCONNTPGroupInfo {
    mailcore::NNTPGroupInfo * _nativeInfo;
}

#define nativeType mailcore::NNTPGroupInfo

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
    mailcore::NNTPGroupInfo * groupInfo = (mailcore::NNTPGroupInfo *) object;
    return [[[self alloc] initWithMCNNTPGroupInfo:groupInfo] autorelease];
}

- (mailcore::Object *) mco_mcObject
{
    return _nativeInfo;
}

- (NSString *) description
{
    return MCO_OBJC_BRIDGE_GET(description);
}

- (instancetype) initWithMCNNTPGroupInfo:(mailcore::NNTPGroupInfo *)info
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

MCO_OBJC_SYNTHESIZE_STRING(setName, name)
MCO_OBJC_SYNTHESIZE_SCALAR(unsigned int, unsigned int, setMessageCount, messageCount)

@end
