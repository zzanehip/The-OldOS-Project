//
//  MCOOperation+Private.h
//  mailcore2
//
//  Created by Matt Ronge on 01/31/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOPERATION_PRIVATE_H

#define MAILCORE_MCOPERATION_PRIVATE_H

#ifdef __cplusplus
namespace mailcore {
    class Operation;
}
#endif

// Shhh, secret stuff in here

@interface MCOOperation (Private)
#ifdef __cplusplus
- (instancetype) initWithMCOperation:(mailcore::Operation *)op;
#endif
- (void) start;
@end

#endif
