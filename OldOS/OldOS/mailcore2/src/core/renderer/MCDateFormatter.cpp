//
//  MCDateFormatter.cpp
//  testUI
//
//  Created by DINH Viêt Hoà on 1/28/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCDateFormatter.h"
#include <stdlib.h>

#if defined(__APPLE__)
#define USE_COREFOUNDATION 1
#else
#include <unicode/udat.h>
#endif

#if USE_COREFOUNDATION
#include <CoreFoundation/CoreFoundation.h>
#endif

using namespace mailcore;

DateFormatter::DateFormatter()
{
    mDateFormatter = NULL;
    mDateStyle = DateFormatStyleMedium;
    mTimeStyle = DateFormatStyleMedium;
    mDateFormat = NULL;
    mTimezone = NULL;
    mLocale = NULL;
    mAppleDateFormatter = NULL;
}

DateFormatter::~DateFormatter()
{
#if USE_COREFOUNDATION
    if (mAppleDateFormatter != NULL) {
        CFRelease(mAppleDateFormatter);
    }
#else
    if (mDateFormatter != NULL) {
        udat_close(mDateFormatter);
    }
#endif
    MC_SAFE_RELEASE(mDateFormat);
    MC_SAFE_RELEASE(mTimezone);
    MC_SAFE_RELEASE(mLocale);
}

DateFormatter * DateFormatter::dateFormatter()
{
    DateFormatter * result = new DateFormatter();
    result->autorelease();
    return result;
}


void DateFormatter::setDateStyle(DateFormatStyle style)
{
    mDateStyle = style;
}

DateFormatStyle DateFormatter::dateStyle()
{
    return mDateStyle;
}

void DateFormatter::setTimeStyle(DateFormatStyle style)
{
    mTimeStyle = style;
}

DateFormatStyle DateFormatter::timeStyle()
{
    return mTimeStyle;
}

void DateFormatter::setLocale(String * locale)
{
    MC_SAFE_REPLACE_COPY(String, mLocale, locale);
}

String * DateFormatter::locale()
{
    return mLocale;
}

void DateFormatter::setTimezone(String * timezone)
{
    MC_SAFE_REPLACE_COPY(String, mTimezone, timezone);
}

String * DateFormatter::timezone()
{
    return mTimezone;
}

void DateFormatter::setDateFormat(String * dateFormat)
{
    MC_SAFE_REPLACE_COPY(String, mDateFormat, dateFormat);
}

String * DateFormatter::dateFormat()
{
    return mDateFormat;
}

String * DateFormatter::stringFromDate(time_t date)
{
    prepare();
#if USE_COREFOUNDATION
    if (mAppleDateFormatter == NULL)
        return NULL;
    
    CFDateRef dateRef = CFDateCreate(NULL, (CFAbsoluteTime) date - kCFAbsoluteTimeIntervalSince1970);
    CFStringRef string = CFDateFormatterCreateStringWithDate(NULL, (CFDateFormatterRef) mAppleDateFormatter, dateRef);
    CFIndex len = CFStringGetLength(string);
    UniChar * buffer = (UniChar *) malloc(sizeof(* buffer) * len);
    CFStringGetCharacters(string, CFRangeMake(0, len), buffer);
    String * result = String::stringWithCharacters(buffer, (unsigned int) len);
    free(buffer);
    CFRelease(string);
    CFRelease(dateRef);
    return result;
#else
    if (mDateFormatter == NULL)
        return NULL;
    
    UErrorCode err = U_ZERO_ERROR;
    int32_t len = udat_format(mDateFormatter, ((double) date) * 1000., NULL, 0, NULL, &err);
    if(err != U_BUFFER_OVERFLOW_ERROR) {
        return NULL;
    }
    
    String * result;
    
    err = U_ZERO_ERROR;
    UChar * unichars = (UChar *) malloc((len + 1) * sizeof(unichars));
    udat_format(mDateFormatter, ((double) date) * 1000., unichars, len + 1, NULL, &err);
    result = new String(unichars, len);
    free(unichars);
    
    result->autorelease();
    return result;
#endif
}

time_t DateFormatter::dateFromString(String * dateString)
{
    prepare();
#if USE_COREFOUNDATION
    if (mAppleDateFormatter == NULL)
        return (time_t) -1;
    
    CFAbsoluteTime absoluteTime;
    bool r;
    time_t result;
    CFStringRef dateCFString = CFStringCreateWithCharacters(NULL, (const UniChar *) dateString->unicodeCharacters(),
                                                            dateString->length());
    r = CFDateFormatterGetAbsoluteTimeFromString((CFDateFormatterRef) mAppleDateFormatter, dateCFString,
                                                 NULL, &absoluteTime);
    result = (time_t) -1;
    if (r) {
        result = (time_t) absoluteTime + kCFAbsoluteTimeIntervalSince1970;
    }
    CFRelease(dateCFString);
    
    return result;
#else
    if (mDateFormatter == NULL)
        return (time_t) -1;
    
    UErrorCode err = U_ZERO_ERROR;
    UDate date = udat_parse(mDateFormatter, dateString->unicodeCharacters(), dateString->length(),
                            NULL, &err);
    if (err != U_ZERO_ERROR) {
        return (time_t) -1;
    }
    
    return date / 1000.;
#endif
}

#if USE_COREFOUNDATION
static CFDateFormatterStyle toAppleStyle(DateFormatStyle style)
{
    switch (style) {
        case DateFormatStyleFull:
            return kCFDateFormatterFullStyle;
        case DateFormatStyleLong:
            return kCFDateFormatterLongStyle;
        case DateFormatStyleMedium:
            return kCFDateFormatterMediumStyle;
        case DateFormatStyleShort:
            return kCFDateFormatterShortStyle;
        case DateFormatStyleNone:
            return kCFDateFormatterNoStyle;
    }
    return kCFDateFormatterMediumStyle;
}
#endif

void DateFormatter::prepare()
{
#if USE_COREFOUNDATION
    if (mAppleDateFormatter != NULL)
        return;
    
    CFStringRef localeIdentifier = NULL;
    CFLocaleRef localeRef = NULL;
    if (mLocale != NULL) {
        localeIdentifier = CFStringCreateWithCharacters(NULL, (const UniChar *) mLocale->unicodeCharacters(),
                                                        mLocale->length());
        localeRef = CFLocaleCreate(NULL, localeIdentifier);
    }
    if (localeRef == NULL) {
        localeRef = CFLocaleCopyCurrent();
    }
    mAppleDateFormatter = CFDateFormatterCreate(NULL, localeRef, toAppleStyle(mDateStyle), toAppleStyle(mTimeStyle));
    if (mDateFormat != NULL) {
        CFStringRef dateFormatCFString = CFStringCreateWithCharacters(NULL, (const UniChar *) mDateFormat->unicodeCharacters(),
                                                                      mDateFormat->length());
        CFDateFormatterSetFormat((CFDateFormatterRef) mAppleDateFormatter, dateFormatCFString);
        CFRelease(dateFormatCFString);
    }
    if (localeIdentifier != NULL) {
        CFRelease(localeIdentifier);
    }
    if (localeRef != NULL) {
        CFRelease(localeRef);
    }
#else
    if (mDateFormatter != NULL)
        return;
    
    const UChar * tzID = NULL;
    int32_t tzIDLength = -1;
    const UChar * pattern = NULL;
    int32_t patternLength = -1;
    UErrorCode err = U_ZERO_ERROR;
    const char * locale = NULL;
    
    if (mTimezone != NULL) {
        tzID = mTimezone->unicodeCharacters();
        tzIDLength = mTimezone->length();
    }
    if (mDateFormat != NULL) {
        pattern = mDateFormat->unicodeCharacters();
        patternLength = mDateFormat->length();
    }
    if (mLocale != NULL) {
        locale = mLocale->UTF8Characters();
    }
    
    mDateFormatter = udat_open((UDateFormatStyle) mTimeStyle, (UDateFormatStyle) mDateStyle,
                               locale,
                               tzID, tzIDLength,
                               pattern, patternLength,
                               &err);
#endif
}
