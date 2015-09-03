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

@class MADocument;

@interface MADQueryVisualizationViewController : UIViewController

@property (nonatomic, weak) MADocument *document;

- (void)redraw;

@end

#endif
