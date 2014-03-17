//
//  MTQueryBuilderContainerController.h
//  MTQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "MTViewControllerAsyncProtocol.h"
#import "MTQueryBuilderViewController.h"
#import "MTQueryBuilderAdvancedViewController.h"

@interface MTQueryBuilderContainerController : MTViewController
    <MTViewControllerProtocol>

@property (nonatomic, assign) id <MTViewControllerAsyncProtocol> delegateContentController;

- (MTQueryBuilderViewController *)queryBuilderController;
- (MTQueryBuilderAdvancedViewController *)queryBuilderControllerAdvanced;

@end
