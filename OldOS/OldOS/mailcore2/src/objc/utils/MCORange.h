//
//  MCORange.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCORANGE_H

#define MAILCORE_MCORANGE_H

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#include <MailCore/MCBaseTypes.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

@class MCOIndexSet;

typedef struct {
    /** first integer of the range.*/
    uint64_t location;
    
    /** length of the range.*/
    uint64_t length;
} MCORange;

/** Constants for an emtpy range.*/
extern MCORange MCORangeEmpty;

/** Returns a new range given a location and length.*/
MCORange MCORangeMake(uint64_t location, uint64_t length);

/** Returns an index set that is the result of sustracting a range from a range.*/
MCOIndexSet * MCORangeRemoveRange(MCORange range1, MCORange range2);

/** Returns an index set that is the result of the union a range from a range.*/
MCOIndexSet * MCORangeUnion(MCORange range1, MCORange range2);

#ifdef __cplusplus

/** Returns a C++ range from an Objective-C range.*/
mailcore::Range MCORangeToMCRange(MCORange range);

/** Returns an Objective-C range from a C++ range.*/
MCORange MCORangeWithMCRange(mailcore::Range range);

#endif

/** Returns the intersection of two ranges.*/
MCORange MCORangeIntersection(MCORange range1, MCORange range2);

/** Returns YES if two given ranges have an intersection.*/
BOOL MCORangeHasIntersection(MCORange range1, MCORange range2);

/** Returns left bound of a range.*/
uint64_t MCORangeLeftBound(MCORange range);

/** Returns right bound of a range.*/
uint64_t MCORangeRightBound(MCORange range);

/** Returns a serializable form (NSString) of a range */
NSString * MCORangeToString(MCORange range);

/** Create a range from a serializable form (NSString). */
MCORange MCORangeFromString(NSString * rangeString);

#ifdef __cplusplus
}
#endif

#endif
