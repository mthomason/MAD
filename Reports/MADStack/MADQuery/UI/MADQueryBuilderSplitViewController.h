//
//  MTQueryBuilderContainerController.h
//  MTQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderContainerController_h
#define Reports_MTQueryBuilderContainerController_h

#import <UIKit/UIKit.h>
#import "MADocumentProtocol.h"
#import "MUIViewControllerDelegate.h"
#import "MADViewController.h"

@class MADQueryViewController,
        MADQueryVisualizationViewController,
        MADocument;

@interface MADQueryBuilderSplitViewController : MADSplitViewController
    <MTViewControllerProtocol, MADViewControllerDocumentProtocol>

@property (nonatomic, weak) id <MTViewControllerProtocol> viewControllerDelegate;
@property (nonatomic, weak) MADocument *document;

@property (readonly) UINavigationController *detailNavigationController;
@property (readonly) MADQueryVisualizationViewController *queryBuilderControllerAdvanced;
@property (readonly) MADQueryViewController *queryBuilderController;

@end

#endif
