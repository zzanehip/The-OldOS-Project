#ifndef MAILCORE_MCWIN32_H

#define MAILCORE_MCWIN32_H

// It must be included at the beginning of the file.

#ifdef _MSC_VER

#define _CRT_RAND_S
#include <stdlib.h>

#ifdef __cplusplus
#include <algorithm>
#endif

#include <stdio.h>
#include <Winsock2.h>
#include <windows.h>
#include <rpc.h>
#include <time.h>
#include <sys/stat.h>
#include <errno.h>
#include <direct.h>

#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))
#define strcasecmp _stricmp
#define strncasecmp _strnicmp
#define strcasestr mailcore::win32_strcasestr
#define strdup _strdup
#define fileno _fileno
#define unlink _unlink
#define mkdir _mkdir
#define fopen mailcore::win32_fopen
#define gmtime_r mailcore::win32_gmtime_r
#define localtime_r mailcore::win32_localtime_r
#define gettimeofday mailcore::win32_gettimeofday
#define getpid mailcore::win32_getpid
#define snprintf mailcore::win32_snprintf
#define vasprintf mailcore::win32_vasprintf
#define timegm mailcore::win32_timegm
#define random mailcore::win32_random
#define getpid mailcore::win32_getpid
#define mkdtemp mailcore::win32_mkdtemp

#define S_ISDIR(m) ((m & _S_IFDIR) != 0)

#ifndef pid_t
typedef int pid_t;
#endif

#ifdef __cplusplus
namespace mailcore {

    struct tm * win32_gmtime_r(const time_t *clock, struct tm *result);
    struct tm * win32_localtime_r(const time_t *clock, struct tm *result);
    time_t win32_timegm(struct tm *timeptr);
    int win32_gettimeofday(struct timeval * tp, struct timezone * tzp);
    
    FILE * win32_fopen(const char * filename, const char * mode);
    int win32_vasprintf(char **strp, const char *fmt, va_list ap);
    int win32_snprintf(char * str, size_t size, const char * format, ...);

    char * win32_strcasestr(const char * s, const char * find);
    
    long win32_random(void);
    pid_t win32_getpid(void);
    
    char * win32_mkdtemp(char *name_template);
}
#endif

#endif

#endif
