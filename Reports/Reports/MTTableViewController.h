//
//  MUITableViewController.h
//  Reports
//
//  Created by Michael Thomason on 11/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTTableViewController_h
#define Reports_MTTableViewController_h

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"

@interface MTTableViewController : UITableViewController

@property (assign, nonatomic) IBOutlet id <MTViewControllerProtocol> delegate;

@end

#endif
