//
//  MCOIMAPFolderStatus.m
//  mailcore2
//
//  Created by Sebastian on 6/5/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPFolderStatus.h"
#import "NSObject+MCO.h"

#include "MCIMAPFolderStatus.h"

#define nativeType mailcore::IMAPFolderStatus

@implementation MCOIMAPFolderStatus {
    mailcore::IMAPFolderStatus * _nativeStatus;
}

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

- (instancetype) initWithMCFolderStatus:(mailcore::IMAPFolderStatus *)status
{
    self = [super init];
    
    status->retain();
    _nativeStatus = status;
    
    return self;
}

- (void) dealloc
{
    MC_SAFE_RELEASE(_nativeStatus);
    [super dealloc];
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::IMAPFolderStatus * status = (mailcore::IMAPFolderStatus *) object;
    return [[[self alloc] initWithMCFolderStatus:status] autorelease];
}

- (instancetype) init
{
    mailcore::IMAPFolderStatus * folderStatus = new mailcore::IMAPFolderStatus();
    self = [self initWithMCFolderStatus:folderStatus];
    folderStatus->release();

    return self;
}

- (mailcore::Object *) mco_mcObject
{
    return _nativeStatus;
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

MCO_OBJC_SYNTHESIZE_SCALAR(uint32_t, uint32_t, setUnseenCount, unseenCount)
MCO_OBJC_SYNTHESIZE_SCALAR(uint32_t, uint32_t, setMessageCount, messageCount)
MCO_OBJC_SYNTHESIZE_SCALAR(uint32_t, uint32_t, setRecentCount, recentCount)
MCO_OBJC_SYNTHESIZE_SCALAR(uint32_t, uint32_t, setUidNext, uidNext)
MCO_OBJC_SYNTHESIZE_SCALAR(uint32_t, uint32_t, setUidValidity, uidValidity)
MCO_OBJC_SYNTHESIZE_SCALAR(uint64_t, uint64_t, setHighestModSeqValue, highestModSeqValue)

@end
