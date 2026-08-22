//
//  FXKeychain.m
//
//  Version 1.3.2
//
//  Created by Nick Lockwood on 29/12/2012.
//  Copyright 2012 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/FXKeychain
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//


#import "FXKeychain.h"


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


@implementation FXKeychain

+ (instancetype)defaultKeychain
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey];
        sharedInstance = [[FXKeychain alloc] initWithService:bundleID
                                                 accessGroup:nil];
    });

    return sharedInstance;
}

- (id)init
{
    return [self initWithService:nil accessGroup:nil];
}

- (id)initWithService:(NSString *)service
          accessGroup:(NSString *)accessGroup
{
    if ((self = [super init]))
    {
        _service = [service copy];
        _accessGroup = [accessGroup copy];
    }
    return self;
}

- (BOOL)setObject:(id)object forKey:(id)key
{
    NSParameterAssert(key);

    //generate query
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    if ([_service length]) query[(__bridge NSString *)kSecAttrService] = _service;
    query[(__bridge NSString *)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge NSString *)kSecAttrAccount] = [key description];
    
#if defined __IPHONE_OS_VERSION_MAX_ALLOWED && !TARGET_IPHONE_SIMULATOR
    if ([_accessGroup length]) query[(__bridge NSString *)kSecAttrAccessGroup] = _accessGroup;
#endif
    
    //encode object
    NSData *data = nil;
    NSError *error = nil;
    if ([(id)object isKindOfClass:[NSString class]])
    {
        data = [(NSString *)object dataUsingEncoding:NSUTF8StringEncoding];
    }
    else if (object)
    {
        data = [NSPropertyListSerialization dataWithPropertyList:object
                                                          format:NSPropertyListBinaryFormat_v1_0
                                                         options:0
                                                           error:&error];
    }

    //fail if object is invalid
    NSAssert(!object || (object && data), @"FXKeychain failed to encode object for key '%@', error: %@", key, error);

    //delete existing data
#if __IPHONE_4_0 && TARGET_OS_IPHONE 
	OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
#else
	CFTypeRef result;
	[query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnRef];
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
	if (status == errSecSuccess) {
		status = SecKeychainItemDelete((SecKeychainItemRef) result);
		CFRelease(result);
	}
#endif
	
    //write data
    if (data)
    {
        query[(__bridge NSString *)kSecValueData] = data;
        status = SecItemAdd ((__bridge CFDictionaryRef)query, NULL);
        if (status != errSecSuccess)
        {
            NSLog(@"FXKeychain failed to store data for key '%@', error: %ld", key, (long)status);
            return NO;
        }
    }
    else if (status != errSecSuccess)
    {
        NSLog(@"FXKeychain failed to delete data for key '%@', error: %ld", key, (long)status);
        return NO;
    }
    return YES;
}

- (BOOL)setObject:(id)object forKeyedSubscript:(id)key
{
    return [self setObject:object forKey:key];
}

- (BOOL)removeObjectForKey:(id)key
{
    return [self setObject:nil forKey:key];
}

- (id)objectForKey:(id)key
{
    NSParameterAssert(key);

    //generate query
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    if ([_service length]) query[(__bridge NSString *)kSecAttrService] = _service;
    query[(__bridge NSString *)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge NSString *)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    query[(__bridge NSString *)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    query[(__bridge NSString *)kSecAttrAccount] = [key description];
    
#if defined __IPHONE_OS_VERSION_MAX_ALLOWED && !TARGET_IPHONE_SIMULATOR
    if ([_accessGroup length]) query[(__bridge NSString *)kSecAttrAccessGroup] = _accessGroup;
#endif
    
    //recover data
    id object = nil;
    NSError *error = nil;
    CFDataRef data = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&data);
    if (status == errSecSuccess && data)
    {
        //attempt to decode as a plist
        object = [NSPropertyListSerialization propertyListWithData:(__bridge NSData *)data
                                                           options:NSPropertyListImmutable
                                                            format:NULL
                                                             error:&error];
        
        if ([object respondsToSelector:@selector(objectForKey:)] && object[@"$archiver"])
        {
            //data represents an NSCoded archive. don't trust it
            object = nil;
        }
        else if (!object)
        {
            //may be a string
            object = [[NSString alloc] initWithData:(__bridge NSData *)data encoding:NSUTF8StringEncoding];
        }
        if (!object)
        {
             NSLog(@"FXKeychain failed to decode data for key '%@', error: %@", key, error);
        }
        CFRelease(data);
        return object;
    }
    else
    {
        //no value found
        return nil;
    }
}

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

@end
