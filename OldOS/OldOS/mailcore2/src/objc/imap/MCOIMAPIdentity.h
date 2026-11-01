//
//  MCOIMAPIdentity.h
//  mailcore2
//
//  Created by Hoa V. DINH on 8/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPIDENTITY_H

#define MAILCORE_MCOIMAPIDENTITY_H

#import <Foundation/Foundation.h>

@interface MCOIMAPIdentity : NSObject <NSCopying>

/** Returns a simple identity */
+ (MCOIMAPIdentity *) identityWithVendor:(NSString *)vendor
                                    name:(NSString *)name
                                 version:(NSString *)version;

/** Vendor of the IMAP client */
@property (nonatomic, copy) NSString * vendor;

/** Name of the IMAP client */
@property (nonatomic, copy) NSString * name;

/** Version of the IMAP client */
@property (nonatomic, copy) NSString * version;

/** All fields names of the identity of the client */
- (NSArray<NSString *> *) allInfoKeys;

/** Set a custom field in the identity */
- (NSString *) infoForKey:(NSString *)key;

/** Retrieve a custom field in the identity */
- (void) setInfo:(NSString *)value forKey:(NSString *)key;

/** Remove all info keys including vendor, name and version */
- (void) removeAllInfos;

@end

#endif
