//
//  SettingsViewController.h
//  iOS UI Test
//
//  Created by Jonathan Willing on 4/8/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const UsernameKey;
extern NSString * const PasswordKey;
extern NSString * const HostnameKey;
extern NSString * const FetchFullMessageKey;
extern NSString * const OAuthEnabledKey;

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *hostnameTextField;
@property (weak, nonatomic) IBOutlet UISwitch *fetchFullMessageSwitch;

@property (nonatomic, weak) id<SettingsViewControllerDelegate> delegate;
- (IBAction)done:(id)sender;

@end

@protocol SettingsViewControllerDelegate <NSObject>
- (void)settingsViewControllerFinished:(SettingsViewController *)viewController;
@end
