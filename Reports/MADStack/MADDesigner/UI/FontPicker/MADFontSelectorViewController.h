//
//  UITableViewControllerFontSelector.h
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerFontSelectorViewController_h
#define Reports_MTReportDesignerFontSelectorViewController_h

#import "MADTableViewController.h"
#import "MADToolboxDisplayProtocol.h"

@class MADocument;
@class MADFontSelectorViewController;
@class MADFont;

@protocol MADReportDesignerFontSelectorDelegate;

@interface MADFontSelectorViewController : MADTableViewController
    <UITableViewDelegate, UITableViewDataSource, MADToolboxDisplayProtocol>

    @property (nonatomic, weak) id <MADReportDesignerFontSelectorDelegate> delegate;
    @property (nonatomic, assign) BOOL clearsBackground;

    - (void)setFamilyName:(NSString *)familyName;

@end

#endif
