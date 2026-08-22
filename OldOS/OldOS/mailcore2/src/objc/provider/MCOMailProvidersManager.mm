//
//  MCOMailProvidersManager.m
//  mailcore2
//
//  Created by Robert Widmann on 4/28/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOMailProvidersManager.h"
#include "MCMailProvidersManager.h"
#import "MCOMailProvider.h"

#import "NSString+MCO.h"
#import "NSDictionary+MCO.h"
#import "NSObject+MCO.h"

@implementation MCOMailProvidersManager 

+ (MCOMailProvidersManager *) sharedManager
{
    static MCOMailProvidersManager * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init]; \
    });
    return sharedInstance;
}

- (instancetype) init
{
    NSString * filename;
    
    self = [super init];
    
    filename = [[NSBundle bundleForClass:[self class]] pathForResource:@"providers" ofType:@"json"];
    if (filename) {
        mailcore::MailProvidersManager::sharedManager()->registerProvidersWithFilename(filename.mco_mcString);
    }
    
    return self;
}

- (MCOMailProvider *) providerForEmail:(NSString *)email
{
    mailcore::MailProvider *provider = mailcore::MailProvidersManager::sharedManager()->providerForEmail(email.mco_mcString);
    return MCO_TO_OBJC(provider);
}

- (MCOMailProvider *) providerForMX:(NSString *)hostname
{
    mailcore::MailProvider *provider = mailcore::MailProvidersManager::sharedManager()->providerForMX(hostname.mco_mcString);
    return MCO_TO_OBJC(provider);
}

- (MCOMailProvider *) providerForIdentifier:(NSString *)identifier
{
    mailcore::MailProvider *provider = mailcore::MailProvidersManager::sharedManager()->providerForIdentifier(identifier.mco_mcString);
    return MCO_TO_OBJC(provider);
}

- (void) registerProvidersWithFilename:(NSString *)filename
{
    mailcore::MailProvidersManager::sharedManager()->registerProvidersWithFilename(filename.mco_mcString);
}

@end
