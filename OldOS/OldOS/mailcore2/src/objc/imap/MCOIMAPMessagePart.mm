//
//  MCOIMAPMessagePart.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPMessagePart.h"

#include "MCIMAP.h"

#import "MCOUtils.h"

@implementation MCOIMAPMessagePart

#define nativeType mailcore::IMAPMessagePart

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::IMAPMessagePart * part = (mailcore::IMAPMessagePart *) object;
    return [[[self alloc] initWithMCPart:part] autorelease];
}

MCO_SYNTHESIZE_NSCODING

MCO_OBJC_SYNTHESIZE_STRING(setPartID, partID)

@end
