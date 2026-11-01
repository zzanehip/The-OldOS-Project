//
//  MCBase64.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 7/30/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCBASE64_H

#define MAILCORE_MCBASE64_H

#ifdef __cplusplus
extern "C" {
#endif

extern char * MCDecodeBase64(const char * in, int len, int * p_outlen);
extern char * MCEncodeBase64(const char * in, int len);

#ifdef __cplusplus
}
#endif

#endif
