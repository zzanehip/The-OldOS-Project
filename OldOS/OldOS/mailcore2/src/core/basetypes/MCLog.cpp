#include "MCWin32.h" // should be included first.

#include "MCDefines.h"
#include "MCLog.h"

#include <stdarg.h>
#include <string.h>
#include <stdio.h>
#ifndef _MSC_VER
#include <time.h>
#include <unistd.h>
#include <sys/time.h>
#endif
#include <pthread.h>
#if __APPLE__
#include <execinfo.h>
#endif

#if defined(ANDROID) || defined(__ANDROID__)
#include <android/log.h>
#endif

static pid_t sPid = -1;
int MCLogEnabled = 0;

INITIALIZE(Log)
{
    sPid = getpid();
}

static void logInternalv(FILE * file,
    const char * user, const char * filename, unsigned int line,
    int dumpStack, const char * format, va_list argp);

void MCLogInternal(const char * user,
    const char * filename, 
    unsigned int line, 
    int dumpStack, 
    const char * format, ...)
{
    va_list argp;
    
    va_start(argp, format);
    logInternalv(stderr, user, filename, line, dumpStack, format, argp);
    va_end(argp);
}

static void logInternalv(FILE * file,
    const char * user, const char * filename, unsigned int line,
    int dumpStack, const char * format, va_list argp)
{
    if (!MCLogEnabled)
        return;
    
    while (1) {
        const char * p = strchr(filename, '/');
        if (p == NULL) {
            break;
        }
        filename = p + 1;
    }
    
    struct timeval tv;
    struct tm tm_value;
    pthread_t thread_id = pthread_self();

#if defined(ANDROID) || defined(__ANDROID__)
    __android_log_vprint(ANDROID_LOG_INFO, filename, format, argp);
#else

    gettimeofday(&tv, NULL);
    time_t timevalue_sec = tv.tv_sec;
    localtime_r(&timevalue_sec, &tm_value);
    fprintf(file, "%04u-%02u-%02u %02u:%02u:%02u.%03u ", tm_value.tm_year + 1900, tm_value.tm_mon + 1, tm_value.tm_mday, tm_value.tm_hour, tm_value.tm_min, tm_value.tm_sec, (int) (tv.tv_usec / 1000));

#ifdef __MACH__   
    if (pthread_main_np()) {
#else
    if (0) {
#endif
        fprintf(file, "[%i:main] %s:%u: ", sPid, filename, line);
    }
    else {
        unsigned long threadValue;
#ifdef _MACH_PORT_T
        threadValue = pthread_mach_thread_np(thread_id);
#elif _MSC_VER
        threadValue = (unsigned long) thread_id.p;
#else
        threadValue = (unsigned long) thread_id;
#endif
        fprintf(file, "[%i:%lx] %s:%u: ", sPid, threadValue, filename, line);
    }
    vfprintf(file, format, argp);
    fprintf(file, "\n");
    
    if (dumpStack) {
#if __APPLE__
        void * frame[128];
        int frameCount;
        int i;
    
        fprintf(file, "    ");
        frameCount = backtrace(frame, 128);
        for(i = 0 ; i < frameCount ; i ++) {
            fprintf(file, " %p", frame[i]);
        }
        fprintf(file, "\n");
#endif
        // TODO: other platforms implemented needed.
    }
#endif
}
