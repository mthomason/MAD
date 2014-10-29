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
#import "MTReportDesignerFontSelectorViewController.h"

@class MADocument, MTReportDesignerFontSettingsViewController, MTFont;

@protocol MTReportDesignerFontSettingsDelegate
- (void)fontSettingsTableViewControllerDidSelectFontList:(MTReportDesignerFontSettingsViewController *)controller;
@end

@interface MTReportDesignerFontSettingsViewController : UITableViewController
    <MTToolboxViewControllerProtocol,
        MTReportDesignerFontSelectorDelegate>

@property (nonatomic, weak) id <MTReportDesignerFontSettingsDelegate> delegate;
@property (nonatomic, strong) MADocument *document;

@property (nonatomic, weak) IBOutlet UILabel *labelFontName;

- (void)chooseFont:(MTFont *)font;

@end

#endif
