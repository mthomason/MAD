//
//  MTQueryBuilderAdvancedViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTQueryBuilderAdvancedSchemaViewController.h"
#import "MTScrollViewCenter.h"
#import "MTViewController.h"

@interface MTQueryBuilderAdvancedViewController : UIViewController
    <UIGestureRecognizerDelegate,
        UIScrollViewDelegate,
        UIPopoverControllerDelegate,
        UICollisionBehaviorDelegate,
        MTQueryBuilderAdvancedSchemaDelegate,
        MTViewControllerProtocol>

- (void)reloadActiveDocumentAnimatedAnimated:(BOOL)animated;
- (void)redraw;

@end
