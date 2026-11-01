//
//  NSDictionary+MCO.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "NSDictionary+MCO.h"

#include "MCBaseTypes.h"

#import "NSObject+MCO.h"

@implementation NSDictionary (MCO)

+ (id) mco_objectWithMCObject:(mailcore::Object *)object
{
    return [self mco_dictionaryWithMCHashMap:(mailcore::HashMap *) object];
}

+ (NSDictionary *) mco_dictionaryWithMCHashMap:(mailcore::HashMap *)hashmap
{
    NSMutableDictionary * result = [NSMutableDictionary dictionary];
    mailcore::Array * keys = hashmap->allKeys();
    for(unsigned int i = 0 ; i < keys->count() ; i ++) {
        mailcore::Object * mcKey = keys->objectAtIndex(i);
        mailcore::Object * mcValue = hashmap->objectForKey(mcKey);
        id key = [NSObject mco_objectWithMCObject:mcKey];
        id value = [NSObject mco_objectWithMCObject:mcValue];
        [result setObject:value forKey:key];
    }
    return result;
}

- (mailcore::HashMap *) mco_mcHashMap
{
    mailcore::HashMap * result = mailcore::HashMap::hashMap();
    for(NSObject * key in self) {
        NSObject * value = [self objectForKey:key];
        result->setObjectForKey([key mco_mcObject], [value mco_mcObject]);
    }
    return result;
}

@end
