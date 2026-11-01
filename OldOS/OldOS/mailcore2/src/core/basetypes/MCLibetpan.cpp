//
//  MCLibetpan.cpp
//  mailcore2
//
//  Created by Hoa Dinh on 6/28/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCWin32.h" // should be included first.

#include "MCLibetpan.h"

#include <libetpan/libetpan.h>

#include "MCDefines.h"

using namespace mailcore;

static int tmcomp(struct tm * atmp, struct tm * btmp);

INITIALIZE(Libetpan)
{
    // It will enable CFStream on platforms that supports it.
    mailstream_cfstream_enabled = 1;
}

time_t mailcore::timestampFromDate(struct mailimf_date_time * date_time)
{
    struct tm tmval;
    time_t timeval;
    int zone_min;
    int zone_hour;
    
    tmval.tm_sec  = date_time->dt_sec;
    tmval.tm_min  = date_time->dt_min;
    tmval.tm_hour = date_time->dt_hour;
    tmval.tm_mday = date_time->dt_day;
    tmval.tm_mon  = date_time->dt_month - 1;
    if (date_time->dt_year < 1000) {
        // workaround when century is not given in year
        tmval.tm_year = date_time->dt_year + 2000 - 1900;
    }
    else {
        tmval.tm_year = date_time->dt_year - 1900;
    }
    
    timeval = mkgmtime(&tmval);
    
    if (date_time->dt_zone >= 0) {
        zone_hour = date_time->dt_zone / 100;
        zone_min = date_time->dt_zone % 100;
    }
    else {
        zone_hour = -((- date_time->dt_zone) / 100);
        zone_min = -((- date_time->dt_zone) % 100);
    }
    timeval -= zone_hour * 3600 + zone_min * 60;
    
    return timeval;
}

struct mailimf_date_time * mailcore::dateFromTimestamp(time_t timeval)
{
    struct tm gmt;
    struct tm lt;
    int off;
    struct mailimf_date_time * date_time;
    int sign;
    int hour;
    int min;
    
    gmtime_r(&timeval, &gmt);
    localtime_r(&timeval, &lt);
    
    off = (int) ((mkgmtime(&lt) - mkgmtime(&gmt)) / 60);
    if (off < 0) {
        sign = -1;
    }
    else {
        sign = 1;
    }
    off = off * sign;
    min = off % 60;
    hour = off / 60;
    off = hour * 100 + min;
    off = off * sign;
    
    date_time = mailimf_date_time_new(lt.tm_mday, lt.tm_mon + 1,
                                      lt.tm_year + 1900,
                                      lt.tm_hour, lt.tm_min, lt.tm_sec,
                                      off);
    
    return date_time;
}

struct mailimap_date_time * mailcore::imapDateFromTimestamp(time_t timeval)
{
    struct tm gmt;
    struct tm lt;
    int off;
    struct mailimap_date_time * date_time;
    int sign;
    int hour;
    int min;
    
    gmtime_r(&timeval, &gmt);
    localtime_r(&timeval, &lt);
    
    off = (int) ((mkgmtime(&lt) - mkgmtime(&gmt)) / 60);
    if (off < 0) {
        sign = -1;
    }
    else {
        sign = 1;
    }
    off = off * sign;
    min = off % 60;
    hour = off / 60;
    off = hour * 100 + min;
    off = off * sign;
    
    date_time = mailimap_date_time_new(lt.tm_mday, lt.tm_mon + 1,
                                       lt.tm_year + 1900,
                                       lt.tm_hour, lt.tm_min, lt.tm_sec,
                                       off);
    
    return date_time;
}

time_t mailcore::timestampFromIMAPDate(struct mailimap_date_time * date_time)
{
    struct tm tmval;
    time_t timeval;
    int zone_min;
    int zone_hour;
    
    tmval.tm_sec  = date_time->dt_sec;
    tmval.tm_min  = date_time->dt_min;
    tmval.tm_hour = date_time->dt_hour;
    tmval.tm_mday = date_time->dt_day;
    tmval.tm_mon  = date_time->dt_month - 1;
    if (date_time->dt_year < 1000) {
        // workaround when century is not given in year
        tmval.tm_year = date_time->dt_year + 2000 - 1900;
    }
    else {
        tmval.tm_year = date_time->dt_year - 1900;
    }
    
    timeval = mkgmtime(&tmval);
    
    if (date_time->dt_zone >= 0) {
        zone_hour = date_time->dt_zone / 100;
        zone_min = date_time->dt_zone % 100;
    }
    else {
        zone_hour = -((- date_time->dt_zone) / 100);
        zone_min = -((- date_time->dt_zone) % 100);
    }
    timeval -= zone_hour * 3600 + zone_min * 60;
    
    return timeval;
}

#define INVALID_TIMESTAMP    (-1)

static int tmcomp(struct tm * atmp, struct tm * btmp)
{
    int    result;
    
    if ((result = (atmp->tm_year - btmp->tm_year)) == 0 &&
        (result = (atmp->tm_mon - btmp->tm_mon)) == 0 &&
        (result = (atmp->tm_mday - btmp->tm_mday)) == 0 &&
        (result = (atmp->tm_hour - btmp->tm_hour)) == 0 &&
        (result = (atmp->tm_min - btmp->tm_min)) == 0)
        result = atmp->tm_sec - btmp->tm_sec;
    return result;
}

time_t mailcore::mkgmtime(struct tm * tmp)
{
    int            dir;
    int            bits;
    int            saved_seconds;
    time_t                t;
    struct tm            yourtm, mytm;
    
    yourtm = *tmp;
    saved_seconds = yourtm.tm_sec;
    yourtm.tm_sec = 0;
    /*
     ** Calculate the number of magnitude bits in a time_t
     ** (this works regardless of whether time_t is
     ** signed or unsigned, though lint complains if unsigned).
     */
    for (bits = 0, t = 1; t > 0; ++bits, t <<= 1)
        ;
    /*
     ** If time_t is signed, then 0 is the median value,
     ** if time_t is unsigned, then 1 << bits is median.
     */
    if(bits > 40) bits = 40;
    t = (t < 0) ? 0 : ((time_t) 1 << bits);
    for ( ; ; ) {
        gmtime_r(&t, &mytm);
        dir = tmcomp(&mytm, &yourtm);
        if (dir != 0) {
            if (bits-- < 0) {
                return INVALID_TIMESTAMP;
            }
            if (bits < 0)
                --t;
            else if (dir > 0)
                t -= (time_t) 1 << bits;
            else    t += (time_t) 1 << bits;
            continue;
        }
        break;
    }
    t += saved_seconds;
    return t;
}
