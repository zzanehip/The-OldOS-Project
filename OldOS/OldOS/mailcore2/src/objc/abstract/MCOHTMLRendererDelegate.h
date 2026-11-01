//
//  MCOHTMLRendererDelegate.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOHTMLRENDERERDELEGATE_H

#define MAILCORE_MCOHTMLRENDERERDELEGATE_H

#import <Foundation/Foundation.h>

/** This delegate protocol is used to help rendering of the message.

 It will be used for the following methods.

 [MCOMessageParser htmlRenderingWithDelegate:],

 [MCOMessageBuilder htmlRenderingWithDelegate:]

 -[MCOIMAPMessage htmlRenderingWithFolder:delegate:]
*/

@class MCOAbstractPart;
@class MCOAbstractMessage;
@class MCOMessageHeader;
@class MCOAbstractMessagePart;

@protocol MCOHTMLRendererDelegate <NSObject>

/** All methods are optional.*/
@optional









- (BOOL) abstractMessage:(MCOAbstractMessage *)msg canPreviewPart:(MCOAbstractPart *)part;

/** This delegate method should return YES if the part should be rendered.*/
- (BOOL) abstractMessage:(MCOAbstractMessage *)msg shouldShowPart:(MCOAbstractPart *)part;

/** This delegate method returns the values to be applied to the template for the given header.
 See the content of MCHTMLRendererCallback.cpp for the default values of the header.*/
- (NSDictionary *) abstractMessage:(MCOAbstractMessage *)msg templateValuesForHeader:(MCOMessageHeader *)header;

/** This delegate method returns the values to be applied to the template for the given attachment.
 See the content of MCHTMLRendererCallback.cpp for the default values of the attachment.*/
- (NSDictionary *) abstractMessage:(MCOAbstractMessage *)msg templateValuesForPart:(MCOAbstractPart *)part;

/** @name Template Methods 
 The following methods returns templates. They will match the syntax of ctemplate.
 See https://code.google.com/p/ctemplate/ */

/** This delegate method returns the template for the main header of the message.
 See the content of MCHTMLRendererCallback.cpp for the default values of the template.*/
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg templateForMainHeader:(MCOMessageHeader *)header;

/** This delegate method returns the template an image attachment.*/
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg templateForImage:(MCOAbstractPart *)header;

/** This delegate method returns the template attachment other than images.
 See the content of MCHTMLRendererCallback.cpp for the default values of the template.*/
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg templateForAttachment:(MCOAbstractPart *)part;

/** This delegate method returns the template of the main message.
 It should include HEADER and a BODY values.
 See the content of MCHTMLRendererCallback.cpp for the default values of the template.*/
- (NSString *) abstractMessage_templateForMessage:(MCOAbstractMessage *)msg;

/** This delegate method returns the template of an embedded message (included as attachment).
 It should include HEADER and a BODY values.
 See the content of MCHTMLRendererCallback.cpp for the default values of the template.*/
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessage:(MCOAbstractMessagePart *)part;

/** This delegate method returns the template for the header of an embedded message.
 See the content of MCHTMLRendererCallback.cpp for the default values of the template.*/
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessageHeader:(MCOMessageHeader *)header;

/** This delegate method returns the separator between the text of the message and the attachments.*/
- (NSString *) abstractMessage_templateForAttachmentSeparator:(MCOAbstractMessage *)msg;

/** This delegate method cleans HTML content.
 For example, it could fix broken tags, add missing <html>, <body> tags.
 Default implementation uses HTMLCleaner::cleanHTML to clean HTML content. */
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg cleanHTMLForPart:(NSString *)html;

/** @name Filters
   
 The following methods will filter the HTML content and may apply some filters to
 change how to display the message.*/

/** This delegate method will apply the filter to HTML rendered content of a given text part.
 For example, it could filter the CSS content.*/
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg filterHTMLForPart:(NSString *)html;

/** This delegate method will apply a filter to the whole HTML content.
 For example, it could collapse the quoted messages.*/
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg filterHTMLForMessage:(NSString *)html;

// deprecated versions of the delegate methods.
- (BOOL) MCOAbstractMessage:(MCOAbstractMessage *)msg canPreviewPart:(MCOAbstractPart *)part;
- (BOOL) MCOAbstractMessage:(MCOAbstractMessage *)msg shouldShowPart:(MCOAbstractPart *)part;
- (NSDictionary *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateValuesForHeader:(MCOMessageHeader *)header;
- (NSDictionary *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateValuesForPart:(MCOAbstractPart *)part;
- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForMainHeader:(MCOMessageHeader *)header;
- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForImage:(MCOAbstractPart *)header;
- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForAttachment:(MCOAbstractPart *)part;
- (NSString *) MCOAbstractMessage_templateForMessage:(MCOAbstractMessage *)msg;
- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessage:(MCOAbstractMessagePart *)part;
- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessageHeader:(MCOMessageHeader *)header;
- (NSString *) MCOAbstractMessage_templateForAttachmentSeparator:(MCOAbstractMessage *)msg;
- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg cleanHTMLForPart:(NSString *)html;
- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg filterHTMLForPart:(NSString *)html;
- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg filterHTMLForMessage:(NSString *)html;

@end

#endif
