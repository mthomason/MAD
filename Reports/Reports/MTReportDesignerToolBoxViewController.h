//
//  UIViewControllerToolBox.h
//  Reports
//
//  Created by Michael Thomason on 1/28/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTReportDesignerFontSettingsViewController.h"
#import "MTReportDesignerFontSelectorViewController.h"

@protocol MTReportDesignerToolBoxDelegate
- (void)heightChanged:(CGFloat)newHeight;
- (void)hideToolbox;
@end

@interface MTReportDesignerToolBoxViewController : UIViewController
    <UINavigationBarDelegate, MTReportDesignerFontSettingsDelegate,
        MTReportDesignerFontSelectorDelegate>

@property (assign, nonatomic) IBOutlet id <MTReportDesignerToolBoxDelegate> delegate;
- (void)showToolboxWithObjectIds:(NSSet *)objectIds;
- (void)setFontDelegates:(id)delegate;
- (IBAction)valueChanged:(id)sender;
- (CGFloat)contentHeight;

@end