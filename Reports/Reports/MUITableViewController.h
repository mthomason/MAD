//
//  MUITableViewController.h
//  Reports
//
//  Created by Michael Thomason on 11/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"

@interface MUITableViewController : UITableViewController

@property (assign, nonatomic) IBOutlet id <MUIViewControllerDelegate> delegate;

@end