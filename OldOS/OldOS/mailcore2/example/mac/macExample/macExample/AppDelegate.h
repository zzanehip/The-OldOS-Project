//
//  AppDelegate.h
//  testUI
//
//  Created by DINH Viêt Hoà on 1/19/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MCTMsgListViewController;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet MCTMsgListViewController * _msgListViewController;
    IBOutlet NSWindow * _accountWindow;
}

- (IBAction) accountLogin:(id)sender;
- (IBAction) accountCancel:(id)sender;

@end
