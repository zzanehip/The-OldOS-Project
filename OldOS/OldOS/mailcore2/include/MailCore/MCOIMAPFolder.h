//
//  MCOIMAPFolder.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPFOLDER_H

#define MAILCORE_MCOIMAPFOLDER_H

/** This class represents an IMAP folder */

#import <Foundation/Foundation.h>
#import <MailCore/MCOConstants.h>

@interface MCOIMAPFolder : NSObject <NSCopying>

/** The folder's path, like for example INBOX.Archive */
@property (nonatomic, copy) NSString * path;

/** It's the delimiter for each component of the path. Commonly . or / */
@property (nonatomic, assign) char delimiter;

/** 
 Any flags the folder may have, like if the folder is for Drafts, Spam, Junk, etc. Or
 it could be marked with metadata like that it has no children.
*/
@property (nonatomic, assign) MCOIMAPFolderFlag flags;

@end

#endif
