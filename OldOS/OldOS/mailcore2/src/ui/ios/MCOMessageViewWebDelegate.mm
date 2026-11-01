//
// Created by Hai Nguyen on 21/12/2020.
// Copyright (c) 2020 MailCore. All rights reserved.
//

#import "MCOMessageViewWebDelegate.h"

@interface NSURL (QueryParser)

-(NSDictionary*)queryDictionary;

@end


@implementation MCOMessageViewWebDelegate {

}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
    preferences:(WKWebpagePreferences *)preferences
decisionHandler:(void (^)(WKNavigationActionPolicy, WKWebpagePreferences *))decisionHandler  API_AVAILABLE(macos(10.15)){
    if ([navigationAction.request.URL.query containsString:@"params"]) {
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:navigationAction.request.URL resolvingAgainstBaseURL:false];
        NSMutableArray *imgElements = [NSMutableArray new];

        NSString * jsonValue = [navigationAction.request.URL queryDictionary][@"params"];
        jsonValue = [jsonValue stringByRemovingPercentEncoding];
        NSData * data = [jsonValue dataUsingEncoding:NSUTF8StringEncoding];

        NSError *error;
        imgElements = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];


        self.openInlineAttachments(imgElements);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        decisionHandler(WKNavigationActionPolicyAllow, [WKWebpagePreferences new]);
    });
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [webView evaluateJavaScript:@"scanInlineImages();" completionHandler:nil];
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)webView:(WKWebView *)webView authenticationChallenge:(NSURLAuthenticationChallenge *)challenge
shouldAllowDeprecatedTLS:(void (^)(BOOL))decisionHandler {
    decisionHandler(YES);
}

#pragma end - WKNavigationDelegate

#pragma mark - WKUIDelegate

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    return nil;
}

#pragma end - WKUIDelegate

- (void)updateImageUrl:(NSString *)path at:(NSString *)cid on:(WKWebView *)webView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [webView evaluateJavaScript:[NSString stringWithFormat:@"updateImageUrl({\"id\":\"%@\",\"url\":\"%@\"});", cid, path]
                  completionHandler:^(id _Nullable, NSError * _Nullable error) {
                      NSLog(@"error: %@", error);
                  }];
    });
}

@end

@implementation NSURL (QueryParser)

-(NSDictionary *)queryDictionary
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [[self query] componentsSeparatedByString:@"&"]) {
        NSArray *parts = [param componentsSeparatedByString:@"="];
        if([parts count] < 2) continue;
        [params setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
    }
    return params;
}

@end
