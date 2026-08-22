//
//  MCOIMAPBaseOperation.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/26/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPBASEOPERATION_H

#define MAILCORE_MCOIMAPBASEOPERATION_H

/** Represents a generic IMAP operation with methods that are called with progress updates */

#import <MailCore/MCOOperation.h>

typedef void (^MCOIMAPBaseOperationProgressBlock)(unsigned int current, unsigned int maximum);
typedef void (^MCOIMAPBaseOperationItemProgressBlock)(unsigned int current);

@interface MCOIMAPBaseOperation : MCOOperation

@property (nonatomic, assign, getter=isUrgent) BOOL urgent;

/* Can be overriden by subclasses */

/* 
 Will be called when a sending or receiving the contents of a message 
 @param current The number of bytes sent or received
 @param maximum The total number of bytes expected
*/
- (void)bodyProgress:(unsigned int)current maximum:(unsigned int)maximum;

/*
 Will be called when a new item is received in a list of items, like for example a message list
 @param current The number of items downloaded
 @param maximum The total number of items expected
*/
- (void)itemProgress:(unsigned int)current maximum:(unsigned int)maximum;

@end

#endif
