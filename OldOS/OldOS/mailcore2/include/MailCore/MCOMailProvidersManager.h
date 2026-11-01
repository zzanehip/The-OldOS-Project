//
//  MCOMailProvidersManager.h
//  mailcore2
//
//  Created by Robert Widmann on 4/28/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
   This class is used to detect an email provider and it's associated
   metadata either by MX record or by the email addresss.

   An app might want to use this during setup to limit the number of settings
   a user has to input.
*/

@class MCOMailProvider;

@interface MCOMailProvidersManager : NSObject

NS_ASSUME_NONNULL_BEGIN

/** The shared manager that is used for all lookups */
+ (MCOMailProvidersManager *) sharedManager;

/** 
    Given an email address will try to determine the provider
    @return The email provider info or nil if it can't be determined.
*/
- (nullable MCOMailProvider *) providerForEmail:(NSString *)email;

/** 
    Given the DNS MX record will try to determine the provider
    @return The email provider info or nil if it can't be determined.
*/
- (nullable MCOMailProvider *) providerForMX:(NSString *)hostname;

/**
   Will return information about a provider. Useful if you already know the
   provider (like if it has been determined previously)
   @return The email provider info or nil if none matches
*/
- (nullable MCOMailProvider *) providerForIdentifier:(NSString *)identifier;

/**
   Registers the providers in the JSON file at the file path so they
   can be used with MCOMailProvidersManager.
 */
- (void) registerProvidersWithFilename:(NSString *)filename;

NS_ASSUME_NONNULL_END

@end
