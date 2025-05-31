//
//  UITableViewControllerFontSelector.h
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTReportDesignerFontSelectorViewController_h
#define Reports_MTReportDesignerFontSelectorViewController_h

#import <UIKit/UITableViewController.h>
#import "MADToolboxDisplayProtocol.h"

@protocol MADReportDesignerFontSelectorDelegate;

@class MADocument;

@interface MADFontSelectorViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, MADToolboxDisplayProtocol>

@property (nonatomic, weak) id <MADReportDesignerFontSelectorDelegate> delegate;
@property (nonatomic, assign) BOOL clearsBackground;

- (void)setFamilyName:(NSString *)familyName;

@end

#endif
