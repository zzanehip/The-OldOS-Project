#include "MCWin32.h" // should be included first.

#include "MCString.h"

#if __APPLE__
#define DISABLE_ICU 1
#endif

#include <string.h>
#include <stdlib.h>
#if DISABLE_ICU
#include <unicode/ustring.h>
#else
#include <unicode/ustring.h>
#include <unicode/ucnv.h>
#include <unicode/utypes.h>
#endif
#if !defined(_MSC_VER) && !defined(ANDROID) && !defined(__ANDROID__)
#include <uuid/uuid.h>
#endif
#include <pthread.h>
#include <libetpan/libetpan.h>
#include <libxml/xmlmemory.h>
#include <libxml/HTMLparser.h>
#if __APPLE__
#include <CoreFoundation/CoreFoundation.h>
#endif

#include "MCDefines.h"
#include "MCData.h"
#include "MCHash.h"
#include "MCLog.h"
#include "MCUtils.h"
#include "MCRange.h"
#include "MCArray.h"
#include "MCSet.h"
#include "MCHashMap.h"
#include "MCAutoreleasePool.h"
#include "MCValue.h"
#include "MCHTMLCleaner.h"
#include "MCBase64.h"
#include "MCIterator.h"
#include "ConvertUTF.h"
#include "MCLock.h"

#if defined(_MSC_VER)
#define PATH_SEPARATOR_CHAR '\\'
#define PATH_SEPARATOR_STRING "\\"
#else
#define PATH_SEPARATOR_CHAR '/'
#define PATH_SEPARATOR_STRING "/"
#endif

using namespace mailcore;

static String * s_unicode160 = NULL;
static String * s_unicode133 = NULL;
static String * s_unicode2028 = NULL;

#if DISABLE_ICU && 0
static int32_t u_strlen(const UChar *s) {
    if (s == NULL) {
        return 0;
    }
    const UChar * p = s;
    while (* p != 0) {
        p ++;
    }
    return (int32_t) (p - s);
}

static UChar * u_memcpy(UChar * dest, const UChar * src, int32_t count) {
    memcpy(dest, src, count * sizeof(* src));
    return dest;
}

static UChar * u_strstr(const UChar * s, const UChar * substring)
{
    if (s == NULL) {
        return NULL;
    }
    CFStringRef cfS = CFStringCreateWithCharactersNoCopy(NULL, (const UniChar *) s, u_strlen(s), kCFAllocatorNull);
    CFStringRef cfSubstring = CFStringCreateWithCharactersNoCopy(NULL, (const UniChar *) substring, u_strlen(substring), kCFAllocatorNull);
    
    CFRange range = CFStringFind(cfS, cfSubstring, 0);
    CFRelease(cfSubstring);
    CFRelease(cfS);
    if (range.length == 0) {
        return NULL;
    }
    return (UChar *) (s + range.location);
}

static UChar * u_strrstr(const UChar * s, const UChar * substring)
{
    if (s == NULL) {
        return NULL;
    }
    CFStringRef cfS = CFStringCreateWithCharactersNoCopy(NULL, (const UniChar *) s, u_strlen(s), kCFAllocatorNull);
    CFStringRef cfSubstring = CFStringCreateWithCharactersNoCopy(NULL, (const UniChar *) substring, u_strlen(substring), kCFAllocatorNull);
    
    CFRange range = CFStringFind(cfS, cfSubstring, kCFCompareBackwards);
    CFRelease(cfSubstring);
    CFRelease(cfS);
    if (range.length == 0) {
        return NULL;
    }
    return (UChar *) (s + range.location);
}

static int32_t u_memcmp(const UChar * buf1, const UChar * buf2, int32_t count)
{
    return memcmp(buf1, buf2, count * sizeof(* buf1));
}

static UChar * u_strchr(const UChar *s, UChar c)
{
    if (s == NULL) {
        return NULL;
    }
    const UChar * p = s;
    while (* p != 0) {
        if (* p == c) {
            return (UChar *) p;
        }
        p ++;
    }
    return NULL;
}

static UChar * u_strrchr(const UChar *s, UChar c)
{
    if (s == NULL) {
        return NULL;
    }
    const UChar * lastOccurrence = NULL;
    const UChar * p = s;
    while (* p != 0) {
        if (* p == c) {
            lastOccurrence = p;
        }
        p ++;
    }
    return (UChar *) lastOccurrence;
}
#endif

void mailcore::setICUDataDirectory(String * directory)
{
#if !DISABLE_ICU
    u_setDataDirectory(directory->fileSystemRepresentation());
#endif
}

#pragma mark quote headers string

static inline int to_be_quoted(const char * word, size_t size, int subject)
{
    int do_quote;
    const char * cur;
    size_t i;
    
    do_quote = 0;
    cur = word;
    for(i = 0 ; i < size ; i ++) {
        if (* cur == '=')
            do_quote = 1;
        
        if (!subject) {
            switch (* cur) {
                case ',':
                case ':':
                case '!':
                case '"':
                case '#':
                case '$':
                case '@':
                case '[':
                case '\\':
                case ']':
                case '^':
                case '`':
                case '{':
                case '|':
                case '}':
                case '~':
                case '=':
                case '?':
                case '_':
                    do_quote = 1;
                    break;
            }
        }
        if (((unsigned char) * cur) >= 128)
            do_quote = 1;
        
        cur ++;
    }
    
    return do_quote;
}

#define MAX_IMF_LINE 72

static inline void quote_word(const char * display_charset,
    MMAPString * mmapstr, const char * word, size_t size)
{
    const char * cur;
    size_t i;
    char hex[4];
    int col;
    
    mmap_string_append(mmapstr, "=?");
    mmap_string_append(mmapstr, display_charset);
    mmap_string_append(mmapstr, "?Q?");
    
    col = (int) mmapstr->len;
    
    cur = word;
    for(i = 0 ; i < size ; i ++) {
        int do_quote_char;
        
        do_quote_char = 0;
        switch (* cur) {
            case ',':
            case ':':
            case '!':
            case '"':
            case '#':
            case '$':
            case '@':
            case '[':
            case '\\':
            case ']':
            case '^':
            case '`':
            case '{':
            case '|':
            case '}':
            case '~':
            case '=':
            case '?':
            case '_':
                do_quote_char = 1;
                break;
                
            default:
                if (((unsigned char) * cur) >= 128)
                    do_quote_char = 1;
                break;
        }
        
        if (do_quote_char) {
            snprintf(hex, 4, "=%2.2X", (unsigned char) * cur);
            mmap_string_append(mmapstr, hex);
            col += 3;
        }
        else {
            if (* cur == ' ') {
                mmap_string_append_c(mmapstr, '_');
            }
            else {
                mmap_string_append_c(mmapstr, * cur);
            }
            col += 3;
        }
        cur ++;
    }
    
    mmap_string_append(mmapstr, "?=");
}

static inline void get_word(const char * begin, const char ** pend, int subject, int * pto_be_quoted)
{
    const char * cur;
    
    cur = begin;
    
    while ((* cur != ' ') && (* cur != '\t') && (* cur != '\0')) {
        cur ++;
    }
    while (((* cur == ' ') || (* cur == '\t')) && (* cur != '\0')) {
        cur ++;
    }
    
    if (cur - begin +
        1  /* minimum column of string in a
            folded header */ > MAX_IMF_LINE)
        * pto_be_quoted = 1;
    else
        * pto_be_quoted = to_be_quoted(begin, cur - begin, subject);
    
    * pend = cur;
}

static char * etpan_make_full_quoted_printable(const char * display_charset,
    const char * phrase)
{
    int needs_quote;
    char * str;
    
    needs_quote = to_be_quoted(phrase, strlen(phrase), 0);
    if (needs_quote) {
        MMAPString * mmapstr;
        
        mmapstr = mmap_string_new("");
        quote_word(display_charset, mmapstr, phrase, strlen(phrase));
        str = strdup(mmapstr->str);
        mmap_string_free(mmapstr);
    }
    else {
        str = strdup(phrase);
    }
    
    return str;
}

static char * etpan_make_quoted_printable(const char * display_charset,
    const char * phrase, int subject)
{
    char * str;
    const char * cur;
    MMAPString * mmapstr;
    
    mmapstr = mmap_string_new("");
    
    cur = phrase;
    while (* cur != '\0') {
        const char * begin;
        const char * end;
        int do_quote;
        int quote_words;
        
        begin = cur;
        end = begin;
        quote_words = 0;
        do_quote = 1;
        
        while (* cur != '\0') {
            get_word(cur, &cur, subject, &do_quote);
            if (do_quote) {
                quote_words = 1;
                end = cur;
            }
            else
                break;
            if (* cur != '\0')
                cur ++;
        }
        
        if (quote_words) {
            quote_word(display_charset, mmapstr, begin, end - begin);
            
            if ((* end == ' ') || (* end == '\t')) {
                mmap_string_append_c(mmapstr, * end);
                end ++;
            }
            
            if (* end != '\0') {
                mmap_string_append_len(mmapstr, end, cur - end);
            }
        }
        else {
            mmap_string_append_len(mmapstr, begin, cur - begin);
        }
        
        if ((* cur == ' ') || (* cur == '\t')) {
            mmap_string_append_c(mmapstr, * cur);
            cur ++;
        }
    }
    
    str = strdup(mmapstr->str);
    mmap_string_free(mmapstr);
    
    return str;
}

#pragma mark extract subject

static inline int skip_subj_blob(char * subj, size_t * begin,
                                 size_t length, int keep_bracket)
{
    if (keep_bracket)
        return 0;
    
    /* subj-blob       = "[" *BLOBCHAR "]" *WSP */
    size_t cur_token;
    
    cur_token = * begin;
    
    if (subj[cur_token] != '[')
        return 0;
    
    cur_token ++;
    
    while (1) {
        if (cur_token >= length)
            return 0;
        
        if (subj[cur_token] == '[')
            return 0;
        
        if (subj[cur_token] == ']')
            break;
        
        cur_token ++;
    }
    
    cur_token ++;
    
    while (1) {
        if (cur_token >= length)
            break;
        
        if (subj[cur_token] != ' ')
            break;
        
        cur_token ++;
    }
    
    * begin = cur_token;
    
    return 1;
}

static inline int skip_subj_refwd(char * subj, size_t * begin,
                                  size_t length, int keep_bracket)
{
    /* subj-refwd      = ("re" / ("fw" ["d"])) *WSP [subj-blob] ":" */
    size_t cur_token;
    int prefix;
    int has_suffix;
    
    cur_token = * begin;
    prefix = 0;
    if (!prefix) {
        if (length - cur_token >= 18) {
            if (strncasecmp(subj + cur_token, "Переслать", 18) == 0) {
                cur_token += 18;
                prefix = 1;
            }
        }
    }
    if (!prefix) {
        if (length - cur_token >= 10) {
            if (strncasecmp(subj + cur_token, "Ответ", 10) == 0) {
                cur_token += 10;
                prefix = 1;
            }
        }
    }
    if (!prefix) {
        if (length - cur_token >= 7) {
            if (strncasecmp(subj + cur_token, "Antwort", 7) == 0) {
                cur_token += 7;
                prefix = 1;
            }
        }
    }
    if (!prefix) {
        if (length - cur_token >= 6) {
            if (strncasecmp(subj + cur_token, "回复", 6) == 0) {
                cur_token += 6;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "转发", 6) == 0) {
                cur_token += 6;
                prefix = 1;
            }
        }
    }
    if (!prefix) {
        if (length - cur_token >= 5) {
            // é is 2 chars in utf-8
            if (strncasecmp(subj + cur_token, "réf.", 5) == 0) {
                cur_token += 5;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "rép.", 5) == 0) {
                cur_token += 5;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "trans", 5) == 0) {
                cur_token += 5;
                prefix = 1;
            }
        }
    }
    if (!prefix) {
        if (length - cur_token >= 4) {
            if (strncasecmp(subj + cur_token, "antw", 4) == 0) {
                cur_token += 4;
                prefix = 1;
            }
        }
    }
    if (!prefix) {
        if (length - cur_token >= 3) {
            if (strncasecmp(subj + cur_token, "fwd", 3) == 0) {
                cur_token += 3;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "ogg", 3) == 0) {
                cur_token += 3;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "odp", 3) == 0) {
                cur_token += 3;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "res", 3) == 0) {
                cur_token += 3;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "end", 3) == 0) {
                cur_token += 3;
                prefix = 1;
            }
        }
    }
    if (!prefix) {
        if (length - cur_token >= 2) {
            if (strncasecmp(subj + cur_token, "fw", 2) == 0) {
                cur_token += 2;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "re", 2) == 0) {
                cur_token += 2;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "tr", 2) == 0) {
                cur_token += 2;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "aw", 2) == 0) {
                cur_token += 2;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "sv", 2) == 0) {
                cur_token += 2;
                prefix = 1;
            }
            else if (strncasecmp(subj + cur_token, "rv", 2) == 0) {
                cur_token += 2;
                prefix = 1;
            }
        }
    }
    if (!prefix) {
        if (length - cur_token >= 1) {
            if (strncasecmp(subj + cur_token, "r", 1) == 0) {
                cur_token += 1;
                prefix = 1;
            }
        }
    }
    
    if (!prefix)
        return 0;
    
    while (1) {
        if (cur_token >= length)
            break;
        
        if (subj[cur_token] != ' ')
            break;
        
        cur_token ++;
    }
    
    skip_subj_blob(subj, &cur_token, length, keep_bracket);
    
    has_suffix = 0;
    
    if (!has_suffix) {
        if (length - cur_token >= 3) {
            if (strncasecmp(subj + cur_token, "：", 3) == 0) {
                cur_token += 3;
                has_suffix = 1;
            }
        }
    }
    
    if (!has_suffix) {
        if (cur_token < length) {
            if (subj[cur_token] == ':') {
                cur_token ++;
                has_suffix = 1;
            }
        }
    }
    
    if (!has_suffix) {
        return 0;
    }
    
    * begin = cur_token;
    
    return 1;
}

static inline int skip_subj_leader(char * subj, size_t * begin,
                                   size_t length, int keep_bracket)
{
    size_t cur_token;
    
    cur_token = * begin;
    
    /* subj-leader     = (*subj-blob subj-refwd) / WSP */
    
    if (subj[cur_token] == ' ') {
        cur_token ++;
    }
    else {
        while (cur_token < length) {
            if (!skip_subj_blob(subj, &cur_token, length, keep_bracket))
                break;
        }
        if (!skip_subj_refwd(subj, &cur_token, length, keep_bracket))
            return 0;
    }
    
    * begin = cur_token;
    
    return 1;
}

static char * extract_subject(char * str, int keep_bracket)
{
    char * subj;
    char * cur;
    char * write_pos;
    size_t len;
    size_t begin;
    int do_repeat_5;
    int do_repeat_6;
    
    /*
     (1) Convert any RFC 2047 encoded-words in the subject to
     UTF-8.
     We work on UTF-8 string -- DVH
     */
    
    subj = strdup(str);
    if (subj == NULL)
        return NULL;
    
    len = strlen(subj);
    
    /*
     Convert all tabs and continuations to space.
     Convert all multiple spaces to a single space.
     */
    
    cur = subj;
    write_pos = subj;
    while (* cur != '\0') {
        int cont;
        
        switch (* cur) {
            case '\t':
            case '\r':
            case '\n':
                cont = 1;
                
                cur ++;
                while (* cur && cont) {
                    switch (* cur) {
                        case '\t':
                        case '\r':
                        case '\n':
                            cont = 1;
                            break;
                        default:
                            cont = 0;
                            break;
                    }
                    cur ++;
                }
                
                * write_pos = ' ';
                write_pos ++;
                
                break;
                
            default:
                * write_pos = * cur;
                write_pos ++;
                
                cur ++;
                
                break;
        }
    }
    * write_pos = '\0';
    
    begin = 0;
    
    do {
        do_repeat_6 = 0;
        
        /*
         (2) Remove all trailing text of the subject that matches
         the subj-trailer ABNF, repeat until no more matches are
         possible.
         */
        
        while (len > 0) {
            /* subj-trailer    = "(fwd)" / WSP */
            if (subj[len - 1] == ' ') {
                subj[len - 1] = '\0';
                len --;
            }
            else {
                if (len < 5)
                    break;
                
                if (strncasecmp(subj + len - 5, "(fwd)", 5) != 0)
                    break;
                
                subj[len - 5] = '\0';
                len -= 5;
            }
        }
        
        do {
            size_t saved_begin;
            
            do_repeat_5 = 0;
            
            /*
             (3) Remove all prefix text of the subject that matches the
             subj-leader ABNF.
             */
            
            if (skip_subj_leader(subj, &begin, len, keep_bracket))
                do_repeat_5 = 1;
            
            /*
             (4) If there is prefix text of the subject that matches the
             subj-blob ABNF, and removing that prefix leaves a non-empty
             subj-base, then remove the prefix text.
             */
            
            saved_begin = begin;
            if (skip_subj_blob(subj, &begin, len, keep_bracket)) {
                if (begin == len) {
                    /* this will leave a empty subject base */
                    begin = saved_begin;
                }
                else
                    do_repeat_5 = 1;
            }
            
            /*
             (5) Repeat (3) and (4) until no matches remain.
             Note: it is possible to defer step (2) until step (6),
             but this requires checking for subj-trailer in step (4).
             */
            
        }
        while (do_repeat_5);
        
        /*
         (6) If the resulting text begins with the subj-fwd-hdr ABNF
         and ends with the subj-fwd-trl ABNF, remove the
         subj-fwd-hdr and subj-fwd-trl and repeat from step (2).
         */
        
        if (len >= 5) {
            if (strncasecmp(subj + begin, "[fwd:", 5) == 0) {
                begin += 5;
                
                if (subj[len - 1] == ']') {
                    subj[len - 1] = '\0';
                    len --;
                    do_repeat_6 = 1;
                }
            }
        }
        
    }
    while (do_repeat_6);
    
    /*
     (7) The resulting text is the "base subject" used in
     threading.
     */
    
    /* convert to upper case */
    
    cur = subj + begin;
    write_pos = subj;
    
    while (* cur != '\0') {
        * write_pos = * cur;
        cur ++;
        write_pos ++;
    }
    * write_pos = '\0';
    
    return subj;
}

String::String(const UChar * unicodeChars)
{
    mUnicodeChars = NULL;
    reset();
    if (unicodeChars != NULL) {
        allocate(u_strlen(unicodeChars), true);
    }
    appendCharacters(unicodeChars);
}

String::String(const UChar * unicodeChars, unsigned int length)
{
    mUnicodeChars = NULL;
    reset();
    allocate(length, true);
    appendCharactersLength(unicodeChars, length);
}

String::String(const char * UTF8Characters)
{
    mUnicodeChars = NULL;
    reset();
    if (UTF8Characters != NULL) {
        allocate((unsigned int) strlen(UTF8Characters), true);
    }
    appendUTF8Characters(UTF8Characters);
}

String::String(String * otherString)
{
    mUnicodeChars = NULL;
    reset();
    appendString(otherString);
}

String::String(Data * data, const char * charset)
{
    mUnicodeChars = NULL;
    reset();
    appendBytes(data->bytes(), data->length(), charset);
}

String::String(const char * bytes, unsigned int length, const char * charset)
{
    mUnicodeChars = NULL;
    reset();
    allocate(length, true);
    if (charset == NULL) {
        appendUTF8CharactersLength(bytes, length);
    }
    else {
        appendBytes(bytes, length, charset);
    }
}

String::~String()
{
    reset();
}

static int isPowerOfTwo (unsigned int x)
{
    return ((x != 0) && !(x & (x - 1)));
}

void String::allocate(unsigned int length, bool force)
{
    length ++;
    if (length <= mAllocated)
        return;

    if (force) {
        mAllocated = length;
    }
    else {
        if (!isPowerOfTwo(mAllocated)) {
            mAllocated = 0;
        }
        if (mAllocated == 0) {
            mAllocated = 4;
        }
        while (length > mAllocated) {
            mAllocated *= 2;
        }
    }
    
    mUnicodeChars = (UChar *) realloc(mUnicodeChars, mAllocated * sizeof(* mUnicodeChars));
}

String * String::string()
{
    return stringWithCharacters(NULL, 0);
}

String * String::stringWithData(Data * data, const char * charset)
{
    if (data == NULL) {
        return String::string();
    }
    String * result = NULL;
    result = new String(data->bytes(), data->length(), charset);
    result->autorelease();
    return result;
}

String * String::stringWithUTF8Format(const char * format, ...)
{
    va_list argp;
    
    va_start(argp, format);
    String * result = stringWithVUTF8Format(format, argp);
    va_end(argp);
    
    return result;
}

String * String::stringWithVUTF8Format(const char * format, va_list ap)
{
    char * result;
    vasprintf(&result, format, ap);
    String * str = stringWithUTF8Characters(result);
    free(result);
    return str;
}

String * String::stringWithUTF8Characters(const char * UTF8Characters)
{
    if (UTF8Characters == NULL) {
        return NULL;
    }
    String * result = new String(UTF8Characters);
    return (String *) result->autorelease();
}

String * String::stringWithCharacters(const UChar * characters)
{
    if (characters == NULL) {
        return NULL;
    }
    String * result = new String(characters);
    return (String *) result->autorelease();
}

String * String::stringWithCharacters(const UChar * characters, unsigned int length)
{
    String * result = new String(characters, length);
    return (String *) result->autorelease();
}

void String::appendCharactersLength(const UChar * unicodeCharacters, unsigned int length)
{
    if (unicodeCharacters == NULL) {
        return;
    }
    allocate(mLength + length);
    MCAssert(mUnicodeChars != NULL);
    memcpy(&mUnicodeChars[mLength], unicodeCharacters, length * sizeof(* mUnicodeChars));
    mLength += length;
    mUnicodeChars[mLength] = 0;
}

void String::appendString(String * otherString)
{
    if (otherString == NULL) {
        return;
    }
    appendCharactersLength(otherString->unicodeCharacters(), otherString->length());
}

void String::appendUTF8Format(const char * format, ...)
{
    va_list argp;
    
    va_start(argp, format);
    String * otherString = stringWithVUTF8Format(format, argp);
    va_end(argp);
    
    this->appendString(otherString);
}

void String::appendUTF8CharactersLength(const char * UTF8Characters, unsigned int length)
{
    if (UTF8Characters == NULL) {
        return;
    }

    const UTF8 * source = (const UTF8 *) UTF8Characters;
    UTF16 * target = (UTF16 *) malloc(length * sizeof(* target));
    UTF16 * targetStart = target;
    ConvertUTF8toUTF16(&source, source + length,
                       &targetStart, targetStart + length, lenientConversion);
    appendCharactersLength((UChar *) target, (unsigned int ) (targetStart - target));
    free(target);
}

void String::appendUTF8Characters(const char * UTF8Characters)
{
    if (UTF8Characters != NULL) {
        appendUTF8CharactersLength(UTF8Characters, (unsigned int) strlen(UTF8Characters));
    }
}

void String::appendCharacters(const UChar * unicodeCharacters)
{
    if (unicodeCharacters == NULL)
        return;
    
    appendCharactersLength(unicodeCharacters, u_strlen(unicodeCharacters));
}

const UChar * String::unicodeCharacters()
{
    return mUnicodeChars;
}

const char * String::UTF8Characters()
{
    const UTF16 * source = (const UTF16 *) mUnicodeChars;
    UTF8 * target = (UTF8 *) malloc(mLength * 6 + 1);
    UTF8 * targetStart = target;
    ConvertUTF16toUTF8(&source, source + mLength,
                       &targetStart, targetStart + mLength * 6 + 1, lenientConversion);
    unsigned int utf8length = (unsigned int) (targetStart - target);
    target[utf8length] = 0;
    Data * data = Data::dataWithBytes((const char *) target, utf8length + 1);
    free(target);
    
    return data->bytes();
}

unsigned int String::length()
{
    return mLength;
}

String * String::stringByAppendingString(String * otherString)
{
    String * result = new String(this);
    result->appendString(otherString);
    return (String *) result->autorelease();
}

String * String::stringByAppendingUTF8Format(const char * format, ...)
{
    va_list argp;
    
    va_start(argp, format);
    String * otherString = stringWithVUTF8Format(format, argp);
    va_end(argp);
    
    return this->stringByAppendingString(otherString);
}

String * String::stringByAppendingUTF8Characters(const char * UTF8Characters)
{
    String * otherString = stringWithUTF8Characters(UTF8Characters);
    return this->stringByAppendingString(otherString);
}

String * String::stringByAppendingCharacters(const UChar * unicodeCharacters)
{
    String * otherString = stringWithCharacters(unicodeCharacters);
    return this->stringByAppendingString(otherString);
}

void String::reset()
{
    free(mUnicodeChars);
    mUnicodeChars = NULL;
    mLength = 0;
    mAllocated = 0;
}

void String::setString(String * otherString)
{
    reset();
    appendString(otherString);
}

void String::setUTF8Characters(const char * UTF8Characters)
{
    reset();
    appendUTF8Characters(UTF8Characters);
}

void String::setCharacters(const UChar * unicodeCharacters)
{
    reset();
    appendCharacters(unicodeCharacters);
}

String * String::description()
{
    return this;
}

Object * String::copy()
{
    return new String(this);
}

bool String::isEqual(Object * otherObject)
{
    if (otherObject == NULL)
        return false;
    
    String * otherString = (String *) otherObject;
    if (length() != otherString->length())
        return false;
    return compare(otherString) == 0;
}

unsigned int String::hash()
{
    return hashCompute((const char *) mUnicodeChars, mLength * sizeof(* mUnicodeChars));
}

#define DEFAULT_INCOMING_CHARSET "iso-8859-1"
#define DEFAULT_DISPLAY_CHARSET "utf-8"

String * String::stringByDecodingMIMEHeaderValue(const char * phrase)
{
    size_t cur_token;
    char * decoded;
    String * result;
    bool hasEncoding;
    
    if (phrase == NULL)
        return string();

    if (* phrase == '\0') {
        return string();
    }

    hasEncoding = false;
    if (strstr(phrase, "=?") != NULL) {
        if ((strcasestr(phrase, "?Q?") != NULL) || (strcasestr(phrase, "?B?") != NULL)) {
            hasEncoding = true;
        }
    }

    if (!hasEncoding) {
        return Data::dataWithBytes(phrase, (unsigned int) strlen(phrase))->stringWithDetectedCharset();
    }

    cur_token = 0;
    decoded = NULL;
    mailmime_encoded_phrase_parse(DEFAULT_INCOMING_CHARSET,
        phrase, strlen(phrase),
        &cur_token, DEFAULT_DISPLAY_CHARSET,
        &decoded);

    result = NULL;
    if (decoded != NULL) {
        result = stringWithUTF8Characters(decoded);
    }
    else {
        MCLog("could not decode: %s\n", phrase);
    }

    if (result == NULL) {
      result = string();
    }

    free(decoded);
    
    return result;
}

Data * String::encodedAddressDisplayNameValue()
{
    char * str;
    Data * result;
    
    str = etpan_make_full_quoted_printable(DEFAULT_DISPLAY_CHARSET, UTF8Characters());
    result = Data::dataWithBytes(str, (unsigned int) strlen(str) + 1);
    free(str);
    
    return result;
}

Data * String::encodedMIMEHeaderValue()
{
    char * str;
    Data * result;
    
    str = etpan_make_quoted_printable(DEFAULT_DISPLAY_CHARSET, UTF8Characters(), 0);
    result = Data::dataWithBytes(str, (unsigned int) strlen(str) + 1);
    free(str);
    
    return result;
}

Data * String::encodedMIMEHeaderValueForSubject()
{
    char * str;
    Data * result;
    
    str = etpan_make_quoted_printable(DEFAULT_DISPLAY_CHARSET, UTF8Characters(), 1);
    result = Data::dataWithBytes(str, (unsigned int) strlen(str) + 1);
    free(str);
    
    return result;
}

int String::compareWithCaseSensitive(String * otherString, bool caseSensitive)
{
    if (otherString == NULL) {
        return 1;
    }
    if ((length() == 0) && (otherString->length() == 0)) {
        return 0;
    }
    if ((unicodeCharacters() == NULL) && (otherString->unicodeCharacters() != NULL)) {
        return 0;
    }
    
    if (unicodeCharacters() == NULL) {
        return -1;
    }
    
    if (otherString->unicodeCharacters() == NULL) {
        return 1;
    }
    
#if DISABLE_ICU
    if (caseSensitive) {
        return u_strcmp(unicodeCharacters(), otherString->unicodeCharacters());
    }
    else {
        CFStringRef cfThis = CFStringCreateWithCharactersNoCopy(NULL, mUnicodeChars, mLength, kCFAllocatorNull);
        CFStringRef cfOther = CFStringCreateWithCharactersNoCopy(NULL, otherString->mUnicodeChars, otherString->mLength, kCFAllocatorNull);
        CFComparisonResult result = CFStringCompare(cfThis, cfOther, kCFCompareCaseInsensitive);
        CFRelease(cfThis);
        CFRelease(cfOther);
        return result;
    }
#else
    if (caseSensitive) {
        return u_strcmp(unicodeCharacters(), otherString->unicodeCharacters());
    }
    else {
        return u_strcasecmp(unicodeCharacters(), otherString->unicodeCharacters(), 0);
    }
#endif
}

int String::compare(String * otherString)
{
    return compareWithCaseSensitive(otherString, true);
}

int String::caseInsensitiveCompare(String * otherString)
{
    return compareWithCaseSensitive(otherString, false);
}

//Any-Lower, Any-Upper
String * String::lowercaseString()
{
#if DISABLE_ICU
    CFMutableStringRef cfStr = CFStringCreateMutable(NULL, 0);
    CFStringAppendCharacters(cfStr, (const UniChar *) mUnicodeChars, mLength);
    CFStringLowercase(cfStr, NULL);
    UniChar * characters = (UniChar *) malloc(sizeof(* characters) * mLength);
    CFStringGetCharacters(cfStr, CFRangeMake(0, mLength), characters);
    String * result = String::stringWithCharacters(characters, mLength);
    free(characters);
    CFRelease(cfStr);
    return result;
#else
    UErrorCode err;
    String * result = (String *) copy()->autorelease();
    err = U_ZERO_ERROR;
    u_strToLower(result->mUnicodeChars, result->mLength,
        result->mUnicodeChars, result->mLength,
        NULL, &err);
    return result;
#endif
}

String * String::uppercaseString()
{
#if DISABLE_ICU
    CFMutableStringRef cfStr = CFStringCreateMutable(NULL, 0);
    CFStringAppendCharacters(cfStr, (const UniChar *) mUnicodeChars, mLength);
    CFStringUppercase(cfStr, NULL);
    UniChar * characters = (UniChar *) malloc(sizeof(* characters) * mLength);
    CFStringGetCharacters(cfStr, CFRangeMake(0, mLength), characters);
    String * result = String::stringWithCharacters(characters, mLength);
    free(characters);
    CFRelease(cfStr);
    return result;
#else
    UErrorCode err;
    String * result = (String *) copy()->autorelease();
    err = U_ZERO_ERROR;
    u_strToUpper(result->mUnicodeChars, result->mLength,
        result->mUnicodeChars, result->mLength,
        NULL, &err);
    return result;
#endif
}

void String::appendBytes(const char * bytes, unsigned int length, const char * charset)
{
    if (bytes == NULL) {
        return;
    }

#if __APPLE__
    CFStringEncoding encoding;
    if (strcasecmp(charset, "mutf-7") == 0) {
        encoding = kCFStringEncodingUTF7_IMAP;
    }
    else {
        CFStringRef encodingName = CFStringCreateWithCString(NULL, charset, kCFStringEncodingUTF8);
        encoding = CFStringConvertIANACharSetNameToEncoding(encodingName);
        if (encoding == kCFStringEncodingBig5) {
            encoding = kCFStringEncodingBig5_HKSCS_1999;
        }
        if (encoding == kCFStringEncodingGBK_95) {
            encoding = kCFStringEncodingGB_18030_2000;
        }
        if (encoding == kCFStringEncodingGB_2312_80) {
            encoding = kCFStringEncodingGB_18030_2000;
        }
        CFRelease(encodingName);
    }
    if (encoding == kCFStringEncodingUTF8) {
        appendUTF8CharactersLength(bytes, length);
        return;
    }
    
    bool converted = false;
    int conversionCount = 0;
    while (!converted) {
        CFStringRef cfStr = CFStringCreateWithBytes(NULL, (const UInt8 *) bytes, (CFIndex) length, encoding, false);
        if (cfStr != NULL) {
            converted = true;
            CFDataRef data = CFStringCreateExternalRepresentation(NULL, cfStr, kCFStringEncodingUTF16LE, '_');
            if (data != NULL) {
                UChar * fixedData = (UChar *) malloc(CFDataGetLength(data));
                memcpy(fixedData, CFDataGetBytePtr(data), CFDataGetLength(data));
                unsigned int length = (unsigned int) CFDataGetLength(data) / 2;
                for(int32_t i = 0 ; i < length ; i ++) {
                    if (fixedData[i] == 0) {
                        fixedData[i] = ' ';
                    }
                }
                appendCharactersLength(fixedData, length);
                free(fixedData);
                CFRelease(data);
            }
            CFRelease(cfStr);
        }
        else {
            length --;
            conversionCount ++;
            if (conversionCount > 10) {
                // failed.
                break;
            }
        }
    }
#else
    UErrorCode err;

    // ICU uses "IMAP-mailbox-name" as charset name.
    if (strcasecmp(charset, "mutf-7") == 0) {
        charset = "IMAP-mailbox-name";
    }

    err = U_ZERO_ERROR;
    UConverter * converter = ucnv_open(charset, &err); 
    if (converter == NULL) {
        MCLog("invalid charset %s %i", charset, err);
        return;
    }
    
    err = U_ZERO_ERROR;
    int32_t destLength = ucnv_toUChars(converter, NULL, 0,
        bytes, length, &err);
    int32_t destCapacity = destLength + 1;
    UChar * dest = (UChar *) malloc(destCapacity * sizeof(* dest));
    err = U_ZERO_ERROR;
    destLength = ucnv_toUChars(converter, dest, destCapacity, bytes, length, &err);
    dest[destLength] = 0;
    
    // Fix in case of bad conversion.
    for(int32_t i = 0 ; i < destLength ; i ++) {
        if (dest[i] == 0) {
            dest[i] = ' ';
        }
    }
    
    appendCharactersLength(dest, destLength);
    free(dest);
    
    ucnv_close(converter);
#endif
}

String * String::extractedSubject()
{
    return extractedSubjectAndKeepBracket(false);
}

String * String::extractedSubjectAndKeepBracket(bool keepBracket)
{
    char * result;
    String * str;
    
    result = extract_subject((char *) UTF8Characters(), keepBracket);
    str = String::stringWithUTF8Characters(result);
    free(result);
    
    return str;
}

#if defined(ANDROID) || defined(__ANDROID__)

String * String::uuidString()
{
    char buffer[40];
    FILE * f = fopen("/proc/sys/kernel/random/uuid", "r");
    if (f == NULL) {
        return NULL;
    }
    if (fgets(buffer, sizeof(buffer), f) == NULL) {
        fclose(f);
        return NULL;
    }
    buffer[36] = 0;
    fclose(f);
    return String::stringWithUTF8Characters(buffer);
}

#else

#ifndef _MSC_VER
String * String::uuidString()
{
    uuid_t uuid;
#ifdef _UUID_STRING_T
    uuid_string_t uuidString;
#else
    char uuidString[37];
#endif
    
    uuid_generate(uuid);
    uuid_unparse_lower(uuid, uuidString);
    return String::stringWithUTF8Characters(uuidString);
}
#endif

#endif

unsigned int String::replaceOccurrencesOfString(String * occurrence, String * replacement)
{
    unsigned int count;
    
    if (occurrence->length() == 0)
        return 0;
    
    count = 0;
    UChar * p = mUnicodeChars;
    while (1) {
        UChar * location;
        location = u_strstr(p, occurrence->unicodeCharacters());
        if (location == NULL)
            break;
        p = location + occurrence->length();
        count ++;
    }
    
    UChar * unicodeChars;
    int delta = replacement->length() - occurrence->length();
    int modifiedLength = mLength + delta * count + 1;
    unicodeChars = (UChar *) malloc(modifiedLength * sizeof(* unicodeChars));
    unicodeChars[modifiedLength - 1] = 0;
    UChar * dest_p = unicodeChars;
    p = mUnicodeChars;
    while (1) {
        UChar * location;
        unsigned int count;
        
        location = u_strstr(p, occurrence->unicodeCharacters());
        if (location == NULL)
            break;
        count = (unsigned int) (location - p);
        u_memcpy(dest_p, p, count);
        dest_p += count;
        p += count;
        u_memcpy(dest_p, replacement->unicodeCharacters(), replacement->length());
        p += occurrence->length();
        dest_p += replacement->length();
    }
    // copy remaining
    if(p) {
        unsigned int remainingLength = mLength - (unsigned int) (p - mUnicodeChars);
        memcpy(dest_p, p, remainingLength * sizeof(* p));
        dest_p += remainingLength;
        * dest_p = 0;
    }
    
    free(mUnicodeChars);
    mUnicodeChars = unicodeChars;
    mLength = modifiedLength - 1;
    
    return count;
}

UChar String::characterAtIndex(unsigned int index)
{
    return mUnicodeChars[index];
}

void String::deleteCharactersInRange(Range range)
{
    if (range.location > mLength)
        return;
    
    if (range.length > mLength) {
        range.length = mLength - range.location;
    }
    else if (range.location + range.length > mLength) {
        range.length = mLength - range.location;
    }
    
    int32_t count = mLength - (int32_t) (range.location + range.length);
    memmove(&mUnicodeChars[range.location], &mUnicodeChars[range.location + range.length], count * sizeof(* mUnicodeChars));
    mLength -= range.length;
    mUnicodeChars[mLength] = 0;
}

int String::locationOfString(String * occurrence)
{
    UChar * location;
    location = u_strstr(mUnicodeChars, occurrence->unicodeCharacters());
    if (location == NULL) {
        return -1;
    }
    
    return (int) (location - mUnicodeChars);
}

int String::lastLocationOfString(String * occurrence)
{
    UChar * location;
    location = u_strrstr(mUnicodeChars, occurrence->unicodeCharacters());
    if (location == NULL) {
        return -1;
    }

    return (int) (location - mUnicodeChars);
}

#pragma mark strip HTML

struct parserState {
    int level;
    int enabled;
    int disabledLevel;
    String * result;
    int logEnabled;
    int hasQuote;
    int quoteLevel;
    bool hasText;
    bool lastCharIsWhitespace;
    bool showBlockQuote;
    bool showLink;
    bool hasReturnToLine;
    Array * linkStack;
    Array * paragraphSpacingStack;
};

static void appendQuote(struct parserState * state);

static inline int isWhitespace(UChar ch)
{
    switch (ch) {
        case ' ':
        case '\t':
        case '\n':
        case '\f':
        case '\r':
        case 160:
        case 133:
        case 0x2028:
        case 0x2029:
            return true;
    }
    return false;
}

static void charactersParsed(void * context,
    const xmlChar * ch, int len)
/*" Callback function for stringByStrippingHTML. "*/
{
    struct parserState * state;
    
    state = (struct parserState *) context;
    String * result = state->result;
    
    if (!state->enabled) {
        return;
    }
    
    if (state->logEnabled) {
        MCLog("text %s", ch);
    }
    String * modifiedString;
    modifiedString = new String((const char *) ch, len);
    modifiedString->autorelease();
    bool hasTerminalWhitespace = false;
    bool hasInitialWhitespace = false;
    if (modifiedString->length() > 0) {
        hasInitialWhitespace = isWhitespace(modifiedString->characterAtIndex(0));
        hasTerminalWhitespace = isWhitespace(modifiedString->characterAtIndex(modifiedString->length() - 1));
    }
    modifiedString = modifiedString->stripWhitespace();
    if (hasTerminalWhitespace) {
        if (modifiedString->length() == 0) {
            hasInitialWhitespace = false;
        }
        modifiedString->appendString(MCSTR(" "));
    }

    /*
    if (modifiedString->length() > 0) {
        if (state->lastCharIsWhitespace) {
            if (modifiedString->characterAtIndex(0) == ' ') {
                modifiedString->deleteCharactersInRange(RangeMake(0, 1));
            }
        }
    }
     */

    if (modifiedString->length() > 0) {
        bool lastIsWhiteSpace;
        bool isWhiteSpace;

        isWhiteSpace = false;
        lastIsWhiteSpace = false;
        if (modifiedString->length() > 0) {
            if (modifiedString->characterAtIndex(modifiedString->length() - 1) == ' ') {
                lastIsWhiteSpace = true;
            }
        }
        if (lastIsWhiteSpace && (modifiedString->length() == 1)) {
            isWhiteSpace = true;
        }

        if (isWhiteSpace) {
            if (state->lastCharIsWhitespace) {
                    // do nothing
            }
            else if (!state->hasText) {
                    // do nothing
            }
            else {
                result->appendString(MCSTR(" "));
                state->lastCharIsWhitespace = true;
                state->hasText = true;
            }
        }
        else {
            if (!state->hasQuote) {
                appendQuote(state);
                state->hasQuote = true;
            }
            if (hasInitialWhitespace) {
                if (!state->lastCharIsWhitespace) {
                    result->appendString(MCSTR(" "));
                }
            }
            result->appendString(modifiedString);
            state->lastCharIsWhitespace = lastIsWhiteSpace;
            state->hasText = true;
        }
    }
}

/* GCS: custom error function to ignore errors */
static void structuredError(void * userData,
                            xmlErrorPtr error)
{
    /* ignore all errors */
    (void)userData;
    (void)error;
}

static void appendQuote(struct parserState * state)
{
    if (state->quoteLevel < 0) {
        MCLog("error consistency in quote level");
        state->lastCharIsWhitespace = true;
        return;
    }
    for(int i = 0 ; i < state->quoteLevel ; i ++) {
        state->result->appendString(MCSTR("> "));
    }
    state->lastCharIsWhitespace = true;
}

static void cleanTerminalSpace(String * result)
{
    if (result->length() > 0) {
        if (result->characterAtIndex(result->length() - 1) == ' ') {
            result->deleteCharactersInRange(RangeMake(result->length() - 1, 1));
        }
    }
}

static bool isPreviousLineBlankLine(String * result)
{
    if (result->length() < 2) {
        return false;
    }
    return (result->characterAtIndex(result->length() - 1) == '\n') && (result->characterAtIndex(result->length() - 2) == '\n');
}

static void returnToLine(struct parserState * state)
{
    if (!state->hasQuote) {
        appendQuote(state);
        state->hasQuote = true;
    }

    cleanTerminalSpace(state->result);

    if (!isPreviousLineBlankLine(state->result)) {
        state->result->appendString(MCSTR("\n"));
    }
    state->hasText = false;
    state->lastCharIsWhitespace = true;
    state->hasQuote = false;
    state->hasReturnToLine = false;
}

static void returnToLineAtBeginningOfBlock(struct parserState * state)
{
    if (state->hasText) {
        returnToLine(state);
    }
    state->hasQuote = false;
}

static Set * blockElements(void)
{
    static Set * elements = NULL;
    static MC_LOCK_TYPE lock = MC_LOCK_INITIAL_VALUE;
    
    MC_LOCK(&lock);
    if (elements == NULL) {
        elements = new Set();
        elements->addObject(MCSTR("address"));
        elements->addObject(MCSTR("div"));
        elements->addObject(MCSTR("p"));
        elements->addObject(MCSTR("h1"));
        elements->addObject(MCSTR("h2"));
        elements->addObject(MCSTR("h3"));
        elements->addObject(MCSTR("h4"));
        elements->addObject(MCSTR("h5"));
        elements->addObject(MCSTR("h6"));
        elements->addObject(MCSTR("pre"));
        elements->addObject(MCSTR("ul"));
        elements->addObject(MCSTR("ol"));
        elements->addObject(MCSTR("li"));
        elements->addObject(MCSTR("dl"));
        elements->addObject(MCSTR("dt"));
        elements->addObject(MCSTR("dd"));
        elements->addObject(MCSTR("form"));
        // tables
        elements->addObject(MCSTR("col"));
        elements->addObject(MCSTR("colgroup"));
        elements->addObject(MCSTR("th"));
        elements->addObject(MCSTR("tbody"));
        elements->addObject(MCSTR("thead"));
        elements->addObject(MCSTR("tfoot"));
        elements->addObject(MCSTR("table"));
        elements->addObject(MCSTR("tr"));
        elements->addObject(MCSTR("td"));
    }
    MC_UNLOCK(&lock);
    
    return elements;
}

static HashMap * dictionaryFromAttributes(const xmlChar ** atts)
{
    HashMap * result;
    
    if (atts == NULL)
        return NULL;
    
    result = HashMap::hashMap();
    for(const xmlChar ** curAtt = atts ; * curAtt != NULL ; curAtt += 2) {
        const xmlChar * attrName;
        const xmlChar * attrValue;
        String * name;
        
        attrName = * curAtt;
        attrValue = * (curAtt + 1);
        if ((attrName == NULL) || (attrValue == NULL))
            continue;
        
        name = String::stringWithUTF8Characters((const char *) attrName);
        name = name->lowercaseString();
        result->setObjectForKey(name, String::stringWithUTF8Characters((const char *) attrValue));
    }
    
    return result;
}

static void elementStarted(void * ctx, const xmlChar * name, const xmlChar ** atts)
{
    struct parserState * state;
    
    state = (struct parserState *) ctx;
    
    if (state->logEnabled) {
        MCLog("parsed element %s", name);
    }
    
    if (strcasecmp((const char *) name, "blockquote") == 0) {
        state->quoteLevel ++;
    }
    else if (strcasecmp((const char *) name, "a") == 0) {
        AutoreleasePool * pool;
        String * link = NULL;
        HashMap * attributes;

        pool = new AutoreleasePool();
        attributes = dictionaryFromAttributes(atts);
        if (attributes != NULL) {
            link = (String *) attributes->objectForKey(MCSTR("href"));
        }
        if (link == NULL)
            link = MCSTR("");
        
        Array * item;
        item = new Array();
        item->addObject(link);
        item->addObject(Value::valueWithUnsignedIntValue(state->result->length()));
        state->linkStack->addObject(item);
        item->release();
        pool->release();
    }
    else if (strcasecmp((const char *) name, "p") == 0) {
        bool hasSpacing;
        String * style;
        AutoreleasePool * pool;
        HashMap * attributes;
        
        hasSpacing = true;
        
        pool = new AutoreleasePool();
        attributes = dictionaryFromAttributes(atts);
        if (attributes != NULL) {
            style = (String *) attributes->objectForKey(MCSTR("style"));
            if (style != NULL) {
                if (style->locationOfString(MCSTR("margin: 0.0px 0.0px 0.0px 0.0px;")) != -1) {
                    hasSpacing = false;
                }
                else if (style->locationOfString(MCSTR("margin: 0px 0px 0px 0px;")) != -1) {
                    hasSpacing = false;
                }
                else if (style->locationOfString(MCSTR("margin: 0.0px;")) != -1) {
                    hasSpacing = false;
                }
                else if (style->locationOfString(MCSTR("margin: 0px;")) != -1) {
                    hasSpacing = false;
                }
            }
        }
        pool->release();
        
        state->paragraphSpacingStack->addObject(Value::valueWithBoolValue(hasSpacing));
    }
    
    if (state->enabled) {
        if (state->level == 1) {
            if (strcasecmp((const char *) name, "head") == 0) {
                state->enabled = 0;
                state->disabledLevel = state->level;
            }
        }
        if (strcasecmp((const char *) name, "style") == 0) {
            state->enabled = 0;
            state->disabledLevel = state->level;
        }
        else if (strcasecmp((const char *) name, "script") == 0) {
            state->enabled = 0;
            state->disabledLevel = state->level;
        }
        else if (strcasecmp((const char *) name, "p") == 0) {
            returnToLineAtBeginningOfBlock(state);
            if (((Value *) state->paragraphSpacingStack->lastObject())->boolValue()) {
                returnToLine(state);
            }
        }
        else if (blockElements()->containsObject(String::stringWithUTF8Characters((const char *) name)->lowercaseString())) {
            returnToLineAtBeginningOfBlock(state);
        }
        else if (strcasecmp((const char *) name, "blockquote") == 0) {
            if (!state->showBlockQuote) {
                AutoreleasePool * pool;
                String * type;
                bool cite;
                HashMap * attributes;
                
                cite = false;
                pool = new AutoreleasePool();
                attributes = dictionaryFromAttributes(atts);
                if (attributes != NULL) {
                    type = (String *) attributes->objectForKey(MCSTR("type"));
                    if (type != NULL) {
                        if (type->caseInsensitiveCompare(MCSTR("cite")) == 0) {
                            cite = true;
                        }
                    }
                }
                pool->release();
                
                if (cite) {
                    state->enabled = 0;
                    state->disabledLevel = state->level;
                }
                else {
                    returnToLineAtBeginningOfBlock(state);
                }
            }
            else {
                returnToLineAtBeginningOfBlock(state);
            }
        }
        else if (strcasecmp((const char *) name, "br") == 0) {
            returnToLine(state);
            state->hasReturnToLine = true;
        }
    }
    
    state->level ++;
}

static void elementEnded(void * ctx, const xmlChar * name)
{
    struct parserState * state;
    
    state = (struct parserState *) ctx;
    
    if (state->logEnabled) {
        MCLog("ended element %s", name);
    }
    
    if (strcasecmp((const char *) name, "blockquote") == 0) {
        state->quoteLevel --;
    }
    
    state->level --;
    if (!state->enabled) {
        if (state->level == state->disabledLevel) {
            state->enabled = 1;
        }
    }
    
    bool hasReturnToLine;
    
    hasReturnToLine = false;
    if (strcasecmp((const char *) name, "a") == 0) {
        if (state->enabled) {
            Array * item;
            String * link;
            unsigned int offset;
            
            item = (Array *) state->linkStack->lastObject();
            link = (String *) item->objectAtIndex(0);
            offset = ((Value *) item->objectAtIndex(1))->unsignedIntValue();
            if (state->showLink) {
                if (offset != state->result->length()) {
                    if (link->length() > 0) {
                        if (!state->result->hasSuffix(link)) {
                            if (!state->lastCharIsWhitespace) {
                                state->result->appendUTF8Characters(" ");
                            }
                            state->result->appendUTF8Characters("(");
                            state->result->appendString(link);
                            state->result->appendUTF8Characters(")");
                            state->hasText = true;
                            state->lastCharIsWhitespace = false;
                        }
                    }
                }
            }
        }
        
        state->linkStack->removeObjectAtIndex(state->linkStack->count() - 1);
    }
    else if (strcasecmp((const char *) name, "p") == 0) {
        if (state->enabled) {
            if (((Value *) state->paragraphSpacingStack->lastObject())->boolValue()) {
                returnToLine(state);
            }
        }
        state->paragraphSpacingStack->removeObjectAtIndex(state->paragraphSpacingStack->count() - 1);
        hasReturnToLine = true;
    }
    else if (blockElements()->containsObject(String::stringWithUTF8Characters((const char *) name)->lowercaseString())) {
        hasReturnToLine = true;
    }
    else if (strcasecmp((const char *) name, "blockquote") == 0) {
        hasReturnToLine = true;
    }
    
    if (hasReturnToLine) {
        if (state->enabled) {
            if (!state->hasReturnToLine) {
                returnToLine(state);
            }
        }
    }
}

static void commentParsed(void * ctx, const xmlChar * value)
{
    struct parserState * state;
    
    state = (struct parserState *) ctx;
    
    if (state->logEnabled) {
        MCLog("comments %s", value);
    }
}

void initializeLibXML()
{
    static bool initDone = false;
    static MC_LOCK_TYPE lock = MC_LOCK_INITIAL_VALUE;
    
    MC_LOCK(&lock);
    if (!initDone) {
        initDone = true;
        xmlInitParser();
        
        /* GCS: override structuredErrorFunc to mine so
         I can ignore errors */
        xmlSetStructuredErrorFunc(xmlGenericErrorContext,
                                  &structuredError);
    }
    MC_UNLOCK(&lock);
}

String * String::flattenHTMLAndShowBlockquoteAndLink(bool showBlockquote, bool showLink)
/*" Interpretes the receiver als HTML, removes all tags
 and returns the plain text. "*/
{
    initializeLibXML();
    
    int mem_base = xmlMemBlocks();
    String * result = String::string();
    xmlSAXHandler handler;
    memset(&handler, 0, sizeof(xmlSAXHandler));
    handler.characters = charactersParsed;
    handler.startElement = elementStarted;
    handler.endElement = elementEnded;
    handler.comment = commentParsed;
    struct parserState state;
    state.result = result;
    state.level = 0;
    state.enabled = 1;
    state.logEnabled = 0;
    state.disabledLevel = 0;
    state.quoteLevel = 0;
    state.hasText = false;
    state.hasQuote = false;
    state.hasReturnToLine = false;
    state.showBlockQuote = showBlockquote;
    state.showLink = showLink;
    state.lastCharIsWhitespace = true;
    state.linkStack = new Array();
    state.paragraphSpacingStack = new Array();
    
    const char * characters = cleanedHTMLString()->UTF8Characters();
    
    htmlSAXParseDoc((xmlChar*) characters, "utf-8", &handler, &state);
    
    if (mem_base != xmlMemBlocks()) {
        MCLog("Leak of %d blocks found in htmlSAXParseDoc",
            xmlMemBlocks() - mem_base);
    }

    cleanTerminalSpace(state.result);
    state.paragraphSpacingStack->release();
    state.linkStack->release();

    return result;
}

String * String::flattenHTMLAndShowBlockquote(bool showBlockquote)
{
    return flattenHTMLAndShowBlockquoteAndLink(showBlockquote, true);
}

String * String::flattenHTML()
{
    return flattenHTMLAndShowBlockquote(true);
}

String * String::stripWhitespace()
{
    String * str = (String *)copy();

    // replace space-like characters with space.
    const UChar * source = str->unicodeCharacters();
    UChar * dest = str->mUnicodeChars;
    while (* source != 0) {
        if (* source == '\t') {
            * dest = ' ';
        }
        else if (* source == '\n') {
            * dest = ' ';
        }
        else if (* source == '\f') {
            * dest = ' ';
        }
        else if (* source == '\r') {
            * dest = ' ';
        }
        else if (* source == 160) {
            * dest = ' ';
        }
        else if (* source == 133) {
            * dest = ' ';
        }
        else if (* source == 0x2028) {
            * dest = ' ';
        }
        else if (* source == 0x2029) {
            * dest = ' ';
        }
        else {
            * dest = * source;
        }
        dest ++;
        source ++;
    }

    // skip spaces at the beginning.
    source = str->unicodeCharacters();
    dest = str->mUnicodeChars;
    while (* source == ' ') {
        source ++;
    }

    // copy content
    while (* source != 0) {
        while ((* source == ' ') && (* (source + 1) == ' ')) {
            source ++;
        }
        * dest = * source;
        source ++;
        dest ++;
    }
    * dest = 0;
    str->mLength = (unsigned int) (dest - str->mUnicodeChars);

    // skip spaces at the end.
    if (str->mLength > 0) {
        while (* (dest - 1) == ' ') {
            dest --;
        }
        * dest = 0;
        str->mLength = (unsigned int) (dest - str->mUnicodeChars);
    }

    str->autorelease();
    return str;
}


bool String::hasSuffix(String * suffix)
{
    if (mLength >= suffix->mLength) {
        if (u_memcmp(mUnicodeChars + (mLength - suffix->mLength),
          suffix->mUnicodeChars, suffix->mLength) == 0) {
            return true;
        }
    }
    return false;
}

bool String::hasPrefix(String * prefix)
{
    if (mLength >= prefix->mLength) {
        if (u_memcmp(prefix->mUnicodeChars, mUnicodeChars, prefix->mLength) == 0) {
            return true;
        }
    }
    return false;
}

String * String::lastPathComponent()
{
    // TODO: Improve Windows compatibility.
    if (mUnicodeChars == NULL)
        return MCSTR("");
    UChar * component = u_strrchr(mUnicodeChars, PATH_SEPARATOR_CHAR);
    if (component == NULL)
        return (String *) this->copy()->autorelease();
    return String::stringWithCharacters(component + 1);
}

String * String::pathExtension()
{
    UChar * component = u_strrchr(mUnicodeChars, '.');
    if (component == NULL)
        return MCSTR("");
    return String::stringWithCharacters(component + 1);
}

Data * String::dataUsingEncoding(const char * charset)
{
    if (charset == NULL) {
        charset = "utf-8";
    }
    
#if __APPLE__
    Data * data;
    
    data = NULL;
    CFStringEncoding encoding;
    if (strcasecmp(charset, "mutf-7") == 0) {
        encoding = kCFStringEncodingUTF7_IMAP;
    }
    else {
        CFStringRef encodingName = CFStringCreateWithCString(NULL, charset, kCFStringEncodingUTF8);
        encoding = CFStringConvertIANACharSetNameToEncoding(encodingName);
        CFRelease(encodingName);
    }
    CFStringRef cfStr = CFStringCreateWithBytes(NULL, (const UInt8 *) mUnicodeChars,
        (CFIndex) mLength * sizeof(* mUnicodeChars), kCFStringEncodingUTF16LE, false);
    if (cfStr != NULL) {
        CFDataRef cfData = CFStringCreateExternalRepresentation(NULL, cfStr, encoding, '_');
        if (cfData != NULL) {
            data = Data::dataWithBytes((const char *) CFDataGetBytePtr(cfData),
                                       (unsigned int) CFDataGetLength(cfData));
            CFRelease(cfData);
        }
        CFRelease(cfStr);
    }
    
    return data;
#else
    UErrorCode err;
    Data * data;
    
    // ICU uses "IMAP-mailbox-name" as charset name.
    if (strcasecmp(charset, "mutf-7") == 0) {
        charset = "IMAP-mailbox-name";
    }

    err = U_ZERO_ERROR;
    UConverter * converter = ucnv_open(charset, &err); 
    if (converter == NULL) {
        MCLog("invalid charset %s %i", charset, err);
        return NULL;
    }

    err = U_ZERO_ERROR;
    int32_t destLength = ucnv_fromUChars(converter, NULL, 0, mUnicodeChars, mLength, &err);
    int32_t destCapacity = destLength + 1;
    char * dest = (char *) malloc(destCapacity * sizeof(* dest));
    err = U_ZERO_ERROR;
    destLength = ucnv_fromUChars(converter, dest, destCapacity, mUnicodeChars, mLength, &err);
    dest[destLength] = 0;
    
    // Fix in case of bad conversion.
    for(int32_t i = 0 ; i < destLength ; i ++) {
        if (dest[i] == 0) {
            dest[i] = ' ';
        }
    }
    
    data = Data::dataWithBytes(dest, destLength);
    
    free(dest);
    
    ucnv_close(converter);
    
    return data;
#endif
}

const char * String::fileSystemRepresentation()
{
    return UTF8Characters();
}

String * String::stringWithFileSystemRepresentation(const char * filename)
{
    return stringWithUTF8Characters(filename);
}

String * String::stringByAppendingPathComponent(String * component)
{
    // TODO: Improve Windows compatibility.
    String * result = (String *) this->copy()->autorelease();
    if (result->length() > 0) {
        UChar lastChar = result->unicodeCharacters()[result->length() - 1];
        if (lastChar != PATH_SEPARATOR_CHAR) {
            result->appendUTF8Characters(PATH_SEPARATOR_STRING);
        }
    }
    result->appendString(component);
    return result;
}

String * String::stringByDeletingLastPathComponent()
{
    String * currentString = this;
    if (currentString->isEqual(MCSTR(PATH_SEPARATOR_STRING))) {
        return currentString;
    }
    if (currentString->length() == 0) {
        return currentString;
    }
    if (currentString->unicodeCharacters()[currentString->length() - 1] == PATH_SEPARATOR_CHAR) {
        currentString = currentString->substringToIndex(currentString->length() - 1);
    }
    String * component = currentString->lastPathComponent();
    currentString = currentString->substringToIndex(currentString->length() - component->length());
    if (currentString->isEqual(MCSTR(PATH_SEPARATOR_STRING))) {
        return currentString;
    }
    if (currentString->length() == 0) {
        return currentString;
    }
    if (currentString->unicodeCharacters()[currentString->length() - 1] == PATH_SEPARATOR_CHAR) {
        currentString = currentString->substringToIndex(currentString->length() - 1);
    }
    return currentString;
}

String * String::stringByDeletingPathExtension()
{
    int location = lastLocationOfString(MCSTR("."));
    if ((location == -1) || (location == 0)) {
        return this;
    }
    return substringToIndex(location);
}

Array * String::componentsSeparatedByString(String * separator)
{
    UChar * p;
    Array * result;
    
    result = Array::array();
    p = mUnicodeChars;
    while (1) {
        UChar * location;
#if 0
        location = u_strstr(p, separator->unicodeCharacters());
        if (location == NULL) {
            break;
        }
#else
        location = NULL;
        while (location == NULL) {
            int remaining = length() - (int) (p - mUnicodeChars);
            location = (UChar *) memmem(p, remaining * sizeof(UChar), separator->unicodeCharacters(), separator->length() * sizeof(UChar));
            if (location == NULL) {
                break;
            }
            // If it's odd, it's an invalid location. Keep looking for the pattern.
            if (((char *) location - (char *) p) % sizeof(UChar) != 0) {
                p = (UChar *) (((char *) location) + 1);
                location = NULL;
            }
        }
        if (location == NULL) {
            break;
        }
#endif
        
        unsigned int length = (unsigned int) (location - p);
        String * value = new String(p, length);
        result->addObject(value);
        value->release();
        
        p = location + separator->length();
    }
    unsigned int length = (unsigned int) (mLength - (p - mUnicodeChars));
    if (length > mLength) {
        fprintf(stderr, "trying to split string: |%s| |%s| %i %i %p %p\n", MCUTF8(this), MCUTF8(separator), length, mLength, p, mUnicodeChars);
        return result;
    }
    MCAssert(length <= mLength);
    String * value = new String(p, length);
    result->addObject(value);
    value->release();
    
    return result;
}

int String::intValue()
{
    return (int) strtol(UTF8Characters(), NULL, 10);
}

unsigned int String::unsignedIntValue()
{
    return (unsigned int) strtoul(UTF8Characters(), NULL, 10);
}

long String::longValue()
{
    return strtol(UTF8Characters(), NULL, 10);
}

unsigned long String::unsignedLongValue()
{
    return strtoul(UTF8Characters(), NULL, 10);
}

long long String::longLongValue()
{
    return strtoll(UTF8Characters(), NULL, 10);
}

unsigned long long String::unsignedLongLongValue()
{
    return strtoull(UTF8Characters(), NULL, 10);
}

double String::doubleValue()
{
    return strtod(UTF8Characters(), NULL);

}

Data * String::mUTF7EncodedData()
{
    return dataUsingEncoding("mutf-7");
}

String * String::stringWithMUTF7Data(Data * data)
{
    return data->stringWithCharset("mutf-7");
}

String * String::mUTF7EncodedString()
{
    Data * data = mUTF7EncodedData();
    return data->stringWithCharset("us-ascii");
}

String * String::mUTF7DecodedString()
{
    Data * data = dataUsingEncoding("utf-8");
    return stringWithMUTF7Data(data);
}

String * String::substringFromIndex(unsigned int idx)
{
    return substringWithRange(RangeMake(idx, length() - idx));
}

String * String::substringToIndex(unsigned int idx)
{
    return substringWithRange(RangeMake(0, idx));
}

String * String::substringWithRange(Range range)
{
    if (range.location > length()) {
        return MCSTR("");
    }
    
    if (range.location + range.length > length()) {
        range.length = length() - range.location;
    }
    
    return stringWithCharacters(unicodeCharacters() + range.location, (unsigned int) range.length);
}

static chash * uniquedStringHash = NULL;
static MC_LOCK_TYPE lock = MC_LOCK_INITIAL_VALUE;

static void initUniquedStringHash()
{
    uniquedStringHash = chash_new(CHASH_DEFAULTSIZE, CHASH_COPYKEY);
}

String * String::uniquedStringWithUTF8Characters(const char * UTF8Characters)
{
    chashdatum key;
    chashdatum value;
    static pthread_once_t once = PTHREAD_ONCE_INIT;
    int r;
    
    if (UTF8Characters == NULL) {
        return NULL;
    }

    pthread_once(&once, initUniquedStringHash);
    key.data = (void *) UTF8Characters;
    key.len = (unsigned int) strlen(UTF8Characters);
    MC_LOCK(&lock);
    r = chash_get(uniquedStringHash, &key, &value);
    if (r == 0) {
        MC_UNLOCK(&lock);
        return (String *) value.data;
    }
    else {
        value.data = new String(UTF8Characters);
        value.len = 0;
        chash_set(uniquedStringHash, &key, &value, NULL);
        MC_UNLOCK(&lock);
        return (String *) value.data;
    }
}

String * String::htmlEncodedString()
{
    String * htmlStr = String::string();
#define kBufSz 2000
    
    const char * inStr = UTF8Characters();
    const uint32_t kInStrSz = (const uint32_t) strlen(inStr);
    int nInStrConsumed = 0;
    
    static char buf[kBufSz];
    
    int outVal = -1;
    int nBufConsumed;
    int inStrSz;
    do {
        nBufConsumed = kBufSz-1;
        inStrSz = kInStrSz - nInStrConsumed;
        outVal = htmlEncodeEntities( (unsigned char*)buf,
                                    &nBufConsumed,
                                    (const unsigned char*)inStr+nInStrConsumed,
                                    &inStrSz,
                                    0 );
        if (-2 == outVal || -1 == outVal) {
            MCLog("Unable to encode html entities of %s", MCUTF8DESC(this));
            break;
        }
        buf[nBufConsumed] = '\0';
        htmlStr->appendUTF8Characters(buf);
        nInStrConsumed += inStrSz;
    } while (nInStrConsumed != kInStrSz);
    
    htmlStr->replaceOccurrencesOfString(MCSTR("\n"), MCSTR("<br/>"));
    
    return htmlStr;
}

String * String::cleanedHTMLString()
{
    return HTMLCleaner::cleanHTML(this);
}

String * String::htmlMessageContent()
{
    String * str = this;
    
    Array * lines = str->componentsSeparatedByString(MCSTR("\n"));
    
    while (1) {
        if (lines->count() == 0) {
            break;
        }
        
        if (((String *) lines->lastObject())->length() > 0) {
            break;
        }
        
        lines->removeLastObject();
    }
    
    String * localString;
    int state;
    localString = String::string();
    
    String * quoted = NULL;
    state = 0;
    mc_foreacharray(String, line, lines) {
        if (state == 0) {
            if (line->hasPrefix(MCSTR(">"))) {
                state = 1;
                quoted = new String();
                int i = 1;
                while (i < line->length()) {
                    if (line->characterAtIndex(i) != ' ') {
                        break;
                    }
                    i ++;
                }
                quoted->appendString(line->substringFromIndex(i));
                quoted->appendString(MCSTR("\n"));
            }
            else {
                localString->appendString(line->htmlEncodedString());
                localString->appendString(MCSTR("<br/>"));
            }
        }
        else if (state == 1) {
            if (line->hasPrefix(MCSTR(">"))) {
                int i = 1;
                while (i < line->length()) {
                    if (line->characterAtIndex(i) != ' ') {
                        break;
                    }
                    i ++;
                }
                quoted->appendString(line->substringFromIndex(i));
                quoted->appendString(MCSTR("\n"));
            }
            else {
                if (quoted != NULL) {
                    localString->appendString(MCSTR("<blockquote type=\"cite\">"));
                    localString->appendString(quoted->htmlMessageContent());
                    localString->appendString(MCSTR("</blockquote>"));
                    MC_SAFE_RELEASE(quoted);
                    state = 0;
                }
                localString->appendString(line->htmlEncodedString());
                localString->appendString(MCSTR("<br/>"));
            }
        }
    }
    
    if (quoted != NULL) {
        localString->appendString(MCSTR("<blockquote type=\"cite\">"));
        localString->appendString(quoted->htmlMessageContent());
        localString->appendString(MCSTR("</blockquote>"));
        MC_SAFE_RELEASE(quoted);
    }
    
    return localString;
}

bool String::isEqualCaseInsensitive(String * otherString)
{
    return caseInsensitiveCompare(otherString) == 0;
}

Data * String::decodedBase64Data()
{
    const char * utf8 = UTF8Characters();
    unsigned int encoded_len = (unsigned int) strlen(utf8);
    int decoded_len = 0;
    char * decoded = MCDecodeBase64(utf8, encoded_len, &decoded_len);
    Data * result = Data::dataWithBytes(decoded, decoded_len);
    free(decoded);
    return result;
}

static int hexValue(const char * code) {
    int value = 0;
    const char * pch = code;
    for (;;) {
        int digit = *pch++;
        if (digit >= '0' && digit <= '9') {
            value += digit - '0';
        }
        else if (digit >= 'A' && digit <= 'F') {
            value += digit - 'A' + 10;
        }
        else if (digit >= 'a' && digit <= 'f') {
            value += digit - 'a' + 10;
        }
        else {
            return -1;
        }
        if (pch == code + 2) {
            return value;
        }
        value <<= 4;
    }
}

String * String::urlDecodedString()
{
    Data * sourceData = dataUsingEncoding();
    const char * source = sourceData->bytes();
    char * start = (char *) malloc(sourceData->length() + 1);
    char * dest = start;
    unsigned int i = 0;
    while (i < sourceData->length()) {
        switch (source[i]) {
            case '%':
            {
                if (i + 2 < sourceData->length()) {
                    int value = hexValue(&source[i + 1]);
                    if (value >= 0) {
                        *(dest++) = value;
                        i += 3;
                    }
                    else {
                        *dest++ = '?';
                        i ++;
                    }
                }
                else {
                    *dest++ = '?';
                    i ++;
                }
                break;
            }
            default:
            {
                *dest++ = source[i];
                i ++;
                break;
            }
        }
    }
    * dest = 0;
    String * result = String::stringWithUTF8Characters(start);
    free(start);
    return result;
}

static inline bool isValidUrlChar(char ch) {
    return strchr("$&+,/:;=?@[]#!'()* ", ch) == NULL;
}

String * String::urlEncodedString()
{
    const char * digits = "0123456789ABCDEF";
    Data * sourceData = dataUsingEncoding();
    const char * source = sourceData->bytes();
    char * start = (char *) malloc(sourceData->length() * 3 + 1);
    char * dest = start;
    unsigned int i = 0;
    while (i < sourceData->length()) {
        unsigned char ch = (unsigned char) source[i];
        if (isValidUrlChar(ch)) {
            *dest++ = ch;
        } else {
            *dest++ = '%';
            *dest++ = digits[(ch >> 4) & 0x0F];
            *dest++ = digits[       ch & 0x0F];
        }
        i ++;
    }
    *dest = 0;
    String * result = String::stringWithUTF8Characters(dest);
    free(start);

    return result;
}

HashMap * String::serializable()
{
    HashMap * result = Object::serializable();
    result->setObjectForKey(MCSTR("value"), this);
    return result;
}

void String::importSerializable(HashMap * serializable)
{
    String * value = (String *) serializable->objectForKey(MCSTR("value"));
    setString(value);
}

static void * createObject()
{
    return new String();
}

INITIALIZE(String)
{
    Object::registerObjectConstructor("mailcore::String", &createObject);

    UChar chars_160[1] = {160};
    s_unicode160 = new String(chars_160, 1);
    UChar chars_133[1] = {133};
    s_unicode133 = new String(chars_133, 1);
    UChar chars_2028[1] = {0x2028};
    s_unicode2028 = new String(chars_2028, 1);
}
