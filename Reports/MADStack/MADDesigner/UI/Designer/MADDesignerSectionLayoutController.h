//
//  UITableViewControllerSectionLayoutSettings.h
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDesignerSectionLayoutController_h
#define Reports_MADDesignerSectionLayoutController_h

#import <UIKit/UITableViewController.h>

extern NSString * const MADSectionLayoutSettingsID;

@class MADDesignerSectionLayoutController;

@protocol MADDesignerSectionLayoutDelegate <NSObject>

    - (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible;
    - (void)layoutSettings:(MADDesignerSectionLayoutController *)layoutSettings
              newPageAfter:(BOOL)newPageAfter;
@optional
    - (void)sectionLayoutDidUpdateHeight:(CGFloat)height;
    - (void)sectionLayoutDidUpdateNumberOfRows:(int32_t)numberOfRows;
    - (void)sectionLayoutSettingsDidFinish:(MADDesignerSectionLayoutController *)controller;
@end

@interface MADDesignerSectionLayoutController : UITableViewController
    <UITableViewDelegate>

    + (instancetype)newDesignerSectionLayoutController;

    @property (weak) IBOutlet id <MADDesignerSectionLayoutDelegate> delegate;

    @property (nonatomic, assign) double initalHeightValue;
    @property (nonatomic, assign) BOOL initalVisibility;
    @property (nonatomic, assign) BOOL initalFormFeedEnabled;
    @property (nonatomic, assign) int32_t initalNumberOfRows;

    - (void)updateDisplay;

@end

#endif
