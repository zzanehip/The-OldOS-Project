//
//  NSArray+MCO.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_NSARRAY_MCO_H

#define MAILCORE_NSARRAY_MCO_H

#import <Foundation/Foundation.h>

#ifdef __cplusplus
namespace mailcore {
    class Array;
}
#endif

@interface NSArray (MCO)

#ifdef __cplusplus
+ (NSArray *) mco_arrayWithMCArray:(mailcore::Array *)array;

- (mailcore::Array *) mco_mcArray;
#endif

@end

#endif
