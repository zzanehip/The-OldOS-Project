#ifndef MAILCORE_MCMAINTHREADANDROID_H

#define MAILCORE_MCMAINTHREADANDROID_H

#if defined(__ANDROID) || defined(ANDROID)

#ifdef __cplusplus

namespace mailcore {
    extern void androidSetupThread(void);
    extern void androidUnsetupThread(void);
}
#endif

#endif

#endif
