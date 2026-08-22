//
//  MCORange.c
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCORange.h"

#import "MCOIndexSet.h"
#import "MCOIndexSet+Private.h"
#import "NSObject+MCO.h"
#import "NSString+MCO.h"

#include <string.h>

MCORange MCORangeEmpty = {UINT64_MAX, 0};

MCORange MCORangeMake(uint64_t location, uint64_t length)
{
    MCORange result;
    result.location = location;
    result.length = length;
    return result;
}

MCOIndexSet * MCORangeRemoveRange(MCORange range1, MCORange range2)
{
    mailcore::Range mcRange1 = MCORangeToMCRange(range1);
    mailcore::Range mcRange2 = MCORangeToMCRange(range2);
    mailcore::IndexSet * indexSet = mailcore::RangeRemoveRange(mcRange1, mcRange2);
    return [[[MCOIndexSet alloc] initWithMCIndexSet:indexSet] autorelease];
}

MCOIndexSet * MCORangeUnion(MCORange range1, MCORange range2)
{
    mailcore::Range mcRange1 = MCORangeToMCRange(range1);
    mailcore::Range mcRange2 = MCORangeToMCRange(range2);
    mailcore::IndexSet * indexSet = mailcore::RangeUnion(mcRange1, mcRange2);
    return [[[MCOIndexSet alloc] initWithMCIndexSet:indexSet] autorelease];
}

mailcore::Range MCORangeToMCRange(MCORange range)
{
    return mailcore::RangeMake(range.location, range.length);
}

MCORange MCORangeWithMCRange(mailcore::Range range)
{
    MCORange result;
    result.location = range.location;
    result.length = range.length;
    return result;
}

MCORange MCORangeIntersection(MCORange range1, MCORange range2)
{
    mailcore::Range mcRange1 = MCORangeToMCRange(range1);
    mailcore::Range mcRange2 = MCORangeToMCRange(range2);
    mailcore::Range mcResult = mailcore::RangeIntersection(mcRange1, mcRange2);
    return MCORangeWithMCRange(mcResult);
}

BOOL MCORangeHasIntersection(MCORange range1, MCORange range2)
{
    mailcore::Range mcRange1 = MCORangeToMCRange(range1);
    mailcore::Range mcRange2 = MCORangeToMCRange(range2);
    return mailcore::RangeHasIntersection(mcRange1, mcRange2);
}

uint64_t MCORangeLeftBound(MCORange range)
{
    mailcore::Range mcRange = MCORangeToMCRange(range);
    return mailcore::RangeLeftBound(mcRange);
}

uint64_t MCORangeRightBound(MCORange range)
{
    mailcore::Range mcRange = MCORangeToMCRange(range);
    return mailcore::RangeRightBound(mcRange);
}

NSString * MCORangeToString(MCORange range)
{
    return MCO_TO_OBJC(mailcore::RangeToString(MCORangeToMCRange(range)));
}

MCORange MCORangeFromString(NSString * rangeString)
{
    return MCORangeWithMCRange(mailcore::RangeFromString([rangeString mco_mcString]));
}

