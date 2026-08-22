//
//  MCONNTPOperation_Private.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCONNTPOPERATION_PRIVATE_H
#define MAILCORE_MCONNTPOPERATION_PRIVATE_H

@class MCONNTPSession;

@interface MCONNTPOperation (Private)

@property (nonatomic, retain) MCONNTPSession * session;

@end

#endif
