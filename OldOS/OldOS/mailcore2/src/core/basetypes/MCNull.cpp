//
//  MCNull.cpp
//  hermes
//
//  Created by DINH Viêt Hoà on 4/9/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCNull.h"

using namespace mailcore;

static Null * s_null = NULL;
static pthread_once_t s_once;

static void init_null(void)
{
    s_null = new Null();
}

Null * Null::null()
{
    pthread_once(&s_once, init_null);
    return s_null;
}
