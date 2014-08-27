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

@class MTQueryBuilderViewController,
        MTQueryBuilderVisualizationViewController,
        MADocument;

@interface MTQueryBuilderContainerController : UIViewController
    <MTViewControllerProtocol>

@property (nonatomic, weak) id <MTViewControllerProtocol> delegate;
@property (nonatomic, weak) MADocument *document;

- (MTQueryBuilderViewController *)queryBuilderController;
- (MTQueryBuilderVisualizationViewController *)queryBuilderControllerAdvanced;

@end

#endif
