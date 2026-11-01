//
//  MCOAttachment.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOATTACHMENT_H

#define MAILCORE_MCOATTACHMENT_H

#import <MailCore/MCOAbstractPart.h>

/** This is a single part.

    It can either parsed from RFC 822 message data or created to build a message.*/

@interface MCOAttachment : MCOAbstractPart

/** Returns a MIME type for a filename.*/
+ (NSString *) mimeTypeForFilename:(NSString *)filename;

/** Returns a file attachment with the content of the given file.*/
+ (MCOAttachment *) attachmentWithContentsOfFile:(NSString *)filename;

/** Returns a file attachment with the given data and filename.*/
+ (MCOAttachment *) attachmentWithData:(NSData *)data filename:(NSString *)filename;

/** Returns a part with an HTML content.*/
+ (MCOAttachment *) attachmentWithHTMLString:(NSString *)htmlString;

/** Returns a part with a RFC 822 messsage attachment.*/
+ (MCOAttachment *) attachmentWithRFC822Message:(NSData *)messageData;

/** Returns a part with an plain text content.*/
+ (MCOAttachment *) attachmentWithText:(NSString *)text;

/** Decoded data of the part.*/
@property (nonatomic, strong) NSData * data;

/** Returns string representation according to charset*/
- (NSString *) decodedString;

@end

#endif
