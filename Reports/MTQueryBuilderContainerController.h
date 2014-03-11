//
//  MTQueryBuilderContainerController.h
//  MTQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTQueryBuilderViewController.h"
#import "MTQueryBuilderAdvancedViewController.h"
#import "MTViewControllerAsyncProtocol.h"

@interface MTQueryBuilderContainerController : MTViewController
    <MTViewControllerProtocol>

@property (nonatomic, assign) id <MTViewControllerAsyncProtocol> delegateContentController;

- (MTQueryBuilderViewController *)queryBuilderController;
- (MTQueryBuilderAdvancedViewController *)queryBuilderControllerAdvanced;

@end
