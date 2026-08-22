//
//  NSSet+MCO.h
//  mailcore2
//
//  Created by Hoa V. DINH on 1/29/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
namespace mailcore {
    class Set;
}
#endif

@interface NSSet (MCO)

#ifdef __cplusplus
+ (NSSet *) mco_setWithMCSet:(mailcore::Set *)cppSet;

- (mailcore::Set *) mco_mcSet;
#endif

@end
