//
//  UITableViewControllerFontSelector.h
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerFontSelectorViewController_h
#define Reports_MTReportDesignerFontSelectorViewController_h

#import <UIKit/UIKit.h>
#import "MTFont.h"

@class MTReportDesignerFontSelectorViewController;

@protocol MTReportDesignerFontSelectorDelegate
- (void)uITableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName;
@end

@interface MTReportDesignerFontSelectorViewController : UITableViewController
    <UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <MTReportDesignerFontSelectorDelegate> delegate;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFontAmericanTypewriter;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFontArial;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFontCourierNew;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFontCourier;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFontGeorgia;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFontHelvetica;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFontHelveticaNeue;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFontTimesNewRoman;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFontTrebuchet;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFontVerdana;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFontZapfino;

- (void)setSelectedFont:(MTFont *)font;

@end

#endif
