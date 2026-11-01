//
// Created by Hai Nguyen on 21/12/2020.
// Copyright (c) 2020 MailCore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>


@interface MCOMessageViewWebDelegate : NSObject <WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, copy, nullable) void (^openInlineAttachments)(NSArray * imgUrls);

- (void)updateImageUrl:(NSString *)path at:(NSString *)cid on:(WKWebView *)webView;

@end