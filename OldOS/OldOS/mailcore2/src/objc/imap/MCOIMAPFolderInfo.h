//
//  MCOIMAPFolderInfo.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPFOLDERINFO_H

#define MAILCORE_MCOIMAPFOLDERINFO_H

#import <Foundation/Foundation.h>

/* This class holds IMAP folder metadata */

@interface MCOIMAPFolderInfo : NSObject <NSCopying>

/** The folder's IMAP UIDNEXT value. Used to determine the uid for the next received message. */
@property (nonatomic, assign) uint32_t uidNext;

/** The folders IMAP UIDVALIDITY value. Must be used to determine if the server has changed assigned UIDs */
@property (nonatomic, assign) uint32_t uidValidity;

/** An advanced value used for doing quick flag syncs if the server supports it. The MODSEQ value. */
@property (nonatomic, assign) uint64_t modSequenceValue;

/** Total number of messages in the folder */
@property (nonatomic, assign) int messageCount;

// first uid of the unseen messages.
@property (nonatomic, assign) uint32_t firstUnseenUid;

/** An boolean indicates that this folder or IMAP server allows to add a new permanent flags */
@property (nonatomic, assign) BOOL allowsNewPermanentFlags;

@end

#endif
