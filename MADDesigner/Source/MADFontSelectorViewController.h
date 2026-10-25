//
//  UITableViewControllerFontSelector.h
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTReportDesignerFontSelectorViewController_h
#define Reports_MTReportDesignerFontSelectorViewController_h

#import "MADToolboxDisplayProtocol.h"
#import <UIKit/UITableViewController.h>

@protocol MADReportDesignerFontSelectorDelegate;

@class MADocument;

@interface MADFontSelectorViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, MADToolboxDisplayProtocol>

@property (nonatomic, weak) id <MADReportDesignerFontSelectorDelegate> fontSelectorDelegate;
@property (nonatomic, assign) BOOL clearsBackground;

- (void)setFamilyName:(NSString *)familyName;

@end

#endif
