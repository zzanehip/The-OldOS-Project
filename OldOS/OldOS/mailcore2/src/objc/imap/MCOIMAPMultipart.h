//
//  MCOIMAPMultipart.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPMULTIPART_H

#define MAILCORE_MCOIMAPMULTIPART_H

/** Represents the a multipart retrieved from IMAP */

#import <MailCore/MCOAbstractMultipart.h>

@interface MCOIMAPMultipart : MCOAbstractMultipart <NSCoding>

/** A part identifier looks like 1.2.1 */
@property (nonatomic, copy) NSString * partID;

@end

#endif
