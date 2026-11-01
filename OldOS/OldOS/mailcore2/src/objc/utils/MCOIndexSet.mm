//
//  MCOIndexSet.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIndexSet.h"

#include <MailCore/MCBaseTypes.h>

#import "NSObject+MCO.h"

@implementation MCOIndexSet {
    mailcore::IndexSet * _indexSet;
}

#define nativeType mailcore::IndexSet

MCO_SYNTHESIZE_NSCODING

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

+ (id) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::IndexSet * part = (mailcore::IndexSet *) object;
    return [[[self alloc] initWithMCIndexSet:part] autorelease];
}

- (mailcore::Object *) mco_mcObject
{
    return _indexSet;
}

- (instancetype) init
{
    mailcore::IndexSet * indexSet = new mailcore::IndexSet();
    self = [self initWithMCIndexSet:indexSet];
    indexSet->release();
    return self;
}

- (instancetype) initWithMCIndexSet:(mailcore::IndexSet *)indexSet
{
    self = [super init];
    _indexSet = indexSet;
    _indexSet->retain();
    return self;
}

- (void) dealloc
{
    MC_SAFE_RELEASE(_indexSet);
    [super dealloc];
}

+ (MCOIndexSet *) indexSet
{
    return [[[MCOIndexSet alloc] init] autorelease];
}

+ (MCOIndexSet *) indexSetWithRange:(MCORange)range
{
    MCOIndexSet * indexSet;
    indexSet = [[[MCOIndexSet alloc] init] autorelease];
    [indexSet addRange:range];
    return indexSet;
}

+ (MCOIndexSet *) indexSetWithIndex:(uint64_t)idx
{
    MCOIndexSet * indexSet;
    indexSet = [[[MCOIndexSet alloc] init] autorelease];
    [indexSet addIndex:idx];
    return indexSet;
}

- (BOOL) isEqual:(id)other
{
    if (other == nil) {
        return NO;
    }
    MCOIndexSet * otherIndexSet = other;
    return _indexSet->isEqual(otherIndexSet->_indexSet);
}

- (NSString *) description
{
    return MCO_OBJC_BRIDGE_GET(description);
}

- (unsigned int) count
{
    return _indexSet->count();
}

- (void) addIndex:(uint64_t)idx
{
    _indexSet->addIndex(idx);
}

- (void) removeIndex:(uint64_t)idx
{
    _indexSet->removeIndex(idx);
}

- (BOOL) containsIndex:(uint64_t)idx
{
    return _indexSet->containsIndex(idx);
}

- (void) addRange:(MCORange)range
{
    _indexSet->addRange(MCORangeToMCRange(range));
}

- (void) removeRange:(MCORange)range
{
    _indexSet->removeRange(MCORangeToMCRange(range));
}

- (void) intersectsRange:(MCORange)range
{
    _indexSet->intersectsRange(MCORangeToMCRange(range));
}

- (void) addIndexSet:(MCOIndexSet *)indexSet
{
    _indexSet->addIndexSet(indexSet->_indexSet);
}

- (void) removeIndexSet:(MCOIndexSet *)indexSet
{
    _indexSet->removeIndexSet(indexSet->_indexSet);
}

- (void) intersectsIndexSet:(MCOIndexSet *)indexSet
{
    _indexSet->intersectsIndexSet(indexSet->_indexSet);
}

- (MCORange *) allRanges
{
    return (MCORange *) _indexSet->allRanges();
}

- (unsigned int) rangesCount
{
    return _indexSet->rangesCount();
}

- (void) enumerateIndexes:(void (^)(uint64_t idx))block
{
    MCORange * ranges = [self allRanges];
    for(unsigned int i = 0 ; i < [self rangesCount] ; i ++) {
        for(uint64_t k = 0 ; k <= ranges[i].length ; k ++) {
            block(ranges[i].location + k);
        }
    }
}

- (NSIndexSet *) nsIndexSet
{
    NSMutableIndexSet * result = [NSMutableIndexSet indexSet];
    MCORange * allRanges = [self allRanges];
    for(unsigned int i = 0 ; i < [self rangesCount] ; i ++) {
        [result addIndexesInRange:NSMakeRange((NSUInteger) allRanges[i].location, (NSUInteger) allRanges[i].length + 1)];
    }
    return result;
}

@end
