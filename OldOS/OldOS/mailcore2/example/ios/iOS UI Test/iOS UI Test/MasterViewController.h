//
//  MasterViewController.h
//  iOS UI Test
//
//  Created by Jonathan Willing on 4/8/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"

@interface MasterViewController : UITableViewController <SettingsViewControllerDelegate>

- (IBAction)showSettingsViewController:(id)sender;

@end
