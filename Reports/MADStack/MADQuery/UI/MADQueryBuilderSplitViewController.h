//
//  MTQueryBuilderContainerController.h
//  MTQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderContainerController_h
#define Reports_MTQueryBuilderContainerController_h

#import "MADSplitViewController.h"
#import "MADocumentProtocol.h"
#import "MUIViewControllerDelegate.h"

@class MADQueryVisualizationViewController;
@class MADQueryViewController;
@class MADocument;

@interface MADQueryBuilderSplitViewController : MADSplitViewController
    <MTViewControllerProtocol,
        MADViewControllerDocumentProtocol>

    + (instancetype)newQueryBuilderSplitViewController;

    @property (nonatomic, weak) id <MTViewControllerProtocol> viewControllerDelegate;

    @property (readonly) UINavigationController *detailNavigationController;
    @property (readonly) MADQueryVisualizationViewController *queryBuilderControllerAdvanced;
    @property (readonly) MADQueryViewController *queryBuilderController;

@end

#endif
