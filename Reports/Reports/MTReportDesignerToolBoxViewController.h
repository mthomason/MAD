//
//  UIViewControllerToolBox.h
//  Reports
//
//  Created by Michael Thomason on 1/28/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerToolBoxViewController_h
#define Reports_MTReportDesignerToolBoxViewController_h

#import <UIKit/UIKit.h>
#import "MTReportDesignerFontSettingsViewController.h"
#import "MTReportDesignerFontSelectorViewController.h"
#import "MTReportDesignerDocumentObjectFormat.h"
#import "RptqDocumentObject+Extras.h"

@protocol MTReportDesignerToolBoxDelegate
- (void)heightChanged:(CGFloat)newHeight;
- (void)hideToolbox;
@end

@interface MTReportDesignerToolBoxViewController : UIViewController
    <UINavigationBarDelegate, MTReportDesignerFontSettingsDelegate,
        MTReportDesignerFontSelectorDelegate>

@property (nonatomic, assign) IBOutlet id <MTReportDesignerToolBoxDelegate> delegate;
//@property (nonatomic, retain) MTApplicaitonInstance *applicationInstance;

- (void)showToolboxWithObjectIds:(NSSet *)objectIds;
- (IBAction)valueChanged:(id)sender;
- (CGFloat)contentHeight;

@end

#endif
