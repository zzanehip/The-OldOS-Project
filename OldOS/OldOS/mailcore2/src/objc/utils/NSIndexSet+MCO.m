//
//  NSIndexSet+MCO.m
//  mailcore2
//
//  Created by Hoa V. DINH on 9/10/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "NSIndexSet+MCO.h"
#import "MCOIndexSet.h"

@implementation NSIndexSet (MCO)

- (MCOIndexSet *) mcoIndexSet
{
    MCOIndexSet * result = [MCOIndexSet indexSet];;
    
    [self enumerateRangesUsingBlock:^(NSRange range, BOOL * stop) {
        [result addRange:MCORangeMake(range.location, range.length - 1)];
    }];
    
    return result;
}

@end
