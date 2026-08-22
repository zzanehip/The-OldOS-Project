#include "MCWin32.h" // should be first include.

#include "MCData.h"

#define USE_UCHARDET 0

#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <pthread.h>
#if USE_UCHARDET
#include <uchardet/uchardet.h>
#else
#include <unicode/ucsdet.h>
#endif
#include <libetpan/libetpan.h>
#if __APPLE__
#include <iconv.h>
#include <CoreFoundation/CoreFoundation.h>
#endif

#include "MCDefines.h"
#include "MCString.h"
#include "MCHash.h"
#include "MCUtils.h"
#include "MCHashMap.h"
#include "MCBase64.h"
#include "MCSet.h"
#include "MCLock.h"
#include "MCDataDecoderUtils.h"

#define MCDATA_DEFAULT_CHARSET "iso-8859-1"

using namespace mailcore;

static int isPowerOfTwo (unsigned int x)
{
    return ((x != 0) && !(x & (x - 1)));
}

void Data::allocate(unsigned int length, bool force)
{
    if (mExternallyAllocatedMemory) {
        // We don't know how this memory was allocated.
        // Possibly this memory is readonly.
        // So we need fallback to malloc'ed implementation.

        unsigned int bytes_len = 0;
        char * bytes = NULL;
        if (mBytes) {
            bytes_len = mLength;
            bytes = (char *) malloc(mLength);
            memcpy(bytes, mBytes, mLength);
        }

        reset();
        mBytes = bytes;
        mLength = bytes_len;
        mAllocated = bytes_len;
    }

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
    
    mBytes = (char *) realloc(mBytes, mAllocated);
}

void Data::reset()
{
    if (mExternallyAllocatedMemory) {
        if (mBytes && mBytesDeallocator) {
            mBytesDeallocator(mBytes, mLength);
        }
    } else {
        free(mBytes);
    }
    init();
}

void Data::init()
{
    mAllocated = 0;
    mLength = 0;
    mBytes = NULL;
    mExternallyAllocatedMemory = false;
    mBytesDeallocator = NULL;
}

Data::Data()
{
    init();
}

Data::Data(Data * otherData) : Object()
{
    init();
    appendData(otherData);
}

Data::Data(const char * bytes, unsigned int length)
{
    init();
    allocate(length, true);
    appendBytes(bytes, length);
}

Data::Data(int capacity)
{
    init();
    allocate(capacity, true);
}

Data::~Data()
{
    reset();
}

Data * Data::dataWithBytes(const char * bytes, unsigned int length)
{
    Data * result = new Data(bytes, length);
    return (Data *) result->autorelease();
}

char * Data::bytes()
{
    return mBytes;
}

unsigned int Data::length()
{
    return mLength;
}

void Data::increaseCapacity(unsigned int length)
{
    allocate(mLength + length);
}

void Data::appendData(Data * otherData)
{
    appendBytes(otherData->bytes(), otherData->length());
}

void Data::appendBytes(const char * bytes, unsigned int length)
{
    allocate(mLength + length);
    memcpy(&mBytes[mLength], bytes, length);
    mLength += length;
}

void Data::setBytes(const char * bytes, unsigned int length)
{
    reset();
    appendBytes(bytes, length);
}

void Data::setData(Data * otherData)
{
    reset();
    appendData(otherData);
}

String * Data::description()
{
    return String::stringWithUTF8Format("<%s:%p %i bytes>", MCUTF8(className()), this, length());
}

Object * Data::copy()
{
    return new Data(this);
}

bool Data::isEqual(Object * otherObject)
{
    Data * otherData = (Data *) otherObject;
    if (length() != otherData->length())
        return false;
    if (memcmp(bytes(), otherData->bytes(), mLength) != 0)
        return false;
    return true;
}

unsigned int Data::hash()
{
    return hashCompute(mBytes, mLength);
}

String * Data::stringWithDetectedCharset()
{
    String * result;
    result = stringWithDetectedCharset(NULL, false);
    return result;
}

static String * normalizeCharset(String * charset)
{
    if ((charset->caseInsensitiveCompare(MCSTR("iso-2022-jp")) == 0) ||
    (charset->caseInsensitiveCompare(MCSTR("iso-2022-jp-2")) == 0)) {
        charset = MCSTR("iso-2022-jp-2");
    }
    else if (charset->caseInsensitiveCompare(MCSTR("ks_c_5601-1987")) == 0) {
        charset = MCSTR("euckr");
    }
    else if ((charset->caseInsensitiveCompare(MCSTR("iso-8859-8-i")) == 0) ||
    (charset->caseInsensitiveCompare(MCSTR("iso-8859-8-e")) == 0)) {
        charset = MCSTR("iso-8859-8");
    }
    else if ((charset->caseInsensitiveCompare(MCSTR("GB2312")) == 0) ||
    (charset->caseInsensitiveCompare(MCSTR("GB_2312-80")) == 0)) {
        charset = MCSTR("GBK");
    }
    
    return charset->lowercaseString();
}

String * Data::stringWithCharset(const char * charset)
{
    String * result = new String(this, charset);
    if ((length() != 0) && (result->length() == 0)) {
        result->release();
        return NULL;
    }
    return (String *) result->autorelease();
}

static bool isHintCharsetValid(String * hintCharset)
{
    static MC_LOCK_TYPE lock = MC_LOCK_INITIAL_VALUE;
    static Set * knownCharset = NULL;
    
    MC_LOCK(&lock);
    if (knownCharset == NULL) {
        knownCharset = new Set();
        
#if !USE_UCHARDET
        UCharsetDetector * detector;
        UEnumeration * iterator;
        UErrorCode err = U_ZERO_ERROR;
        
        detector = ucsdet_open(&err);
        iterator = ucsdet_getAllDetectableCharsets(detector, &err);
        while (1) {
            const char * validCharset = uenum_next(iterator, NULL, &err);
            if (err != U_ZERO_ERROR)
                break;
            if (validCharset == NULL)
                break;
            knownCharset->addObject(String::stringWithUTF8Characters(validCharset));
        }
        uenum_close(iterator);
        ucsdet_close(detector);
#else
        const char * charset_list[] = {
            "Big5",
            "EUC-JP",
            "EUC-KR",
            "x-euc-tw",
            "gb18030",
            "ISO-8859-8",
            "windows-1255",
            "windows-1252",
            "Shift_JIS",
            "UTF-8",
            "UTF-16",
            "HZ-GB-2312",
            "ISO-2022-CN",
            "ISO-2022-JP",
            "ISO-2022-KR",
            "ISO-8859-5",
            "windows-1251",
            "KOI8-R",
            "x-mac-cyrillic",
            "IBM866",
            "IBM855",
            "ISO-8859-7",
            "windows-1253",
            "ISO-8859-2",
            "windows-1250",
            "TIS-620",
        };
        for(unsigned int i = 0 ; i < sizeof(charset_list) / sizeof(charset_list[0]) ; i ++) {
            String * str = String::stringWithUTF8Characters(charset_list[i]);
            str = str->lowercaseString();
            knownCharset->addObject(str);
        }
#endif
    }
    MC_UNLOCK(&lock);
    
    if (hintCharset != NULL) {
        hintCharset = normalizeCharset(hintCharset);
        
        if (hintCharset->isEqual(MCSTR("tis-620"))) {
            return true;
        }
        else if (hintCharset->isEqual(MCSTR("koi8-r"))) {
            return true;
        }
        else if (hintCharset->isEqual(MCSTR("euc-kr"))) {
            return true;
        }
        else if (hintCharset->isEqual(MCSTR("windows-1256"))) {
            return true;
        }
        
        // If it's among the known charset, we want to try to detect it
        // to validate that it's the correct charset.
        if (!knownCharset->containsObject(hintCharset)) {
            return true;
        }
    }
    
    return false;
}

String * Data::stringWithDetectedCharset(String * hintCharset, bool isHTML)
{
    String * result;
    String * charset;
    
    if (hintCharset != NULL) {
        hintCharset = normalizeCharset(hintCharset);
    }
    if (isHintCharsetValid(hintCharset)) {
        charset = hintCharset;
    }
    else {
        if (hintCharset == NULL) {
            charset = charsetWithFilteredHTML(isHTML);
        }
        else {
            charset = charsetWithFilteredHTML(isHTML, hintCharset);
        }
    }
    
    if (charset == NULL) {
        charset = MCSTR(MCDATA_DEFAULT_CHARSET);
    }
    
    charset = normalizeCharset(charset);
    
    // Remove whitespace at the end of the string to fix conversion.
    if (charset->isEqual(MCSTR("iso-2022-jp-2"))) {
        Data * data = this;
        result = data->stringWithCharset("iso-2022-jp-2");
        if (result == NULL) {
            result = data->stringWithCharset("iso-2022-jp");
        }
        if (result == NULL) {
            result = MCSTR("");
        }
        
        return result;
    }

    result = stringWithCharset(charset->UTF8Characters());
    if (result == NULL) {
        result = stringWithCharset("iso-8859-1");
    }
    if (result == NULL) {
        result = stringWithCharset("windows-1252");
    }
    if (result == NULL) {
        result = stringWithCharset("utf-8");
    }
    if (result == NULL) {
        result = MCSTR("");
    }
    
    return result;
}

String * Data::charsetWithFilteredHTMLWithoutHint(bool filterHTML)
{
#if !USE_UCHARDET
    UCharsetDetector * detector;
    const UCharsetMatch * match;
    UErrorCode err = U_ZERO_ERROR;
    const char * cName;
    String * result;
    
    detector = ucsdet_open(&err);
    ucsdet_setText(detector, bytes(), length(), &err);
    ucsdet_enableInputFilter(detector, filterHTML);
    match = ucsdet_detect(detector, &err);
    if (match == NULL) {
        ucsdet_close(detector);
        return NULL;
    }
    
    cName = ucsdet_getName(match, &err);
    
    result = String::stringWithUTF8Characters(cName);
    ucsdet_close(detector);
    
    return result;
#else
  String * result = NULL;
  uchardet_t ud = uchardet_new();
  int r = uchardet_handle_data(ud, bytes(), length());
  if (r == 0) {
    uchardet_data_end(ud);
    const char * charset = uchardet_get_charset(ud);
    if (charset[0] != 0) {
      result = String::stringWithUTF8Characters(charset);
    }
  }
  uchardet_delete(ud);
  
  return result;
#endif
}

String * Data::charsetWithFilteredHTML(bool filterHTML, String * hintCharset)
{
    if (hintCharset == NULL)
        return charsetWithFilteredHTMLWithoutHint(filterHTML);
    
#if !USE_UCHARDET
    const UCharsetMatch ** matches;
    int32_t matchesCount;
    UCharsetDetector * detector;
    UErrorCode err = U_ZERO_ERROR;
    String * result;
    
    hintCharset = hintCharset->lowercaseString();
    
    detector = ucsdet_open(&err);
    ucsdet_setText(detector, bytes(), length(), &err);
    ucsdet_enableInputFilter(detector, filterHTML);
    matches = ucsdet_detectAll(detector,  &matchesCount, &err);
    if (matches == NULL) {
        ucsdet_close(detector);
        return hintCharset;
    }
    if (matchesCount == 0) {
        ucsdet_close(detector);
        return hintCharset;
    }
    
    result = NULL;
    
    for(int32_t i = 0 ; i < matchesCount ; i ++) {
        const char * cName;
        String * name;
        int32_t confidence;
        
        cName = ucsdet_getName(matches[i], &err);
        name = String::stringWithUTF8Characters(cName);
        name = name->lowercaseString();
        confidence = ucsdet_getConfidence(matches[i], &err);
        if ((confidence >= 50) && name->isEqual(hintCharset)) {
            result = name;
            break;
        }
    }
    
    if (result == NULL) {
        int32_t maxConfidence;
        
        maxConfidence = 49;
        
        for(int32_t i = 0 ; i < matchesCount ; i ++) {
            const char * cName;
            String * name;
            int32_t confidence;
            
            cName = ucsdet_getName(matches[i], &err);
            confidence = ucsdet_getConfidence(matches[i], &err);
            name = String::stringWithUTF8Characters(cName);
            if (confidence > maxConfidence) {
                result = name;
                maxConfidence = confidence;
            }
        }
    }
    ucsdet_close(detector);
    
    if (result == NULL)
        result = hintCharset;
    
    return result;
#else
    if (hintCharset->caseInsensitiveCompare(MCSTR("utf-8")) == 0) {
        // Checks if the string converts well.
        String * value = stringWithCharset("utf-8");
        if (value != NULL) {
            return hintCharset;
        }
    }

    String * result = charsetWithFilteredHTMLWithoutHint(filterHTML);
    if (result == NULL) {
        result = hintCharset;
    }
    
    if (result->lowercaseString()->isEqual(MCSTR("x-mac-cyrillic")) &&
        hintCharset->lowercaseString()->isEqual(MCSTR("windows-1251"))) {
        result = MCSTR("windows-1251");
    }

    return result;
#endif
}

void Data::takeBytesOwnership(char * bytes, unsigned int length, BytesDeallocator bytesDeallocator)
{
    reset();
    mBytes = bytes;
    mLength = length;
    mAllocated = length;
    mExternallyAllocatedMemory = true;
    mBytesDeallocator = bytesDeallocator;
}

static void mmapDeallocator(char * bytes, unsigned int length) {
    if (bytes) {
        munmap(bytes, length);
    }
}

Data * Data::dataWithContentsOfFile(String * filename)
{
    int r;
    struct stat stat_buf;
    FILE * f;
    Data * data;
    
    f = fopen(filename->fileSystemRepresentation(), "rb");
    if (f == NULL) {
        return NULL;
    }

    r = fstat(fileno(f), &stat_buf);
    if (r < 0) {
        fclose(f);
        return NULL;
    }

    unsigned int length = (unsigned int)stat_buf.st_size;
    void * bytes = mmap(NULL, length, PROT_READ, MAP_PRIVATE, fileno(f), 0);
    fclose(f);

    if (bytes == MAP_FAILED) {
        return NULL;
    }
    
    data = Data::data();
    data->takeBytesOwnership((char *)bytes, length, mmapDeallocator);
    return data;
}

Data * Data::decodedDataUsingEncoding(Encoding encoding)
{
    Data * unused = NULL;
    return MCDecodeData(this, encoding, false, &unused);
}

Data * Data::data()
{
    return dataWithCapacity(0);
}

Data * Data::dataWithCapacity(int capacity)
{
    Data * result = new Data(capacity);
    return (Data *) result->autorelease();
}

String * Data::base64String()
{
    char * encoded = MCEncodeBase64(bytes(), length());
    String * result = String::stringWithUTF8Characters(encoded);
    free(encoded);
    return result;
}

HashMap * Data::serializable()
{
    HashMap * result = Object::serializable();
    result->setObjectForKey(MCSTR("data"), base64String());
    return result;
}

void Data::importSerializable(HashMap * serializable)
{
    setData(((String *) (serializable->objectForKey(MCSTR("data"))))->decodedBase64Data());
}

ErrorCode Data::writeToFile(String * filename)
{
    FILE * f = fopen(filename->fileSystemRepresentation(), "wb");

    if (f == NULL) {
        return ErrorFile;
    }
    size_t result = fwrite(bytes(), length(), 1, f);
    if (fclose(f) != 0) {
        return ErrorFile;
    }
    if (result == 0) {
        return ErrorFile;
    }
    return ErrorNone;
}

#if __APPLE__
static CFStringEncoding encodingFromCString(const char * charset)
{
    CFStringEncoding encoding;
    CFStringRef charsetString;
    CFDataRef charsetData;
    
    charsetData = CFDataCreate(NULL, (const UInt8 *) charset, strlen(charset));
    charsetString = CFStringCreateFromExternalRepresentation(NULL, charsetData, kCFStringEncodingUTF8);
    encoding = CFStringConvertIANACharSetNameToEncoding(charsetString);
    CFRelease(charsetString);
    CFRelease(charsetData);
    
    return encoding;
}

static size_t lepIConvInternal(iconv_t cd,
                               const char **inbuf, size_t *inbytesleft,
                               char **outbuf, size_t *outbytesleft,
                               char **inrepls, const char *outrepl)
{
    size_t ret = 0, ret1;
    char *ib = (char *) *inbuf;
    size_t ibl = *inbytesleft;
    char *ob = *outbuf;
    size_t obl = *outbytesleft;

    for (;;)
    {
        ret1 = iconv (cd, &ib, &ibl, &ob, &obl);
        if (ret1 != (size_t)-1)
            ret += ret1;
        if (ibl && obl && errno == EILSEQ)
        {
            if (inrepls)
            {
                /* Try replacing the input */
                char **t;
                for (t = inrepls; *t; t++)
                {
                    char *ib1 = *t;
                    size_t ibl1 = strlen (*t);
                    char *ob1 = ob;
                    size_t obl1 = obl;
                    iconv (cd, &ib1, &ibl1, &ob1, &obl1);
                    if (!ibl1)
                    {
                        ++ib, --ibl;
                        ob = ob1, obl = obl1;
                        ++ret;
                        break;
                    }
                }
                if (*t)
                    continue;
            }
            if (outrepl)
            {
                /* Try replacing the output */
                size_t n = strlen (outrepl);
                if (n <= obl)
                {
                    memcpy (ob, outrepl, n);
                    ++ib, --ibl;
                    ob += n, obl -= n;
                    ++ret;
                    continue;
                }
            }
        }
        *inbuf = ib, *inbytesleft = ibl;
        *outbuf = ob, *outbytesleft = obl;
        return ret;
    }
}

static int lepIConv(const char * tocode, const char * fromcode,
                    const char * str, size_t length,
                    char * result, size_t * result_len)

{
    size_t out_size;
    size_t old_out_size;
    iconv_t conv;
    char * p_result;
    int res;
    size_t r;

    conv = iconv_open(tocode, fromcode);
    if (conv == (iconv_t) -1) {
        res = MAIL_CHARCONV_ERROR_UNKNOWN_CHARSET;
        goto err;
    }

    out_size = * result_len;
    old_out_size = out_size;
    p_result = result;

    r = lepIConvInternal(conv, &str, &length,
                         &p_result, &out_size, NULL, "?");
    if (r == (size_t) -1) {
        res = MAIL_CHARCONV_ERROR_CONV;
        goto close_iconv;
    }
    
    iconv_close(conv);
    
    * result_len = old_out_size - out_size;
    * p_result = '\0';

    return MAIL_CHARCONV_NO_ERROR;
    
close_iconv:
    iconv_close(conv);
err:
    return res;
}

static int lepCFConv(const char * tocode, const char * fromcode,
                     const char * str, size_t length,
                     char * result, size_t * result_len)
{
    CFDataRef data;
    CFStringRef resultString;
    CFStringEncoding fromEncoding;
    CFStringEncoding toEncoding;
    CFDataRef resultData;

    fromEncoding = encodingFromCString(fromcode);
    toEncoding = encodingFromCString(tocode);
    if (fromEncoding == kCFStringEncodingInvalidId)
        return MAIL_CHARCONV_ERROR_UNKNOWN_CHARSET;
    if (toEncoding == kCFStringEncodingInvalidId)
        return MAIL_CHARCONV_ERROR_UNKNOWN_CHARSET;

    data = CFDataCreate(NULL, (const UInt8 *) str, length);
    resultString = CFStringCreateFromExternalRepresentation(NULL, data, fromEncoding);
    if (resultString == NULL) {
        CFRelease(data);
        return MAIL_CHARCONV_ERROR_CONV;
    }

    resultData = CFStringCreateExternalRepresentation(NULL, resultString, toEncoding, (UInt8) '?');

    unsigned int len;
    len = (unsigned int) CFDataGetLength(resultData);
    if (len > * result_len) {
        len = (unsigned int) * result_len;
    }
    CFDataGetBytes(resultData, CFRangeMake(0, len), (UInt8 *) result);
    * result_len = len;
    result[len] = 0;
    
    CFRelease(resultData);
    CFRelease(resultString);
    CFRelease(data);
    
    return MAIL_CHARCONV_NO_ERROR;
}

static int lepMixedConv(const char * tocode, const char * fromcode,
                        const char * str, size_t length,
                        char * result, size_t * result_len)
{
    int r;
    
    if (strcasecmp(fromcode, "iso-2022-jp-2") == 0) {
        r = lepCFConv(tocode, fromcode, str, length,
                      result, result_len);
        if (r == MAIL_CHARCONV_NO_ERROR)
            return r;
    }
    
    r = lepIConv(tocode, fromcode, str, length,
                 result, result_len);
    if (r == MAIL_CHARCONV_NO_ERROR)
        return r;
    
    return r;
}
#endif

#if defined(__ANDROID__) || defined(ANDROID)

static int lepMixedConv(const char * tocode, const char * fromcode,
                        const char * str, size_t length,
                        char * result, size_t * result_len)
{
    Data * data = Data::dataWithBytes(str, length);
    String * ustr = data->stringWithCharset(fromcode);
    if (ustr == NULL) {
        return MAIL_CHARCONV_ERROR_CONV;
    }
    data = ustr->dataUsingEncoding(tocode);
    if (data == NULL) {
        return MAIL_CHARCONV_ERROR_CONV;
    }
    size_t len = data->length();
    if (len > * result_len) {
        len = * result_len;
    }
    memcpy(result, data->bytes(), len);
    result[len] = 0;
    * result_len = len;

    return MAIL_CHARCONV_NO_ERROR;
}

#endif

static void * createObject()
{
    return new Data();
}

INITIALIZE(Data)
{
    Object::registerObjectConstructor("mailcore::Data", &createObject);
#if __APPLE__ || defined(__ANDROID__) || defined(ANDROID)
    extended_charconv = lepMixedConv;
#endif
}
