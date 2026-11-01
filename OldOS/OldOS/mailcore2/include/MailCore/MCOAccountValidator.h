//
//  MCOAccountValidator.h
//  mailcore2
//
//  Created by Christopher Hockley on 20/01/15.
//  Copyright (c) 2015 MailCore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MCOOperation.h>
#import <MailCore/MCOConstants.h>

/**
 This class is used to validate an email provider and it's associated
 metadata and credentials.
 
 An app might want to use this during setup to limit the number of settings
 a user has to input.
 */

@class MCONetService;

@interface MCOAccountValidator : MCOOperation

@property (nonatomic, copy) NSString * email; /* for SMTP */
@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * password;
@property (nonatomic, copy) NSString * OAuth2Token;

@property (nonatomic, retain) NSArray<MCONetService *> * imapServices;
@property (nonatomic, retain) NSArray<MCONetService *> * popServices;
@property (nonatomic, retain) NSArray<MCONetService *> * smtpServices;

@property (nonatomic, assign, getter=isImapEnabled) BOOL imapEnabled;
@property (nonatomic, assign, getter=isPopEnabled) BOOL popEnabled;
@property (nonatomic, assign, getter=isSmtpEnabled) BOOL smtpEnabled;

@property (nonatomic, copy) MCOConnectionLogger connectionLogger;

// result
@property (nonatomic, retain, readonly) NSString * identifier;
@property (nonatomic, retain, readonly) MCONetService * imapServer;
@property (nonatomic, retain, readonly) MCONetService * popServer;
@property (nonatomic, retain, readonly) MCONetService * smtpServer;
@property (nonatomic, retain, readonly) NSError * imapError;
@property (nonatomic, retain, readonly) NSError * popError;
@property (nonatomic, retain, readonly) NSError * smtpError;

/**
 Starts the asynchronous account validation operation.
 
 @param completionBlock Called when the operation is finished.
 */
- (void) start:(void (^)(void))completionBlock;

- (instancetype) init;

@end
