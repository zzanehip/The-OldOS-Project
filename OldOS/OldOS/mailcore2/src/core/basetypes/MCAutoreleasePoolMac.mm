//
//  MCAutoreleasePoolMac.mm
//  mailcore2
//
//  Created by DINH Viêt Hoà on 5/4/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCAutoreleasePool.h"

#import <Foundation/Foundation.h>

using namespace mailcore;

void * AutoreleasePool::createAppleAutoreleasePool()
{
    return [[NSAutoreleasePool alloc] init];
}

void AutoreleasePool::releaseAppleAutoreleasePool(void * appleAutoreleasePool)
{
    [(NSAutoreleasePool *) appleAutoreleasePool release];
}

