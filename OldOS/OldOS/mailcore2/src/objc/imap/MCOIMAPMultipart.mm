//
//  MCOIMAPMultipart.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPMultipart.h"

#include "MCIMAP.h"

#import "MCOUtils.h"

@implementation MCOIMAPMultipart

#define nativeType mailcore::IMAPMultipart

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::IMAPMultipart * part = (mailcore::IMAPMultipart *) object;
    return [[[self alloc] initWithMCPart:part] autorelease];
}

MCO_SYNTHESIZE_NSCODING

MCO_OBJC_SYNTHESIZE_STRING(setPartID, partID)

@end
