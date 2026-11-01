//
//  MCTCIDURLProtocol.h
//  testUI
//
//  Created by DINH Viêt Hoà on 1/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <MailCore/MailCore.h>

@interface MCOCIDURLProtocol : NSURLProtocol

+ (void) registerProtocol;

+ (BOOL) isCID:(NSURL *)url;
+ (BOOL) isXMailcoreImage:(NSURL *)url;

#ifdef __cplusplus
+ (void) startLoadingWithMessage:(MCOAbstractMessage *)message
                    partUniqueID:(NSString *)partUniqueID
                            data:(NSData *)data
                         request:(NSMutableURLRequest *)request;

+ (void) partDownloadedMessage:(MCOAbstractMessage *)message
                  partUniqueID:(NSString *)partUniqueID
                          data:(NSData *)data;
#endif

@end
