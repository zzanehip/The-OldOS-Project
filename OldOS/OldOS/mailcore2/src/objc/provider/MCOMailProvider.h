//
//  MCOMailProvider.h
//  mailcore2
//
//  Created by Robert Widmann on 4/28/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCONetService;

/**
   Represents a email service provider, like for example Gmail, Yahoo, Fastmail.fm etc.
*/

@interface MCOMailProvider : NSObject

@property (nonatomic, copy) NSString * identifier;

- (instancetype) initWithInfo:(NSDictionary *)info;

/**
   A list of ways that you can connect to the IMAP server
   @return An array of MCONetService
*/
- (NSArray<MCONetService *> *) imapServices;

/**
   A list of ways that you can connect to the SMTP server
   @return An array of MCONetService
*/
- (NSArray<MCONetService *> *) smtpServices;

/**
   A list of ways that you can connect to the POP3 server
   @return An array of MCONetService
*/
- (NSArray<MCONetService *> *) popServices;

- (BOOL) matchEmail:(NSString *)email;
- (BOOL) matchMX:(NSString *)hostname;

/**
   Where sent mail is stored on the IMAP server
   @return Returns nil if it is unknown
*/
- (NSString *) sentMailFolderPath;

/**
   Where starred mail is stored on the IMAP server.
   This only applies to some servers like Gmail
   @return Returns nil if it is unknown
*/
- (NSString *) starredFolderPath;

/**
   Where all mail or the archive folder is stored on the IMAP server
   @return Returns nil if it is unknown
*/
- (NSString *) allMailFolderPath;

/**
   Where trash is stored on the IMAP server
   @return Returns nil if it is unknown
*/
- (NSString *) trashFolderPath;

/**
   Where draft messages are stored on the IMAP server
   @return Returns nil if it is unknown
*/
- (NSString *) draftsFolderPath;

/**
   Where spam messages are stored on the IMAP server
   @return Returns nil if it is unknown
*/
- (NSString *) spamFolderPath;

/**
   Where important messages are stored on the IMAP server
   This only applies to some servers, like Gmail
   @return Returns nil if it is unknown
*/
- (NSString *) importantFolderPath;

#pragma mark - Unavailable initializers
/** Do not invoke this directly. */
- (instancetype) init NS_UNAVAILABLE;
/** Do not invoke this directly. */
+ (instancetype) new NS_UNAVAILABLE;

@end
