//
//  MCLibetpanTypes.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 4/7/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCLIBETPANTYPES_H

#define MAILCORE_MCLIBETPANTYPES_H

#ifdef __cplusplus
extern "C" {
#endif
    struct mailimap_body_fields;
    struct mailimap_body_ext_1part;
    struct mailimf_address;
    struct mailimf_mailbox;
    struct mailimap_address;
    struct mailmime;
    struct mailmime_mechanism;
    struct mailimap_namespace_item;
    struct mailimap_namespace_info;
    struct mailimap_body;
    struct mailimap_body_fields;
    struct mailimap_body_ext_1part;
    struct mailimap_body_type_1part;
    struct mailimap_body_type_basic;
    struct mailimap_body_type_text;
    struct mailimap_body_type_mpart;
    struct mailimap_body_type_msg;
    typedef struct mailimap mailimap;
    struct mailimap_set;
    struct mailimap_date_time;
    struct mailimf_fields;
    struct mailimap_envelope;
    typedef struct mailpop3 mailpop3;
    typedef struct mailsmtp mailsmtp;
    typedef struct newsnntp newsnntp;
    struct mailsem;
#ifdef __cplusplus
}
#endif

#endif
