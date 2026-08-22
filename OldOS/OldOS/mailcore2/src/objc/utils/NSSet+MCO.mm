//
//  NSSet+MCO.m
//  mailcore2
//
//  Created by Hoa V. DINH on 1/29/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import "NSSet+MCO.h"

#include "MCSet.h"
#include "MCArray.h"
#import "NSObject+MCO.h"

@implementation NSSet (MCO)

+ (id) mco_objectWithMCObject:(mailcore::Object *)object
{
    return [self mco_setWithMCSet:(mailcore::Set *) object];
}

+ (NSSet *) mco_setWithMCSet:(mailcore::Set *)cppSet
{
    if (cppSet == NULL)
        return nil;
    
    NSMutableSet * result = [NSMutableSet set];
    mailcore::Array * array = cppSet->allObjects();
    for(unsigned int i = 0 ; i < array->count() ; i ++) {
        [result addObject:[NSObject mco_objectWithMCObject:array->objectAtIndex(i)]];
    }
    return result;
}

- (mailcore::Set *) mco_mcSet
{
    mailcore::Set * result = mailcore::Set::set();
    NSArray * array = [self allObjects];
    for(unsigned int i = 0 ; i < [array count] ; i ++) {
        result->addObject([[array objectAtIndex:i] mco_mcObject]);
    }
    return result;
}

@end
