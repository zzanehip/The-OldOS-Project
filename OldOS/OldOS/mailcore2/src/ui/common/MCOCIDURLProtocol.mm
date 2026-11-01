//
//  MCTCIDURLProtocol.m
//  testUI
//
//  Created by DINH Viêt Hoà on 1/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOCIDURLProtocol.h"

#define MCOCIDURLProtocolDownloadedNotification @"MCOCIDURLProtocolDownloadedNotification"

@implementation MCOCIDURLProtocol

+ (void) registerProtocol
{
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
		[NSURLProtocol registerClass:[MCOCIDURLProtocol class]];
	});
}

+ (BOOL) canInitWithRequest:(NSURLRequest *)theRequest
{
    if ([self isCID:[theRequest URL]])
        return YES;
    if ([self isXMailcoreImage:[theRequest URL]])
        return YES;
    return NO;
}

+ (BOOL) isCID:(NSURL *)url
{
	NSString *theScheme = [url scheme];
	if ([theScheme caseInsensitiveCompare:@"cid"] == NSOrderedSame)
        return YES;
    return NO;
}

+ (BOOL) isXMailcoreImage:(NSURL *)url
{
	NSString *theScheme = [url scheme];
	if ([theScheme caseInsensitiveCompare:@"x-mailcore-image"] == NSOrderedSame)
        return YES;
    return NO;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (id) initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id < NSURLProtocolClient >)client
{
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_downloaded:) name:MCOCIDURLProtocolDownloadedNotification object:nil];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (NSString *) _partUniqueID
{
    return [NSURLProtocol propertyForKey:@"PartUniqueID" inRequest:[self request]];
}

- (NSData *) _data
{
    return [NSURLProtocol propertyForKey:@"Data" inRequest:[self request]];
}

- (MCOAbstractMessage *) _message
{
    return (MCOAbstractMessage *) [NSURLProtocol propertyForKey:@"Message" inRequest:[self request]];
}

- (void) startLoading
{
    //NSLog(@"waiting for %p %@", self, [self _partUniqueID]);
    if ([self _data] != NULL) {
        [[self class] partDownloadedMessage:[self _message] partUniqueID:[self _partUniqueID] data:[self _data]];
    }
}

- (void) _downloaded:(NSNotification *)notification
{
    NSDictionary * userInfo = [notification userInfo];
    
    NSString * notifPartID = [userInfo objectForKey:@"PartUniqueID"];
    MCOAbstractMessage * notifMessage = [userInfo objectForKey:@"Message"];
    if (notifMessage != [self _message]) {
        return;
    }
    if (![[self _partUniqueID] isEqualToString:notifPartID]) {
        return;
    }
    
    NSData * data = [userInfo objectForKey:@"Data"];
    NSURLResponse * response = [[NSURLResponse alloc] initWithURL:[[self request] URL] MIMEType:@"application/data"
                                            expectedContentLength:[data length] textEncodingName:nil];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
    [response release];
}

- (void) stopLoading
{
}

+ (void) startLoadingWithMessage:(MCOAbstractMessage *)message
                    partUniqueID:(NSString *)partUniqueID
                            data:(NSData *)data
                         request:(NSMutableURLRequest *)request
{
    [NSURLProtocol setProperty:message
                        forKey:@"Message" inRequest:request];
    if (data != NULL) {
        [NSURLProtocol setProperty:data forKey:@"Data" inRequest:request];
    }
    [NSURLProtocol setProperty:partUniqueID forKey:@"PartUniqueID" inRequest:request];
}

+ (void) partDownloadedMessage:(MCOAbstractMessage *)message
                  partUniqueID:(NSString *)partUniqueID
                          data:(NSData *)data
{
    NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:message forKey:@"Message"];
    [userInfo setObject:partUniqueID forKey:@"PartUniqueID"];
    if (data != NULL) {
        [userInfo setObject:data forKey:@"Data"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MCOCIDURLProtocolDownloadedNotification object:nil userInfo:userInfo];
    [userInfo release];
}

@end
