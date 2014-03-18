//
//  UIViewControllerToolBox.h
//  Reports
//
//  Created by Michael Thomason on 1/28/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerToolBoxViewController_h
#define Reports_MTReportDesignerToolBoxViewController_h

#import <UIKit/UIKit.h>

@protocol MTReportDesignerToolBoxDelegate
- (void)toolboxHeightChanged:(CGFloat)newHeight;
- (void)hideToolbox;
@end

@interface MTReportDesignerToolBoxViewController : UIViewController

@property (nonatomic, assign) IBOutlet id <MTReportDesignerToolBoxDelegate> delegate;

- (void)showToolboxWithObjectIds:(NSSet *)objectIds;
- (IBAction)valueChanged:(id)sender;
- (CGFloat)contentHeight;

@end

#endif
