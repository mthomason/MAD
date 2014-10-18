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
#import "MUIViewControllerDelegate.h"

@class MADQueryViewController,
        MADQueryVisualizationViewController,
        MADocument;

@interface MTQueryBuilderContainerController : UISplitViewController
    <MTViewControllerProtocol>

@property (nonatomic, weak) id <MTViewControllerProtocol> viewControllerDelegate;
@property (nonatomic, weak) MADocument *document;

@property (nonatomic, strong) MADQueryViewController *queryBuilderController;
@property (nonatomic, strong) MADQueryVisualizationViewController *queryBuilderControllerAdvanced;

@end

#endif
