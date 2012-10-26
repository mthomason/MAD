//
//  UIModalTableViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIModalTableViewController;

@protocol UIModalTableViewControllerDelegate
- (void)modalTableViewControllerDidFinish:(id)controller;
@end

@interface UIModalTableViewController : UITableViewController

@property (assign, nonatomic) IBOutlet id <UIModalTableViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end