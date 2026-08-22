//
//  MCOIMAPFolderStatus.h
//  mailcore2
//
//  Created by Sebastian on 6/5/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPFOLDERSTATUS_H

#define MAILCORE_MCOIMAPFOLDERSTATUS_H

#import <Foundation/Foundation.h>

/* This class holds IMAP folder metadata */

@interface MCOIMAPFolderStatus : NSObject <NSCopying>

/** The folder's IMAP UIDNEXT value. Used to determine the uid for the next received message. */
@property (nonatomic, assign) uint32_t uidNext;

/** The folders IMAP UIDVALIDITY value. Must be used to determine if the server has changed assigned UIDs */
@property (nonatomic, assign) uint32_t uidValidity;

/** Number of recent messages received in the folder */
@property (nonatomic, assign) uint32_t recentCount;

/** Number of unseen messages in the folder */
@property (nonatomic, assign) uint32_t unseenCount;

/** Number of messages in the folder */
@property (nonatomic, assign) uint32_t messageCount;

/** Highest modification sequence value for this folder. See CONDSTORE RFC 4551. */
@property (nonatomic, assign) uint64_t highestModSeqValue;

@end

#endif
