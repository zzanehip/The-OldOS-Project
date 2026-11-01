//
//  MCDateFormatter.h
//  testUI
//
//  Created by DINH Viêt Hoà on 1/28/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCDATEFORMATTER_H

#define MAILCORE_MCDATEFORMATTER_H

#include <MailCore/MCBaseTypes.h>

// predeclare UDateFormat
// copied from <unicode/udat.h>
typedef void * UDateFormat;

#ifdef __cplusplus

namespace mailcore {
    
    class String;
    
    // Uses same values as UDateFormatStyle
    enum DateFormatStyle {
        DateFormatStyleFull = 0 /* UDAT_FULL*/,
        DateFormatStyleLong = 1 /* UDAT_LONG */,
        DateFormatStyleMedium = 2 /* UDAT_MEDIUM */,
        DateFormatStyleShort = 3 /* UDAT_SHORT */,
        DateFormatStyleNone = -1 /* UDAT_NONE */,
    };
    
    class MAILCORE_EXPORT DateFormatter : public Object {
    public:
        DateFormatter();
        virtual ~DateFormatter();
        
        static DateFormatter * dateFormatter();
        
        virtual void prepare();

        virtual void setDateStyle(DateFormatStyle style);
        virtual DateFormatStyle dateStyle();
        
        virtual void setTimeStyle(DateFormatStyle style);
        virtual DateFormatStyle timeStyle();
        
        virtual void setLocale(String * locale);
        virtual String * locale();
        
        virtual void setTimezone(String * timezone);
        virtual String * timezone();
        
        virtual void setDateFormat(String * dateFormat);
        virtual String * dateFormat();
        
        virtual String * stringFromDate(time_t date);
        virtual time_t dateFromString(String * dateString);

    private:
        UDateFormat * mDateFormatter;
        DateFormatStyle mDateStyle;
        DateFormatStyle mTimeStyle;
        String * mDateFormat;
        String * mTimezone;
        String * mLocale;
        void * mAppleDateFormatter;
    };
    
}

#endif

#endif /* defined(__testUI__MCDateFormatter__) */
