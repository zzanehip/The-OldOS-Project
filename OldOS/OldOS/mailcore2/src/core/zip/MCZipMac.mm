//
//  MCZipMac.mm
//  mailcore2
//
//  Created by juliangsp on 7/7/15.
//  Copyright (c) 2015 MailCore. All rights reserved.
//

#include "MCZipPrivate.h"

#import "NSObject+MCO.h"
#import <Foundation/Foundation.h>

using namespace mailcore;

String * mailcore::TemporaryDirectoryForZip()
{
    NSError * error;
    NSString * directoryString;
    
    error = nil;
    directoryString = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
    directoryString = [directoryString stringByAppendingString:[[NSUUID UUID] UUIDString]];
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:directoryString withIntermediateDirectories:YES attributes:nil error:NULL]) {
        return nil;
    }
    
    return MCO_FROM_OBJC(String, directoryString);
}
