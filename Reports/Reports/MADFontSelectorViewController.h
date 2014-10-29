//
//  UITableViewControllerFontSelector.h
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerFontSelectorViewController_h
#define Reports_MTReportDesignerFontSelectorViewController_h

#import <UIKit/UIKit.h>

@class MADocument, MADFontSelectorViewController, MTFont;

@protocol MTReportDesignerFontSelectorDelegate
- (void)uITableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName;
@end

@interface MADFontSelectorViewController : UITableViewController
    <UITableViewDelegate>

@property (nonatomic, weak) IBOutlet id <MTReportDesignerFontSelectorDelegate> delegate;
@property (nonatomic, weak) MADocument *document;

@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFontAmericanTypewriter;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFontArial;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFontCourierNew;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFontCourier;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFontGeorgia;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFontHelvetica;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFontHelveticaNeue;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFontTimesNewRoman;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFontTrebuchet;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFontVerdana;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFontZapfino;

- (void)setSelectedFont:(MTFont *)font;

@end

#endif
