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
#import "MTViewController.h"
#import "MTViewControllerAsyncProtocol.h"

@class MTQueryBuilderViewController, MTQueryBuilderVisualizationViewController;

@interface MTQueryBuilderContainerController : MTViewController
    <MTViewControllerProtocol>

@property (nonatomic, assign) id <MTViewControllerAsyncProtocol> delegateContentController;

- (MTQueryBuilderViewController *)queryBuilderController;
- (MTQueryBuilderVisualizationViewController *)queryBuilderControllerAdvanced;

@end

#endif
