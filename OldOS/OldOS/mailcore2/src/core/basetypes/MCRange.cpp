#include "MCWin32.h" // should be included first.

#include "MCRange.h"

#include "MCIndexSet.h"
#include "MCHashMap.h"
#include "MCString.h"
#include "MCUtils.h"
#include "MCArray.h"

#ifndef _MSC_VER
#include <sys/param.h>
#endif

#if defined(ANDROID) || defined(__ANDROID__)
#include "MCAndroid.h"
#endif

using namespace mailcore;

Range mailcore::RangeEmpty = {UINT64_MAX, 0};

Range mailcore::RangeMake(uint64_t location, uint64_t length)
{
    Range range;
    range.location = location;
    range.length = length;
    return range;
}

Range mailcore::RangeIntersection(Range range1, Range range2)
{
    if (RangeRightBound(range2) < range1.location) {
        return RangeEmpty;
    }
    else if (RangeRightBound(range1) < range2.location) {
        return RangeEmpty;
    }
    else {
        uint64_t left1;
        uint64_t right1;
        uint64_t left2;
        uint64_t right2;
        uint64_t leftResult;
        uint64_t rightResult;

        left1 = range1.location;
        right1 = RangeRightBound(range1);
        left2 = range2.location;
        right2 = RangeRightBound(range2);
        
        leftResult = MAX(left1, left2);
        rightResult = MIN(right1, right2);
        if (rightResult == UINT64_MAX) {
            return RangeMake(leftResult, UINT64_MAX);
        }
        else {
            return RangeMake(leftResult, rightResult - leftResult);
        }
    }
}

bool mailcore::RangeHasIntersection(Range range1, Range range2)
{
    return RangeIntersection(range1, range2).location != UINT64_MAX;
}

IndexSet * mailcore::RangeRemoveRange(Range range1, Range range2)
{
    uint64_t left1;
    uint64_t right1;
    uint64_t left2;
    uint64_t right2;
    IndexSet * result;
    
    if (!RangeHasIntersection(range1, range2))
        return IndexSet::indexSetWithRange(range1);
    
    result = IndexSet::indexSet();
    
    range2 = RangeIntersection(range1, range2);
    
    left1 = range1.location;
    right1 = RangeRightBound(range1);
    left2 = range2.location;
    right2 = RangeRightBound(range2);
    
    if (left2 > left1) {
        result->addRange(RangeMake(left1, left2 - left1 - 1));
    }
    
    if (right2 != UINT64_MAX) {
        if (right1 == UINT64_MAX) {
            result->addRange(RangeMake(right2 + 1, UINT64_MAX));
        }
        else {
            if (right2 < right1) {
                result->addRange(RangeMake(right2 + 1, right1 - (right2 + 1)));
            }
        }
    }
    
    return result;
}

IndexSet * mailcore::RangeUnion(Range range1, Range range2)
{
    if (!RangeHasIntersection(range1, range2)) {
        IndexSet * result = IndexSet::indexSet();
        
        result->addRange(range1);
        result->addRange(range2);
        
        return result;
    }
    else {
        uint64_t left1;
        uint64_t right1;
        uint64_t left2;
        uint64_t right2;
        uint64_t resultLeft;
        uint64_t resultRight;
        
        left1 = range1.location;
        right1 = RangeRightBound(range1);
        left2 = range2.location;
        right2 = RangeRightBound(range2);
        
        resultLeft = MIN(left1, left2);
        resultRight = MAX(right1, right2);
        if (resultRight == UINT64_MAX) {
            return IndexSet::indexSetWithRange(RangeMake(resultLeft, UINT64_MAX));
        }
        else {
            return IndexSet::indexSetWithRange(RangeMake(resultLeft, resultRight - resultLeft));
        }
    }
}

uint64_t mailcore::RangeLeftBound(Range range)
{
    return range.location;
}

uint64_t mailcore::RangeRightBound(Range range)
{
    if (range.length == UINT64_MAX)
        return UINT64_MAX;
    return range.location + range.length;
}

String * mailcore::RangeToString(Range range)
{
    return String::stringWithUTF8Format("%llu-%llu", (unsigned long long) range.location,
                                        (unsigned long long) range.length);
}

Range mailcore::RangeFromString(String * rangeString)
{
    Array * components = rangeString->componentsSeparatedByString(MCSTR("-"));
    if (components->count() != 2)
        return RangeEmpty;
    String * locationString = (String *) components->objectAtIndex(0);
    String * lengthString = (String *) components->objectAtIndex(1);
    return RangeMake(locationString->unsignedLongLongValue(), lengthString->unsignedLongLongValue());
}
