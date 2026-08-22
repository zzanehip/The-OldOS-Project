//
//  main.m
//  tests
//
//  Created by DINH Viêt Hoà on 1/10/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "test-all.h"
#if __APPLE__
#include "test-all-mac.h"
#endif

int main(int argc, const char * argv[])
{
    testAll();
#if __APPLE__
    testAllMac();
#endif
    return 0;
}

