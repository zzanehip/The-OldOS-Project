//
//  MCOMessageView.h
//  testUI
//
//  Created by DINH Viêt Hoà on 1/19/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <MailCore/MailCore.h>

@protocol MCOMessageViewDelegate;

@interface MCOMessageView : NSView

@property (nonatomic, copy) NSString * folder;
@property (nonatomic, strong) MCOAbstractMessage * message;

@property (nonatomic, assign) id <MCOMessageViewDelegate> delegate;

@property (nonatomic, assign) BOOL prefetchIMAPImagesEnabled;
@property (nonatomic, assign) BOOL prefetchIMAPAttachmentsEnabled;

@end

@protocol MCOMessageViewDelegate <NSObject>

@optional
- (NSData *) MCOMessageView:(MCOMessageView *)view dataForPartWithUniqueID:(NSString *)partUniqueID;
- (void) MCOMessageView:(MCOMessageView *)view fetchDataForPartWithUniqueID:(NSString *)partUniqueID
     downloadedFinished:(void (^)(NSError * error))downloadFinished;

- (NSString *) MCOMessageView:(MCOMessageView *)view templateForMainHeader:(MCOMessageHeader *)header;
- (NSString *) MCOMessageView:(MCOMessageView *)view templateForImage:(MCOAbstractPart *)part;
- (NSString *) MCOMessageView:(MCOMessageView *)view templateForAttachment:(MCOAbstractPart *)part;
- (NSString *) MCOMessageView_templateForMessage:(MCOMessageView *)view;
- (NSString *) MCOMessageView:(MCOMessageView *)view templateForEmbeddedMessage:(MCOAbstractMessagePart *)part;
- (NSString *) MCOMessageView:(MCOMessageView *)view templateForEmbeddedMessageHeader:(MCOMessageHeader *)header;
- (NSString *) MCOMessageView_templateForAttachmentSeparator:(MCOMessageView *)view;

- (NSDictionary *) MCOMessageView:(MCOMessageView *)view templateValuesForPartWithUniqueID:(NSString *)uniqueID;
- (NSDictionary *) MCOMessageView:(MCOMessageView *)view templateValuesForHeader:(MCOMessageHeader *)header;
- (BOOL) MCOMessageView:(MCOMessageView *)view canPreviewPart:(MCOAbstractPart *)part;
- (BOOL) MCOMessageView:(MCOMessageView *)msg shouldShowPart:(MCOAbstractPart *)part;

- (NSString *) MCOMessageView:(MCOMessageView *)view filteredHTMLForPart:(NSString *)html;
- (NSString *) MCOMessageView:(MCOMessageView *)view filteredHTMLForMessage:(NSString *)html;
- (NSData *) MCOMessageView:(MCOMessageView *)view previewForData:(NSData *)data isHTMLInlineImage:(BOOL)isHTMLInlineImage;

@end
