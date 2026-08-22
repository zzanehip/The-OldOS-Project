//
//  MCOObjectWrapper.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOObjectWrapper.h"

#include <typeinfo>

#include "MCUtils.h"
#include "MCBaseTypes.h"

#import "NSObject+MCO.h"

@implementation MCOObjectWrapper {
    mailcore::Object * mObject;
}

+ (void) load
{
    MCORegisterClass([NSValue class], &typeid(mailcore::Value));
    MCORegisterClass([NSData class], &typeid(mailcore::Data));
    MCORegisterClass([NSString class], &typeid(mailcore::String));
    MCORegisterClass([NSDictionary class], &typeid(mailcore::HashMap));
    MCORegisterClass([NSArray class], &typeid(mailcore::Array));
}

- (void) dealloc
{
    MC_SAFE_RELEASE(mObject);
    [super dealloc];
}

+ (MCOObjectWrapper *) objectWrapperWithObject:(mailcore::Object *)object
{
    MCOObjectWrapper * wrapper = [[MCOObjectWrapper alloc] init];
    [wrapper setObject:object];
    return [wrapper autorelease];
}

- (void) setObject:(mailcore::Object *)object
{
    MC_SAFE_RELEASE(mObject);
    mObject = object;
    MC_SAFE_RETAIN(mObject);
}

- (mailcore::Object *) object
{
    return mObject;
}

@end
