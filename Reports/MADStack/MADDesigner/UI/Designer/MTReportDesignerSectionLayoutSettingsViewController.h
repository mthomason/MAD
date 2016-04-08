//
//  UITableViewControllerSectionLayoutSettings.h
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerSectionLayoutSettingsViewController_h
#define Reports_MTReportDesignerSectionLayoutSettingsViewController_h

#import <UIKit/UITableViewController.h>

extern NSString * const MTReportDesignerSectionLayoutSettingsViewControllerIdentifier;

@class MTReportDesignerSectionLayoutSettingsViewController;

@protocol MTReportDesignerSectionLayoutSettingsDelegate <NSObject>

    - (void)sectionLayoutDidUpdateVisibility:(bool)isVisible;
    - (void)layoutSettings:(MTReportDesignerSectionLayoutSettingsViewController *)layoutSettings newPageAfter:(bool)newPageAfter;
@optional
    - (void)sectionLayoutDidUpdateHeight:(CGFloat)height;
    - (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows;
    - (void)sectionLayoutSettingsDidFinish:(MTReportDesignerSectionLayoutSettingsViewController *)controller;
@end

@interface MTReportDesignerSectionLayoutSettingsViewController : UITableViewController
    <UITableViewDelegate>

    + (instancetype)toolboxSettings;

    @property (weak) IBOutlet id <MTReportDesignerSectionLayoutSettingsDelegate> delegate;

    @property (nonatomic, assign) double initalHeightValue;
    @property (nonatomic, assign) BOOL initalVisibility;
    @property (nonatomic, assign) BOOL initalFormFeedEnabled;
    @property (nonatomic, assign) NSUInteger initalNumberOfRows;

    - (void)updateDisplay;

@end

#endif
