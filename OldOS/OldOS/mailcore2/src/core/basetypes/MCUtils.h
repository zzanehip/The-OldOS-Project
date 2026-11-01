#ifndef MAILCORE_MCUTILS_H

#define MAILCORE_MCUTILS_H

#ifdef __cplusplus

#define MC_SAFE_RETAIN(o) ((o) != NULL ? (o)->retain() : NULL)
#define MC_SAFE_COPY(o) ((o) != NULL ? (o)->copy() : NULL)

#define MC_SAFE_RELEASE(o) \
    do { \
        if ((o) != NULL) { \
            (o)->release(); \
            (o) = NULL; \
        } \
    } while (0)

#define MC_SAFE_REPLACE_RETAIN(type, mField, value) \
    do { \
        MC_SAFE_RELEASE(mField); \
        mField = (type *) MC_SAFE_RETAIN(value); \
    } while (0)

#define MC_SAFE_REPLACE_COPY(type, mField, value) \
    do { \
        MC_SAFE_RELEASE(mField); \
        mField = (type *) MC_SAFE_COPY(value); \
    } while (0)

#define MCSTR(str) mailcore::String::uniquedStringWithUTF8Characters("" str "")

#define MCUTF8(str) MCUTF8DESC(str)
#define MCUTF8DESC(obj) ((obj) != NULL ? (obj)->description()->UTF8Characters() : NULL )

#define MCLOCALIZEDSTRING(key) key

#define MCISKINDOFCLASS(instance, class) (dynamic_cast<class *>(instance) != NULL)

#endif

#ifdef _MSC_VER
#	ifdef MAILCORE_DLL
#		define MAILCORE_EXPORT __declspec(dllexport)
#	else
#		define MAILCORE_EXPORT __declspec(dllimport)
#   endif
#else
#	define MAILCORE_EXPORT
#endif

#ifdef __ANDROID_API__
#if __ANDROID_API__ < 21
#include <wchar.h>
extern int               iswblank(wint_t);
extern int vfwscanf(FILE*, const wchar_t*, va_list);
extern int vswscanf(const wchar_t*, const wchar_t*, va_list);
extern int vwscanf(const wchar_t*, va_list);
extern float wcstof(const wchar_t*, wchar_t**);
extern long double wcstold(const wchar_t*, wchar_t**);
extern long long wcstoll(const wchar_t*, wchar_t**, int);
extern unsigned long long wcstoull(const wchar_t*, wchar_t**, int);
#endif
#endif

#ifdef __clang__

#if __has_feature(attribute_analyzer_noreturn)
#define CLANG_ANALYZER_NORETURN __attribute__((analyzer_noreturn))
#else
#define CLANG_ANALYZER_NORETURN
#endif

#define ATTRIBUTE_RETURNS_NONNULL __attribute__((returns_nonnull))

#else

#define CLANG_ANALYZER_NORETURN
#define ATTRIBUTE_RETURNS_NONNULL

#endif

#ifndef DEPRECATED_ATTRIBUTE
#define DEPRECATED_ATTRIBUTE        __attribute__((deprecated))
#endif

#endif
