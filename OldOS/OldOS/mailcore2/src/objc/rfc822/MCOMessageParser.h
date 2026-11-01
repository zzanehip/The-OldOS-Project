//
//  MCOMessageParser.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOMESSAGEPARSER_H

#define MAILCORE_MCOMESSAGEPARSER_H

/**
 This class implements a parsed message.
 When the full content of a message has been fetched using POP or IMAP,
 you need to parse it.
*/

#import <MailCore/MCOAbstractMessage.h>

@protocol MCOHTMLRendererDelegate;

@interface MCOMessageParser : MCOAbstractMessage

/** returns a parsed message from the given RFC 822 data.*/
+ (MCOMessageParser *) messageParserWithData:(NSData *)data;

/** data is the RFC 822 formatted message.*/
- (instancetype) initWithData:(NSData *)data;
- (void) dealloc;

/** It's the main part of the message. It can be MCOMessagePart, MCOMultipart or MCOAttachment.*/
- (MCOAbstractPart *) mainPart;

/** data of the RFC 822 formatted message. It's the input of the parser.*/
- (NSData *) data;

/** HTML rendering of the message to be displayed in a web view. delegate can be nil.*/
- (NSString *) htmlRenderingWithDelegate:(id <MCOHTMLRendererDelegate>)delegate;

/** HTML rendering of the body of the message to be displayed in a web view.*/
- (NSString *) htmlBodyRendering;

/** Text rendering of the message.*/
- (NSString *) plainTextRendering;

/** Text rendering of the body of the message. All end of line will be removed and white spaces cleaned up.
 This method can be used to generate the summary of the message.*/
- (NSString *) plainTextBodyRendering;

/** Text rendering of the body of the message. All end of line will be removed and white spaces cleaned up if requested.
 This method can be used to generate the summary of the message.*/
- (NSString *) plainTextBodyRenderingAndStripWhitespace:(BOOL)stripWhitespace;

@end

#endif
