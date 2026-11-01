#ifndef MAILCORE_MCLOG_H

#define MAILCORE_MCLOG_H

#include <stdio.h>
#include <MailCore/MCUtils.h>

#define MCLog(...) MCLogInternal(NULL, __FILE__, __LINE__, 0, __VA_ARGS__)
#define MCLogStack(...) MCLogInternal(NULL, __FILE__, __LINE__, 1, __VA_ARGS__)

MAILCORE_EXPORT
extern int MCLogEnabled;
    
#ifndef __printflike
#define __printflike(a,b)
#endif

#ifdef __cplusplus
extern "C" {
#endif
    MAILCORE_EXPORT
    void MCLogInternal(const char * user,
                       const char * filename,
                       unsigned int line,
                       int dumpStack,
                       const char * format, ...) __printflike(5, 6);
#ifdef __cplusplus
}
#endif

#endif
