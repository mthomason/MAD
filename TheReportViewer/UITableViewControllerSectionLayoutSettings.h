//
//  UITableViewControllerSectionLayoutSettings.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UITableViewControllerSectionLayoutSettings;

@protocol SectionLayoutSettingsDelegate
- (void)sectionLayoutDidUpdateHeight:(CGFloat)height;
- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible;
@optional
- (void)sectionLayoutSettingsDidFinish:(UITableViewControllerSectionLayoutSettings *)controller;
@end

@interface UITableViewControllerSectionLayoutSettings : UITableViewController
    <UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <SectionLayoutSettingsDelegate> delegate;
@property (retain, nonatomic) IBOutlet UILabel *labelHeight;
@property (retain, nonatomic) IBOutlet UIStepper *heightStepper;
@property (retain, nonatomic) IBOutlet UISwitch *visibilitySwitch;

@property (assign) NSInteger initalStepperValue;
@property (assign) BOOL initalSwitchValue;

- (double)stepperValueNormalized;

@end