//
//  MADAboutTableViewController.h
//  MAD
//
//  Created by Michael Thomason on 8/20/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADAboutTableViewController_h
#define Reports_MADAboutTableViewController_h

#import <UIKit/UITableViewController.h>

@protocol MADViewControllerStandardProtocol;

@interface MADAboutTableViewController : UITableViewController

@property (nonatomic, weak) IBOutlet id <MADViewControllerStandardProtocol, UITableViewDelegate> delegate;

+ (instancetype)newAboutTableViewController;
- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end

#endif
