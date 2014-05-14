//
//  UITableViewControllerSectionLayoutSettings.h
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerSectionLayoutSettingsViewController_h
#define Reports_MTReportDesignerSectionLayoutSettingsViewController_h

#import <UIKit/UIKit.h>

extern NSString * const MTReportDesignerSectionLayoutSettingsViewControllerIdentifier;

@class MTReportDesignerSectionLayoutSettingsViewController;

@protocol MTReportDesignerSectionLayoutSettingsDelegate
- (void)sectionLayoutDidUpdateHeight:(CGFloat)height;
- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible;
- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows;
@optional
- (void)sectionLayoutSettingsDidFinish:(MTReportDesignerSectionLayoutSettingsViewController *)controller;
@end

@interface MTReportDesignerSectionLayoutSettingsViewController : UITableViewController
    <UITableViewDelegate>

@property (weak) IBOutlet id <MTReportDesignerSectionLayoutSettingsDelegate> delegate;

@property (nonatomic, assign) NSInteger initalStepperValue;
@property (nonatomic, assign) BOOL initalSwitchValue;
@property (nonatomic, assign) NSUInteger initalNumberOfRows;

- (void)updateDisplay;

@end

#endif
