//
//  MTQueryBuilderAdvancedViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderVisualizationViewController_h
#define Reports_MTQueryBuilderVisualizationViewController_h

#import <UIKit/UIKit.h>

@class MAReportDocument;

@interface MTQueryBuilderVisualizationViewController : UIViewController

@property (nonatomic, weak) MAReportDocument *document;

- (void)reloadDocument:(MAReportDocument *)documentReport animated:(BOOL)animated;
- (void)redraw;

@end

#endif
