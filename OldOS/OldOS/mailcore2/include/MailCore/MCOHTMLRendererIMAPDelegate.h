//
//  MCOHTMLRendererIMAPDelegate.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOHTMLRENDERERIMAPDELEGATE_H

#define MAILCORE_MCOHTMLRENDERERIMAPDELEGATE_H

#import <MailCore/MCOHTMLRendererDelegate.h>

/**
 This delegate protocol is used to fetch the content of the part of the message when the HTML render needs them.
 It will help fetch the minimal amount of information from the message required to render the HTML.

 It will be used for the following method.

 [MCOIMAPMessage htmlRenderingWithFolder:delegate:]
*/

@class MCOIMAPPart;

@protocol MCOHTMLRendererIMAPDelegate <MCOHTMLRendererDelegate>

/** All methods are optional.*/
@optional

/** 
 The delegate method returns NULL if the delegate have not fetch the part yet. The opportunity can also be used to
 start fetching the attachment.
 It will return the data synchronously if it has already fetched it.
*/
- (NSData *) abstractMessage:(MCOAbstractMessage *)msg dataForIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder;

/**
 The delegate method will notify the delegate to start fetching the given part.
 It will be used to render an attachment that cannot be previewed.
*/
- (void) abstractMessage:(MCOAbstractMessage *)msg prefetchAttachmentIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder;

/**
 The delegate method will notify the delegate to start fetching the given part.
 It will be used to render an attachment that can be previewed.
*/
- (void) abstractMessage:(MCOAbstractMessage *)msg prefetchImageIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder;

// deprecated versions of the delegate methods.
- (NSData *) MCOAbstractMessage:(MCOAbstractMessage *)msg dataForIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder;
- (void) MCOAbstractMessage:(MCOAbstractMessage *)msg prefetchAttachmentIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder;
- (void) MCOAbstractMessage:(MCOAbstractMessage *)msg prefetchImageIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder;

@end

#endif
