//
//  test-all-mac.cpp
//  mailcore2
//
//  Created by Hoa Dinh on 11/12/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "test-all-mac.h"

#include <MailCore/MailCore.h>

extern "C" {
  extern int mailstream_debug;
}

static mailcore::String * password = NULL;
static mailcore::String * displayName = NULL;
static mailcore::String * email = NULL;

static void testProviders() {
  NSString *filename =  [[NSBundle bundleForClass:[MCOMessageBuilder class]] pathForResource:@"providers" ofType:@"json"];
  mailcore::MailProvidersManager::sharedManager()->registerProvidersWithFilename(filename.mco_mcString);
  
  NSLog(@"Providers: %s", MCUTF8DESC(mailcore::MailProvidersManager::sharedManager()->providerForEmail(MCSTR("email1@gmail.com"))));
}

void testObjC()
{
  MCOIMAPSession *session = [[MCOIMAPSession alloc] init];
  session.username = [NSString mco_stringWithMCString:email];
  session.password = [NSString mco_stringWithMCString:password];
  session.hostname = @"imap.gmail.com";
  session.port = 993;
  session.connectionType = MCOConnectionTypeTLS;
  
  NSLog(@"check account");
  MCOIMAPOperation *checkOp = [session checkAccountOperation];
  [checkOp start:^(NSError *err) {
    NSLog(@"check account done");
    if (err) {
      NSLog(@"Oh crap, an error %@", err);
    } else {
      NSLog(@"CONNECTED");
      NSLog(@"fetch all folders");
      MCOIMAPFetchFoldersOperation *foldersOp = [session fetchAllFoldersOperation];
      [foldersOp start:^(NSError *err, NSArray *folders) {
        NSLog(@"fetch all folders done");
        if (err) {
          NSLog(@"Oh crap, an error %@", err);
        } else {
          NSLog(@"Folder %@", folders);
        }
      }];
    }
  }];
  
  
  [[NSRunLoop currentRunLoop] run];
  [session autorelease];
}

void testAllMac()
{
  mailcore::setICUDataDirectory(MCSTR("/usr/local/share/icu"));
  
  email = MCSTR("email@gmail.com");
  password = MCSTR("MyP4ssw0rd");
  displayName = MCSTR("My Email");
  
  mailcore::AutoreleasePool * pool = new mailcore::AutoreleasePool();
  MCLogEnabled = 1;
  mailstream_debug = 1;
  
  //testProviders();
  //testObjC();
  
  pool->release();
}
