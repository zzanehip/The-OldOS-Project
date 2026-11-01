//
//  MCONNTPDisconnectOperation.m
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import "MCONNTPDisconnectOperation.h"

#import "MCOOperation+Private.h"
#import "MCOUtils.h"

#include "MCNNTPDisconnectOperation.h"

@implementation MCONNTPDisconnectOperation

#define nativeType mailcore::NNTPDisconnectOperation

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
