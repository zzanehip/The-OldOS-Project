//
//  MCOIMAPFolderInfo.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPFolderInfo.h"
#import "NSObject+MCO.h"

#include "MCIMAPFolderInfo.h"

#define nativeType mailcore::IMAPFolderInfo

@implementation MCOIMAPFolderInfo {
    mailcore::IMAPFolderInfo * _nativeInfo;
}

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

- (instancetype) initWithMCFolderInfo:(mailcore::IMAPFolderInfo *)info
{
    self = [super init];

    info->retain();
    _nativeInfo = info;

    return self;
}

- (void) dealloc
{
    MC_SAFE_RELEASE(_nativeInfo);
    [super dealloc];
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::IMAPFolderInfo * info = (mailcore::IMAPFolderInfo *) object;
    return [[[self alloc] initWithMCFolderInfo:info] autorelease];
}

- (mailcore::Object *) mco_mcObject
{
    return _nativeInfo;
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

MCO_OBJC_SYNTHESIZE_SCALAR(uint32_t, uint32_t, setUidNext, uidNext)
MCO_OBJC_SYNTHESIZE_SCALAR(uint32_t, uint32_t, setUidValidity, uidValidity)
MCO_OBJC_SYNTHESIZE_SCALAR(uint64_t, uint64_t, setModSequenceValue, modSequenceValue)
MCO_OBJC_SYNTHESIZE_SCALAR(int, int, setMessageCount, messageCount)
MCO_OBJC_SYNTHESIZE_SCALAR(uint32_t, uint32_t, setFirstUnseenUid, firstUnseenUid)
MCO_OBJC_SYNTHESIZE_SCALAR(BOOL, bool, setAllowsNewPermanentFlags, allowsNewPermanentFlags)

@end
