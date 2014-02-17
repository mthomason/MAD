//
//  fontSettingsTableViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerFontSettingsViewController_h
#define Reports_MTReportDesignerFontSettingsViewController_h

#import <UIKit/UIKit.h>
#import "MTToolboxViewControllerProtocol.h"
#import "MTFont.h"
#import "MTApplicaitonInstance.h"

@class MTReportDesignerFontSettingsViewController;

@protocol MTReportDesignerFontSettingsDelegate
- (void)fontSettingsTableViewControllerDidSelectFontList:(MTReportDesignerFontSettingsViewController *)controller;
@end

@interface MTReportDesignerFontSettingsViewController : UITableViewController
    <UITableViewDelegate, MTToolboxViewControllerProtocol>

@property (assign, nonatomic) IBOutlet id <MTReportDesignerFontSettingsDelegate> delegate;
//@property (nonatomic, retain) MTApplicaitonInstance *applicationInstance;

@property (nonatomic, retain) IBOutlet UILabel *labelFontName;

- (void)chooseFont:(MTFont *)font;

@end

#endif
