//
//  MCOMessageBuilder.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOMESSAGEBUILDER_H

#define MAILCORE_MCOMESSAGEBUILDER_H

#import <MailCore/MCOAbstractMessage.h>

@class MCOAttachment;
/**
 This class will allow you to build a RFC 822 formatted message.
 For example when you need to send a message using SMTP,
 you need to generate first a RFC 822 formatted message.
 This class will help you do that.
 
    MCOMessageBuilder * builder = [[MCOMessageBuilder alloc] init];
    [[builder header] setFrom:[MCOAddress addressWithDisplayName:@"Hoa V. DINH" mailbox:@"hoa@etpan.org"];
    NSArray * to = [NSArray arrayWithObject:[MCOAddress addressWithDisplayName:@"Gael Roualland" mailbox:@"gael@etpan.org"]];
    [[builder header] setTo:to];
    [[builder header] setSubject:@"A nice picture!"];
    [builder setHTMLBody:@"<div>Here's the message I need to send.</div>"];
    [builder addAttachment:[MCOAttachment attachmentWithContentsOfFile:@"/Users/foo/Pictures/image.jpg"]];
    NSData * rfc822Data = [builder data];
 
*/

@class MCOAttachment;
@protocol MCOHTMLRendererDelegate;

@interface MCOMessageBuilder : MCOAbstractMessage <NSCopying>

/** Main HTML content of the message.*/
@property (nonatomic, copy, setter=setHTMLBody:) NSString * htmlBody;

/** Plain text content of the message.*/
@property (nonatomic, copy) NSString * textBody;

/** List of file attachments.*/
@property (nonatomic, copy) NSArray<MCOAttachment *> * attachments;

/** List of related file attachments (included as cid: link in the HTML part).*/
@property (nonatomic, copy) NSArray<MCOAttachment *> * relatedAttachments;

/** Prefix for the boundary identifier. Default value is nil.*/
@property (nonatomic, copy) NSString * boundaryPrefix;

/** Add an attachment.*/
- (void) addAttachment:(MCOAttachment *)attachment;

/** Add a related attachment.*/
- (void) addRelatedAttachment:(MCOAttachment *)attachment;

/** RFC 822 formatted message.*/
- (NSData *) data;

/** RFC 822 formatted message for encryption.*/
- (NSData *) dataForEncryption;

/** Store RFC 822 formatted message to file. */
- (BOOL) writeToFile:(NSString *)filename error:(NSError **)error;

/**
 Returns an OpenPGP signed message with a given signature.
 The signature needs to be computed on the data returned by -dataForEncryption
 before calling this method.
 You could use http://www.netpgp.com to generate it.
 */
- (NSData *) openPGPSignedMessageDataWithSignatureData:(NSData *)signature;

/**
 Returns an OpenPGP encrypted message with a given encrypted data.
 The encrypted data needs to be computed before calling this method.
 You could use http://www.netpgp.com to generate it.
 */
- (NSData *) openPGPEncryptedMessageDataWithEncryptedData:(NSData *)encryptedData;

/** HTML rendering of the message to be displayed in a web view. The delegate can be nil.*/
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
