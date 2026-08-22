//
//  MCDataMac.m
//  mailcore2
//
//  Created by Hoa V. DINH on 10/24/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCData.h"

#import <Foundation/Foundation.h>

using namespace mailcore;

CFDataRef Data::destructiveNSData()
{
    NSData * result;
    if (mExternallyAllocatedMemory) {
        BytesDeallocator deallocator = mBytesDeallocator;
        result = [[[NSData alloc] initWithBytesNoCopy:mBytes length:mLength deallocator:^(void * bytes, NSUInteger length) {
            if (deallocator) {
                deallocator((char *)bytes, (unsigned int)length);
            }
        }] autorelease];
    } else {
        result = [NSData dataWithBytesNoCopy:(void *) mBytes length:mLength];
    }
    init();
    return (CFDataRef) result;
}
