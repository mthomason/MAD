//
//  MADToolboxPresentationController.h
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADToolboxPresentationController_h
#define Reports_MADToolboxPresentationController_h

#import <UIKit/UIKit.h>

@class MADDimmingView;

@interface MADToolboxPresentationController : UIPresentationController

    @property (nonatomic, weak) id <UIPopoverPresentationControllerDelegate> popoverPresentationControllerDelegate;
    @property (nonatomic, strong) MADDimmingView *dimmingView;
    @property (nonatomic, weak) UIView *container;
    @property (nonatomic, strong) UIView *passthroughContainer;
    @property (nonatomic, strong) NSSet *passthroughContainers;
    @property (nonatomic, strong) NSSet *passthroughViews;

    - (BOOL)showOnSide;

@end

#endif
