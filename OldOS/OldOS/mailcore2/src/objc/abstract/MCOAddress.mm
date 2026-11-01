//
//  MCOAddress.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/10/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOAddress.h"
#import "MCOAddress+Private.h"

#include <typeinfo>

#include "MCAddress.h"
#include "NSString+MCO.h"
#include "NSObject+MCO.h"
#include "NSArray+MCO.h"

@implementation MCOAddress {
    mailcore::Address * _nativeAddress;
}

#define nativeType mailcore::Address

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

- (id) copyWithZone:(NSZone *)zone
{
    nativeType * nativeObject = (nativeType *) [self mco_mcObject]->copy();
    id result = [[self class] mco_objectWithMCObject:nativeObject];
    MC_SAFE_RELEASE(nativeObject);
    return [result retain];
}

MCO_SYNTHESIZE_NSCODING

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::Address * address = (mailcore::Address *) object;
    return [[[self alloc] initWithMCAddress:address] autorelease];
}

- (mailcore::Object *) mco_mcObject
{
    return _nativeAddress;
}

+ (MCOAddress *) addressWithDisplayName:(NSString *)displayName
                                mailbox:(NSString *)mailbox
{
    MCOAddress * result = [[[MCOAddress alloc] init] autorelease];
    MC_SAFE_RELEASE(result->_nativeAddress);
    result->_nativeAddress = mailcore::Address::addressWithDisplayName([displayName mco_mcString], [mailbox mco_mcString]);
    if (!result->_nativeAddress) {
        return NULL;
    }
    result->_nativeAddress->retain();
    return result;
}

+ (MCOAddress *) addressWithMailbox:(NSString *)mailbox
{
    MCOAddress * result = [[[MCOAddress alloc] init] autorelease];
    MC_SAFE_RELEASE(result->_nativeAddress);
    result->_nativeAddress = mailcore::Address::addressWithMailbox([mailbox mco_mcString]);
    if (!result->_nativeAddress) {
        return NULL;
    }
    result->_nativeAddress->retain();
    return result;
}

+ (MCOAddress *) addressWithRFC822String:(NSString *)RFC822String
{
    MCOAddress * result = [[[MCOAddress alloc] init] autorelease];
    MC_SAFE_RELEASE(result->_nativeAddress);
    result->_nativeAddress = mailcore::Address::addressWithRFC822String([RFC822String mco_mcString]);
    if (!result->_nativeAddress) {
        return NULL;
    }
    result->_nativeAddress->retain();
    return result;
}

+ (MCOAddress *) addressWithNonEncodedRFC822String:(NSString *)nonEncodedRFC822String
{
    MCOAddress * result = [[[MCOAddress alloc] init] autorelease];
    MC_SAFE_RELEASE(result->_nativeAddress);
    result->_nativeAddress = mailcore::Address::addressWithNonEncodedRFC822String([nonEncodedRFC822String mco_mcString]);
    if (!result->_nativeAddress) {
        return NULL;
    }
    result->_nativeAddress->retain();
    return result;
}

+ (NSArray<MCOAddress *> *) addressesWithRFC822String:(NSString *)string
{
    return [NSArray mco_arrayWithMCArray:mailcore::Address::addressesWithRFC822String(string.mco_mcString)];
}

+ (NSArray<MCOAddress *> *) addressesWithNonEncodedRFC822String:(NSString *)string
{
    return [NSArray mco_arrayWithMCArray:mailcore::Address::addressesWithNonEncodedRFC822String(string.mco_mcString)];
}


- (instancetype) init
{
    self = [super init];
    
    _nativeAddress = new mailcore::Address();
    
    return self;
}

- (instancetype) initWithMCAddress:(mailcore::Address *)address
{
    self = [super init];
    
    _nativeAddress = address;
    _nativeAddress->retain();
    
    return self;
}

+ (MCOAddress *) addressWithMCAddress:(mailcore::Address *)address
{
    if (address == NULL)
        return nil;
    
    return [[[self alloc] initWithMCAddress:address] autorelease];
}

- (void) dealloc
{
    MC_SAFE_RELEASE(_nativeAddress);
    [super dealloc];
}

- (NSString *) description
{
    return MCO_OBJC_BRIDGE_GET(description);
}

MCO_OBJC_SYNTHESIZE_STRING(setDisplayName, displayName)
MCO_OBJC_SYNTHESIZE_STRING(setMailbox, mailbox)

- (NSString *) RFC822String
{
    return MCO_OBJC_BRIDGE_GET(RFC822String);
}

- (NSString *) nonEncodedRFC822String
{
    return MCO_OBJC_BRIDGE_GET(nonEncodedRFC822String);
}

- (NSUInteger) hash
{
    return [[self displayName] hash] ^ [[self mailbox] hash];
}

- (BOOL) isEqual:(id)object
{
    if (![object isKindOfClass:[MCOAddress class]]) {
        return NO;
    }

    MCOAddress * other = object;
    return [[self displayName] isEqualToString:[other displayName]] &&
        [[self mailbox] isEqualToString:[other mailbox]];
}

@end

@implementation NSArray (MCOAddress)

- (NSString *) mco_RFC822StringForAddresses
{
    return [NSString mco_stringWithMCString:mailcore::Address::RFC822StringForAddresses([self mco_mcArray])];
}

- (NSString *) mco_nonEncodedRFC822StringForAddresses
{
    return [NSString mco_stringWithMCString:mailcore::Address::nonEncodedRFC822StringForAddresses([self mco_mcArray ])];
}

@end
