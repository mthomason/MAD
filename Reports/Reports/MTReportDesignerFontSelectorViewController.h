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
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFontAmericanTypewriter;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFontArial;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFontCourierNew;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFontCourier;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFontGeorgia;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFontHelvetica;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFontHelveticaNeue;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFontTimesNewRoman;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFontTrebuchet;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFontVerdana;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFontZapfino;

- (void)setSelectedFont:(MTFont *)font;

@end

#endif
