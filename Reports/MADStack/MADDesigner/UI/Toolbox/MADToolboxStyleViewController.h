//
//  fontSettingsTableViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerFontSettingsViewController_h
#define Reports_MTReportDesignerFontSettingsViewController_h

#import <UIKit/UITableViewController.h>
#import "MADReportDesignerFontSelectorDelegateProtocol.h"
#import "MADToolboxControllerProtocol.h"
#import "MADFontSelectorViewController.h"
#import "MADToolboxDisplayProtocol.h"
#import "MADViewControllerDocumentProtocol.h"

@class MADocument, MADToolboxStyleViewController, MTFont;
@protocol MADDesignerDisplayProtocol;

@protocol MADReportDesignerFontSettingsDelegate

    - (void)fontSettingsTableViewControllerDidSelectFontList:(MADToolboxStyleViewController *)controller;

@end

@interface MADToolboxStyleViewController : UITableViewController
    <MADToolboxDisplayProtocol, MADToolboxControllerProtocol,
        MADReportDesignerFontSelectorDelegate, MADViewControllerDocumentProtocol>

    @property (nonatomic, weak) id <MADReportDesignerFontSettingsDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, weak) IBOutlet UILabel *labelFontName;
    @property (nonatomic, assign) BOOL clearsBackground;

@end

#endif
