//
//  UITableViewControllerSectionLayoutSettings.h
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTReportDesignerSectionLayoutSettingsViewController;

@protocol MTReportDesignerSectionLayoutSettingsDelegate
- (void)sectionLayoutDidUpdateHeight:(CGFloat)height;
- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible;
@optional
- (void)sectionLayoutSettingsDidFinish:(MTReportDesignerSectionLayoutSettingsViewController *)controller;
@end

@interface MTReportDesignerSectionLayoutSettingsViewController : UITableViewController
    <UITableViewDelegate>

@property (assign) IBOutlet id <MTReportDesignerSectionLayoutSettingsDelegate> delegate;
@property (retain) IBOutlet UILabel *labelHeight;
@property (retain) IBOutlet UIStepper *heightStepper;
@property (retain) IBOutlet UISwitch *visibilitySwitch;

@property (assign) NSInteger initalStepperValue;
@property (assign) BOOL initalSwitchValue;

- (double)stepperValueNormalized;

@end
