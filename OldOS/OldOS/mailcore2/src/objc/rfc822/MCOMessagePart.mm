//
//  MessagePart.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOMessagePart.h"

#include "MCRFC822.h"

#import "NSObject+MCO.h"

@implementation MCOMessagePart

#define nativeType mailcore::MessagePart

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

+ (id) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::MessagePart * part = (mailcore::MessagePart *) object;
    return [[[self alloc] initWithMCPart:part] autorelease];
}

@end
