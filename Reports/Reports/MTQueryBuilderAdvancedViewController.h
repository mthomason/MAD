//
//  MTQueryBuilderAdvancedViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqTable+Extras.h"
#import "RptqDocument+ActiveDocument.h"
#import "MTQueryBuilderAdvancedSchemaViewController.h"
#import "UIColor+EverydayApps.h"
#import "UIGestureRecognizer+AnchorPoint.h"
#import "UIView+NSObjectIdTag.h"
#import "CGGeometry+Extras.h"
#import "UIColor+PaperPatterns.h"
#import "MTScrollViewCenter.h"

@interface MTQueryBuilderAdvancedViewController : UIViewController
    <UIGestureRecognizerDelegate, UIScrollViewDelegate, MTQueryBuilderAdvancedSchemaDelegate>

- (void)reloadDocument:(MTReportDocument *)documentReport;

@end
