//
//  fontSettingsTableViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerFontSettingsViewController_h
#define Reports_MTReportDesignerFontSettingsViewController_h

#import <UIKit/UIKit.h>
#import "MTToolboxViewControllerProtocol.h"

@class MTReportDesignerFontSettingsViewController, MTFont;

@protocol MTReportDesignerFontSettingsDelegate
- (void)fontSettingsTableViewControllerDidSelectFontList:(MTReportDesignerFontSettingsViewController *)controller;
@end

@interface MTReportDesignerFontSettingsViewController : UITableViewController
    <MTToolboxViewControllerProtocol>

@property (assign, nonatomic) IBOutlet id <MTReportDesignerFontSettingsDelegate> delegate;
@property (nonatomic, retain) IBOutlet UILabel *labelFontName;

- (void)chooseFont:(MTFont *)font;

@end

#endif
