//
//  MCOIMAPFolder.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPFolder.h"

#import "MCOUtils.h"

#include "MCIMAP.h"

@implementation MCOIMAPFolder {
    mailcore::IMAPFolder * _nativeFolder;
}

#define nativeType mailcore::IMAPFolder

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
    mailcore::IMAPFolder * folder = (mailcore::IMAPFolder *) object;
    return [[[self alloc] initWithMCFolder:folder] autorelease];
}

- (instancetype) init
{
    mailcore::IMAPFolder * folder = new mailcore::IMAPFolder();
    self = [self initWithMCFolder:folder];
    folder->release();
    
    return self;
}

- (instancetype) initWithMCFolder:(mailcore::IMAPFolder *)folder
{
    self = [super init];
    
    _nativeFolder = folder;
    _nativeFolder->retain();
    
    return self;
}

- (void) dealloc
{
    MC_SAFE_RELEASE(_nativeFolder);
    [super dealloc];
}

- (mailcore::Object *) mco_mcObject
{
    return _nativeFolder;
}

- (NSString *) description
{
    return MCO_OBJC_BRIDGE_GET(description);
}

MCO_OBJC_SYNTHESIZE_STRING(setPath, path)
MCO_OBJC_SYNTHESIZE_SCALAR(char, char, setDelimiter, delimiter)
MCO_OBJC_SYNTHESIZE_SCALAR(MCOIMAPFolderFlag, mailcore::IMAPFolderFlag, setFlags, flags)

@end
