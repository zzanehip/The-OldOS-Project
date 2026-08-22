//
//  IMAPMultiDisconnectOperation.m
//  mailcore2
//
//  Created by Hoa V. DINH on 11/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPMultiDisconnectOperation.h"

#import "MCOOperation+Private.h"
#import "MCOUtils.h"

#include "MCIMAPMultiDisconnectOperation.h"

@implementation MCOIMAPMultiDisconnectOperation

#define nativeType mailcore::IMAPMultiDisconnectOperation

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    nativeType * op = (nativeType *) object;
    return [[[self alloc] initWithMCOperation:op] autorelease];
}

@end
