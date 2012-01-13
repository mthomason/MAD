//
//  FlipsideViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerDataSourceTypes.h"

@class UIViewControllerDatabases;

@protocol UIViewControllerDatabasesDelegate
- (void)flipsideViewControllerDidFinish:(UIViewControllerDatabases *)controller;
@end

@interface UIViewControllerDatabases : UIViewController
    <UIPopoverControllerDelegate,
        UITableViewControllerDataSourceTypesDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerDatabasesDelegate> delegate;
@property (strong, nonatomic) UIPopoverController *tableViewControllerDataSourceTypes;

- (IBAction)done:(id)sender;

@end