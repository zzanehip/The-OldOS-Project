//
//  MCFetchAsyncMXRecord.cpp
//  mailcore2
//
//  Created by Christopher Hockley on 29/01/15.
//  Copyright (c) 2015 MailCore. All rights reserved.
//

#include "MCMXRecordResolverOperation.h"

#if !defined(ANDROID) && !defined(__ANDROID__)
#include <arpa/inet.h>
#include <resolv.h>
#endif

using namespace mailcore;

MXRecordResolverOperation::MXRecordResolverOperation()
{
    mHostname = NULL;
    mMXRecords = NULL;
}

MXRecordResolverOperation::~MXRecordResolverOperation()
{
    MC_SAFE_RELEASE(mMXRecords);
    MC_SAFE_RELEASE(mHostname);
}

void MXRecordResolverOperation::setHostname(String * hostname)
{
    MC_SAFE_REPLACE_COPY(String, mHostname, hostname);
}

String * MXRecordResolverOperation::hostname()
{
    return mHostname;
}

Array * MXRecordResolverOperation::mxRecords()
{
    return mMXRecords;
}

void MXRecordResolverOperation::main()
{
    mMXRecords = new Array();
#if !defined(ANDROID) && !defined(__ANDROID__)
    unsigned char response[NS_PACKETSZ];
    ns_msg handle;
    ns_rr rr;
    int len;
    char dispbuf[4096];
    
    if (((len = res_search(MCUTF8(mHostname), ns_c_in, ns_t_mx, response, sizeof(response))) >= 0) and
        (ns_initparse(response, len, &handle) >= 0) and
        (ns_msg_count(handle, ns_s_an) >= 0)) {
    
        for (int ns_index = 0; ns_index < len; ns_index++) {
            if (ns_parserr(&handle, ns_s_an, ns_index, &rr)) {
                /* WARN: ns_parserr failed */
                continue;
            }
            ns_sprintrr (&handle, &rr, NULL, NULL, dispbuf, sizeof (dispbuf));
            if (ns_rr_class(rr) == ns_c_in and ns_rr_type(rr) == ns_t_mx) {
                char mxname[4096];
                dn_expand(ns_msg_base(handle), ns_msg_base(handle) + ns_msg_size(handle), ns_rr_rdata(rr) + NS_INT16SZ, mxname, sizeof(mxname));
                String * str = String::stringWithUTF8Characters(mxname);
                mMXRecords->addObject(str);
            }
        }
    }
#endif
}

