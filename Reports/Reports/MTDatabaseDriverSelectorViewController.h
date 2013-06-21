//
//  UITableViewControllerDataSourceTypes.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseDriverSelectorViewController_h
#define Reports_MTDatabaseDriverSelectorViewController_h

#import <UIKit/UIKit.h>
#import "MTTableViewController.h"
#import "UIDevice+Hack.h"
#import "Constants.h"
#import "MTDatabaseDriverSelectorMySqlViewController.h"

@interface MTDatabaseDriverSelectorViewController : MTTableViewController

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

@end

#endif
