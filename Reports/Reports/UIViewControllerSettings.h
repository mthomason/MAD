//
//  UIViewControllerSettings.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUIViewController.h"
#import "UITableViewControllerSettings.h"

@interface UIViewControllerSettings : MUIViewController

@property (retain, nonatomic) UITableViewControllerSettings *tableViewControllerSettings;

- (IBAction)done:(id)sender;

@end