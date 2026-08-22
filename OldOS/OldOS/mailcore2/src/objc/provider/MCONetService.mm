//
//  MCONetService.m
//  mailcore2
//
//  Created by Robert Widmann on 4/28/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCONetService.h"
#include "MCNetService.h"

#import "NSDictionary+MCO.h"
#import "NSString+MCO.h"
#import "NSObject+MCO.h"

@implementation MCONetService {
    mailcore::NetService *_netService;
}

#define nativeType mailcore::NetService

+ (void) load
{
    MCORegisterClass( self, &typeid(nativeType) );
}

- (mailcore::Object *) mco_mcObject
{
    return _netService;
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::NetService *netService = (mailcore::NetService *)object;
    return [[[self alloc] initWithNetService:netService] autorelease];
}

+ (MCONetService *) serviceWithInfo:(NSDictionary *)info
{
    return [[[self alloc] initWithInfo:info] autorelease];
}

- (instancetype) initWithInfo:(NSDictionary *)info
{
    self = [super init];
    
    _netService = mailcore::NetService::serviceWithInfo(info.mco_mcHashMap);
    _netService->retain();
    
    return self;
}

- (instancetype) initWithNetService:(mailcore::NetService *)netService
{
    self = [super init];
    
    _netService = netService;
    _netService->retain();
    
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    nativeType * nativeObject = (nativeType *) [self mco_mcObject]->copy();
    id result = [[self class] mco_objectWithMCObject:nativeObject];
    MC_SAFE_RELEASE(nativeObject);
    return [result retain];
}

MCO_OBJC_SYNTHESIZE_STRING(setHostname, hostname)
MCO_OBJC_SYNTHESIZE_SCALAR(unsigned int, unsigned int, setPort, port)
MCO_OBJC_SYNTHESIZE_SCALAR(MCOConnectionType, mailcore::ConnectionType, setConnectionType, connectionType)

- (NSDictionary *) info
{
    return [NSDictionary mco_dictionaryWithMCHashMap:_netService->info()];
}

- (NSString *) hostnameWithEmail:(NSString *)email
{
    return [NSString mco_stringWithMCString:_netService->normalizedHostnameWithEmail(email.mco_mcString)];
}

@end