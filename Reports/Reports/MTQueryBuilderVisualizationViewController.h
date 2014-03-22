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

@interface MTQueryBuilderVisualizationViewController : UIViewController

- (void)reloadActiveDocumentAnimatedAnimated:(BOOL)animated;
- (void)redraw;

@end

#endif
