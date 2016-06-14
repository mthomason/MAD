//
//  fontSettingsTableViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerFontSettingsViewController_h
#define Reports_MTReportDesignerFontSettingsViewController_h

#import <UIKit/UITableViewController.h>
#import "MADReportDesignerFontSelectorDelegateProtocol.h"
#import "MTToolboxViewControllerProtocol.h"
#import "MADFontSelectorViewController.h"
#import "MADToolboxDisplayProtocol.h"

@class MADocument;
@class MADToolboxStyleViewController;
@class MTFont;

@protocol MTReportDesignerFontSettingsDelegate

    - (void)fontSettingsTableViewControllerDidSelectFontList:(MADToolboxStyleViewController *)controller;

@end

@interface MADToolboxStyleViewController : UITableViewController
    <MADToolboxDisplayProtocol, MTToolboxViewControllerProtocol,
        MADReportDesignerFontSelectorDelegate>

    @property (nonatomic, weak) id <MTReportDesignerFontSettingsDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, weak) IBOutlet UILabel *labelFontName;
    @property (nonatomic, assign) BOOL clearsBackground;

@end

#endif
