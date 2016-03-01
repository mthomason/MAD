//
//  UITableViewControllerFontSelector.h
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerFontSelectorViewController_h
#define Reports_MTReportDesignerFontSelectorViewController_h

#import "MADViewController.h"
#import "MADToolboxDisplayProtocol.h"

@class MADocument, MADFontSelectorViewController, MADFont;

@protocol MTReportDesignerFontSelectorDelegate
    - (void)uITableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName;
@end

@interface MADFontSelectorViewController : MADTableViewController
    <UITableViewDelegate, UITableViewDataSource, MADToolboxDisplayProtocol>

    @property (nonatomic, weak) id <MTReportDesignerFontSelectorDelegate> delegate;
    @property (nonatomic, assign) BOOL clearsBackground;

    - (void)setFamilyName:(NSString *)familyName;

@end

#endif
