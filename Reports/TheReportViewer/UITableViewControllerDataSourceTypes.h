//
//  UITableViewControllerDataSourceTypes.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UITableViewControllerDataSourceTypes;

@protocol UITableViewControllerDataSourceTypesDelegate
- (void)uITableViewControllerDataSourceTypesDidFinish:(UITableViewControllerDataSourceTypes *)controller;
@end

@interface UITableViewControllerDataSourceTypes : UITableViewController

@property (assign, nonatomic) IBOutlet id <UITableViewControllerDataSourceTypesDelegate> delegate;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

@end