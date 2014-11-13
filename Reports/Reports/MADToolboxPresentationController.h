//
//  MADToolboxPresentationController.h
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MADDimmingView;

@interface MADToolboxPresentationController : UIPresentationController

@property (nonatomic, assign) id <UIPopoverPresentationControllerDelegate> popoverPresentationControllerDelegate;
@property (nonatomic, strong) MADDimmingView *dimmingView;
@property (nonatomic, strong) UIView *passthroughContainer;
@property (nonatomic, strong) NSSet *passthroughContainers;
@property (nonatomic, strong) NSSet *passthroughViews;

- (BOOL)showOnSide;

@end
