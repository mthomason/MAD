//
//  UIViewControllerSettings.h
//  Reports
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "Constants.h"
#import "UITableViewControllerSettings.h"

@interface UIViewControllerSettings : MTViewController

@property (retain, nonatomic) UITableViewControllerSettings *tableViewControllerSettings;

- (IBAction)done:(id)sender;

@end