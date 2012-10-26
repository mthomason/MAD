//
//  UIViewControllerSettings.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerSettings.h"

@class UIViewControllerSettings;

@protocol UIViewControllerSettingsDelegate
- (void)uIViewControllerSettingsDidFinish:(UIViewControllerSettings *)controller;
@end

@interface UIViewControllerSettings : UIViewController

@property (assign, nonatomic) IBOutlet id <UIViewControllerSettingsDelegate> delegate;

@property (retain, nonatomic) UITableViewControllerSettings *tableViewControllerSettings;

- (IBAction)done:(id)sender;

@end