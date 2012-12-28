//
//  labelInformationViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "UITableViewControllerFontSettings.h"
#import "UITableViewControllerFontSelector.h"

@class UIViewControllerToolbox;

@protocol ToolboxViewControllerDelegate
- (void)labelInformationViewControllerDidFinish:(UIViewControllerToolbox *)controller;
@end

@interface UIViewControllerToolbox : UIViewController
    <UIScrollViewDelegate,
    FontSettingsTableViewControllerDelegate,
    UITableViewControllerFontSelectorDelegate>

@property (assign, nonatomic) IBOutlet id <ToolboxViewControllerDelegate> delegate;
@property (retain, nonatomic) IBOutlet UIScrollView *mainScrollView;

@property (retain, nonatomic) UITableViewControllerFontSettings *fontSettingsTableViewController;
@property (retain, nonatomic) UITableViewControllerFontSelector *uITableViewControllerFontSelector;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;

- (IBAction)done:(id)sender;

@end