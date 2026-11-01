//
//  MCTMsgViewController.m
//  testUI
//
//  Created by DINH Viêt Hoà on 1/20/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCTMsgViewController.h"

#import "MCOMessageView.h"

@interface MCTMsgViewController () <MCOMessageViewDelegate>

@end

@implementation MCTMsgViewController

@synthesize folder = _folder;
@synthesize session = _session;

- (void) awakeFromNib
{
    _storage = [[NSMutableDictionary alloc] init];
    _ops = [[NSMutableArray alloc] init];;
    _pending = [[NSMutableSet alloc] init];;
    _callbacks = [[NSMutableDictionary alloc] init];
}

- (void) setMessage:(MCOIMAPMessage *)message
{
    NSLog(@"set message : %@", message);
    NSLog(@"set attachments: %@ %@", [message attachments], [message htmlInlineAttachments]);
    for(MCOOperation * op in _ops) {
        [op cancel];
    }
    [_ops removeAllObjects];
    
    [_callbacks removeAllObjects];
    [_pending removeAllObjects];
    [_storage removeAllObjects];
    [_message release];
    _message = [message retain];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"FetchFullMessageEnabled"]) {
        [_messageView setDelegate:self];
        [_messageView setFolder:_folder];
        [_messageView setMessage:message];
    }
    else {
        [_messageView setMessage:NULL];
        MCOIMAPFetchContentOperation * op = [_session fetchMessageOperationWithFolder:_folder uid:[_message uid]];
        [_ops addObject:op];
        [op start:^(NSError * error, NSData * data) {
            if ([error code] != MCOErrorNone) {
                return;
            }
            
            NSAssert(data != nil, @"data != nil");
            
            MCOMessageParser * msg = [MCOMessageParser messageParserWithData:data];
            [_messageView setDelegate:self];
            [_messageView setFolder:_folder];
            [_messageView setMessage:msg];
        }];
    }
}

- (MCOIMAPMessage *) message
{
    return _message;
}

- (MCOIMAPFetchContentOperation *) _fetchIMAPPartWithUniqueID:(NSString *)partUniqueID folder:(NSString *)folder
{
    NSLog(@"%@ is missing, fetching", partUniqueID);
    
    if ([_pending containsObject:partUniqueID]) {
        return nil;
    }
    
    MCOIMAPPart * part = (MCOIMAPPart *) [_message partForUniqueID:partUniqueID];
    NSAssert(part != nil, @"part != nil");
    
    [_pending addObject:partUniqueID];
    
    MCOIMAPFetchContentOperation * op = [_session fetchMessageAttachmentOperationWithFolder:folder uid:[_message uid] partID:[part partID] encoding:[part encoding]];
    [_ops addObject:op];
    [op start:^(NSError * error, NSData * data) {
        if ([error code] != MCOErrorNone) {
            [self _callbackForPartUniqueID:partUniqueID error:error];
            return;
        }
        
        NSAssert(data != NULL, @"data != nil");
        [_ops removeObject:op];
        [_storage setObject:data forKey:partUniqueID];
        [_pending removeObject:partUniqueID];
        NSLog(@"downloaded %@", partUniqueID);
        
        [self _callbackForPartUniqueID:partUniqueID error:nil];
    }];
    
    return op;
}

typedef void (^DownloadCallback)(NSError * error);

- (void) _callbackForPartUniqueID:(NSString *)partUniqueID error:(NSError *)error
{
    NSArray * blocks;
    blocks = [_callbacks objectForKey:partUniqueID];
    NSLog(@"%@", blocks);
    for(DownloadCallback block in blocks) {
        block(error);
    }
    NSLog(@"done: %@", blocks);
}

- (NSString *) MCOMessageView:(MCOMessageView *)view templateForAttachment:(MCOAbstractPart *)part
{
    return @"<div><img src=\"http://www.iconshock.com/img_jpg/OFFICE/general/jpg/128/attachment_icon.jpg\"/></div>\
{{#HASSIZE}}\
<div>- {{FILENAME}}, {{SIZE}}</div>\
{{/HASSIZE}}\
{{#NOSIZE}}\
<div>- {{FILENAME}}</div>\
{{/NOSIZE}}";
}

- (NSString *) MCOMessageView_templateForMessage:(MCOMessageView *)view
{
    return @"<div style=\"padding-bottom: 20px; font-family: Helvetica; font-size: 13px;\">{{HEADER}}</div><div>{{BODY}}</div>";
}

- (BOOL) MCOMessageView:(MCOMessageView *)view canPreviewPart:(MCOAbstractPart *)part
{
    // tiff, tif, pdf
    NSString * mimeType = [[part mimeType] lowercaseString];
    if ([mimeType isEqualToString:@"image/tiff"]) {
        return YES;
    }
    else if ([mimeType isEqualToString:@"image/tif"]) {
        return YES;
    }
    else if ([mimeType isEqualToString:@"application/pdf"]) {
        return YES;
    }
    
    NSString * ext = nil;
    if ([part filename] != nil) {
        if ([[part filename] pathExtension] != nil) {
            ext = [[[part filename] pathExtension] lowercaseString];
        }
    }
    if (ext != nil) {
        if ([ext isEqualToString:@"tiff"]) {
            return YES;
        }
        else if ([ext isEqualToString:@"tif"]) {
            return YES;
        }
        else if ([ext isEqualToString:@"pdf"]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSString *) MCOMessageView:(MCOMessageView *)view filteredHTML:(NSString *)html
{
    return html;
}

- (NSData *) MCOMessageView:(MCOMessageView *)view dataForPartWithUniqueID:(NSString *)partUniqueID
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"FetchFullMessageEnabled"]) {
        MCOAttachment * attachment = (MCOAttachment *) [[_messageView message] partForUniqueID:partUniqueID];
        return [attachment data];
    }
    else {
        NSData * data = [_storage objectForKey:partUniqueID];
        return data;
    }
}

- (void) MCOMessageView:(MCOMessageView *)view fetchDataForPartWithUniqueID:(NSString *)partUniqueID
     downloadedFinished:(void (^)(NSError * error))downloadFinished
{
    MCOIMAPFetchContentOperation * op = [self _fetchIMAPPartWithUniqueID:partUniqueID folder:_folder];
    [op setProgress:^(unsigned int current, unsigned int maximum) {
        NSLog(@"progress content: %u/%u", current, maximum);
    }];
    if (op != nil) {
        [_ops addObject:op];
    }
    if (downloadFinished != NULL) {
        NSMutableArray * blocks;
        blocks = [_callbacks objectForKey:partUniqueID];
        if (blocks == nil) {
            blocks = [NSMutableArray array];
            [_callbacks setObject:blocks forKey:partUniqueID];
        }
        [blocks addObject:[[downloadFinished copy] autorelease]];
    }
}

- (NSData *) MCOMessageView:(MCOMessageView *)view previewForData:(NSData *)data isHTMLInlineImage:(BOOL)isHTMLInlineImage
{
    if (isHTMLInlineImage) {
        return data;
    }
    else {
        return [self _convertToJPEGData:data];
    }
}

#define IMAGE_PREVIEW_HEIGHT 300
#define IMAGE_PREVIEW_WIDTH 500

- (NSData *) _convertToJPEGData:(NSData *)data
{
    CGImageSourceRef imageSource;
    CGImageRef thumbnail;
    NSMutableDictionary * info;
    int width;
    int height;
    float quality;
    
    width = IMAGE_PREVIEW_WIDTH;
    height = IMAGE_PREVIEW_HEIGHT;
    quality = 1.0;
    
    imageSource = CGImageSourceCreateWithData((CFDataRef) data, NULL);
    if (imageSource == NULL)
        return nil;
    
    info = [[NSMutableDictionary alloc] init];
    [info setObject:(id) kCFBooleanTrue forKey:(id) kCGImageSourceCreateThumbnailWithTransform];
    [info setObject:(id) kCFBooleanTrue forKey:(id) kCGImageSourceCreateThumbnailFromImageAlways];
    [info setObject:(id) [NSNumber numberWithFloat:(float) IMAGE_PREVIEW_WIDTH] forKey:(id) kCGImageSourceThumbnailMaxPixelSize];
    thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef) info);
    [info release];
    
    CGImageDestinationRef destination;
    NSMutableData * destData = [NSMutableData data];
    
    destination = CGImageDestinationCreateWithData((CFMutableDataRef) destData,
                                                   (CFStringRef) @"public.jpeg",
                                                   1, NULL);
    
    CGImageDestinationAddImage(destination, thumbnail, NULL);
    CGImageDestinationFinalize(destination);
    
    CFRelease(destination);
    
    CFRelease(thumbnail);
    CFRelease(imageSource);
    
    return destData;
}

@end
