//
//  MCLibetpan.h
//  mailcore2
//
//  Created by Hoa Dinh on 6/28/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCLIBETPAN_H

#define MAILCORE_MCLIBETPAN_H

#include <time.h>
#include <libetpan/libetpan.h>

namespace mailcore {

    time_t timestampFromDate(struct mailimf_date_time * date_time);
    time_t timestampFromIMAPDate(struct mailimap_date_time * date_time);
    struct mailimf_date_time * dateFromTimestamp(time_t timeval);
    struct mailimap_date_time * imapDateFromTimestamp(time_t timeval);
    time_t mkgmtime(struct tm * tmp);
    
}

#endif
