//
//  MTQueryBuilderContainerController.h
//  MTQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderContainerController_h
#define Reports_MTQueryBuilderContainerController_h

#import <UIKit/UISplitViewController.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MUIViewControllerDelegate.h"
#import "MADTabBarItemProtocol.h"

@class UINavigationController;
@class MADQueryVisualizationViewController;
@class MADQueryViewController;
@class MADocument;

@interface MADQueryBuilderSplitViewController : UISplitViewController
    <MADViewControllerStandardProtocol,
        MADViewControllerDocumentProtocol,
        MADTabBarImageProtocol>

    + (instancetype)newQueryBuilderSplitViewController:(MADocument *)document;

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

    @property (readonly) UINavigationController *detailNavigationController;
    @property (readonly) MADQueryVisualizationViewController *queryBuilderControllerAdvanced;
    @property (readonly) MADQueryViewController *queryBuilderController;

@end

#endif
