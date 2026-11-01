#ifndef MAILCORE_MCRANGE_H

#define MAILCORE_MCRANGE_H

#ifdef __cplusplus

#include <inttypes.h>

#include <MailCore/MCUtils.h>

#ifndef UINT64_MAX
# define UINT64_MAX 18446744073709551615ULL
#endif

namespace mailcore {
    
    class IndexSet;
    class String;
    
    // infinite length : UINT64_MAX
    // empty range : location = UINT64_MAX
    struct Range {
        uint64_t location;
        uint64_t length;
    };
    
    MAILCORE_EXPORT
    extern Range RangeEmpty;
    
    MAILCORE_EXPORT
    Range RangeMake(uint64_t location, uint64_t length);

    MAILCORE_EXPORT
    IndexSet * RangeRemoveRange(Range range1, Range range2);

    MAILCORE_EXPORT
    IndexSet * RangeUnion(Range range1, Range range2);

    MAILCORE_EXPORT
    Range RangeIntersection(Range range1, Range range2);

    MAILCORE_EXPORT
    bool RangeHasIntersection(Range range1, Range range2);

    MAILCORE_EXPORT
    uint64_t RangeLeftBound(Range range);

    MAILCORE_EXPORT
    uint64_t RangeRightBound(Range range);

    MAILCORE_EXPORT
    String * RangeToString(Range range);
    
    MAILCORE_EXPORT
    Range RangeFromString(String * rangeString);
}

#endif

#endif
