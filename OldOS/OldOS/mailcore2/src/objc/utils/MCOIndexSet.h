//
//  MCOIndexSet.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOINDEXSET_H

#define MAILCORE_MCOINDEXSET_H

#import <Foundation/Foundation.h>

#import <MailCore/MCORange.h>

/** similar to NSMutableIndexSet but supports int64_t.  MCORange has a location (uint64_t) and length (uint64_t). */

@interface MCOIndexSet : NSObject <NSCopying, NSCoding>

/** Creates an empty index set.*/
+ (MCOIndexSet *) indexSet;

/** Creates an index set that contains a range of integers.*/
+ (MCOIndexSet *) indexSetWithRange:(MCORange)range;

/** Creates an index set with a single integer.*/
+ (MCOIndexSet *) indexSetWithIndex:(uint64_t)idx;

/** Returns the number of integers in that index set.*/
- (unsigned int) count;

/** Adds an integer to the index set.*/
- (void) addIndex:(uint64_t)idx;

/** Removes an integer from the index set.*/
- (void) removeIndex:(uint64_t)idx;

/** Returns YES if the index set contains the given integer.*/
- (BOOL) containsIndex:(uint64_t)idx;

/** Adds a range of integers to the index set.*/
- (void) addRange:(MCORange)range;

/** Removes a range of integers from the index set.*/
- (void) removeRange:(MCORange)range;

/** Removes all integers that are not in the given range.*/
- (void) intersectsRange:(MCORange)range;

/** Adds all indexes from an other index set to the index set.*/
- (void) addIndexSet:(MCOIndexSet *)indexSet;

/** Remove all indexes from an other index set from the index set.*/
- (void) removeIndexSet:(MCOIndexSet *)indexSet;

/** Removes all integers that are not in the given index set.*/
- (void) intersectsIndexSet:(MCOIndexSet *)indexSet;

/** Returns all the ranges of ths index set.*/
- (MCORange *) allRanges;

/** Returns the number of ranges in this index set.*/
- (unsigned int) rangesCount;

/** Enumerates all the indexes of the index set.*/
- (void) enumerateIndexes:(void (^)(uint64_t idx))block;

/** Returns an NSIndexSet from a MCOIndexSet */
- (NSIndexSet *) nsIndexSet;

@end

#endif
