//
//  UITableViewControllerSectionLayoutSettings.h
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADReportDesignerSectionLayoutSettingsViewController_h
#define Reports_MADReportDesignerSectionLayoutSettingsViewController_h

#import <UIKit/UITableViewController.h>

extern NSString * const MADSectionLayoutSettingsID;

@class MADReportDesignerSectionLayoutSettingsViewController;

@protocol MTReportDesignerSectionLayoutSettingsDelegate <NSObject>

    - (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible;
    - (void)layoutSettings:(MADReportDesignerSectionLayoutSettingsViewController *)layoutSettings
              newPageAfter:(BOOL)newPageAfter;
@optional
    - (void)sectionLayoutDidUpdateHeight:(CGFloat)height;
    - (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows;
    - (void)sectionLayoutSettingsDidFinish:(MADReportDesignerSectionLayoutSettingsViewController *)controller;
@end

@interface MADReportDesignerSectionLayoutSettingsViewController : UITableViewController
    <UITableViewDelegate>

    + (instancetype)newReportDesignerSectionLayoutSettingsViewController;

    @property (weak) IBOutlet id <MTReportDesignerSectionLayoutSettingsDelegate> delegate;

    @property (nonatomic, assign) double initalHeightValue;
    @property (nonatomic, assign) BOOL initalVisibility;
    @property (nonatomic, assign) BOOL initalFormFeedEnabled;
    @property (nonatomic, assign) int32_t initalNumberOfRows;

    - (void)updateDisplay;

@end

#endif
