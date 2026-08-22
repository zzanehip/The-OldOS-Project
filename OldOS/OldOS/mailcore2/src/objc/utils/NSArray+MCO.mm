//
//  NSArray+MCO.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "NSArray+MCO.h"

#include "MCBaseTypes.h"

#import "NSObject+MCO.h"

@implementation NSArray (MCO)

+ (id) mco_objectWithMCObject:(mailcore::Object *)object
{
    return [self mco_arrayWithMCArray:(mailcore::Array *) object];
}

+ (NSArray *) mco_arrayWithMCArray:(mailcore::Array *)array
{
    if (array == NULL) {
        return nil;
    }
    NSMutableArray * result = [NSMutableArray array];
    for(unsigned int i = 0 ; i < array->count() ; i ++) {
        [result addObject:[NSObject mco_objectWithMCObject:array->objectAtIndex(i)]];
    }
    return result;
}

- (mailcore::Array *) mco_mcArray
{
    mailcore::Array * result = mailcore::Array::array();
    for(NSObject * value in self) {
		result->addObject([value mco_mcObject]);
    }
    return result;
}

@end
