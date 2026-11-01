//
//  NSIndexSet+MCO.h
//  mailcore2
//
//  Created by Hoa V. DINH on 9/10/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCOIndexSet;

@interface NSIndexSet (MCO)

/** Returns a MCOIndexSet from an NSIndexSet */
- (MCOIndexSet *) mcoIndexSet;

@end
