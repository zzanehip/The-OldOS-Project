#ifndef FREEBSD_QSORT_R_H

#define FREEBSD_QSORT_R_H

#if defined(ANDROID) || defined(__ANDROID__)

#ifdef __cplusplus

#include <stdint.h>

#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

namespace mailcore {
    extern void
        android_qsort_r(void *a, size_t n, size_t es, void *thunk, int (* cmp)(void *, const void *, const void *));
}

#endif

#endif

#endif

