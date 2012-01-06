//
//  labelInformationViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FontSettingsTableViewController.h"
#import "UITableViewControllerFontSelector.h"

@class EditObjectViewController;

@protocol LabelInformationViewControllerDelegate
- (void)labelInformationViewControllerDidFinish:(EditObjectViewController *)controller;
@end

@interface EditObjectViewController : UIViewController
    <UIScrollViewDelegate,
    FontSettingsTableViewControllerDelegate,
    UITableViewControllerFontSelectorDelegate>

@property (assign, nonatomic) IBOutlet id <LabelInformationViewControllerDelegate> delegate;
@property (retain, nonatomic) IBOutlet UIScrollView *mainScrollView;

@property (retain, nonatomic) FontSettingsTableViewController *fontSettingsTableViewController;
@property (retain, nonatomic) UITableViewControllerFontSelector *uITableViewControllerFontSelector;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;

- (IBAction)done:(id)sender;

@end