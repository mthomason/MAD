//
//  MADToolboxTransitioner.h
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MADToolboxAnimatedTransitioning : NSObject <UIViewControllerAnimatedTransitioning>

    @property (nonatomic, assign, getter=isToolboxVisible) BOOL toolboxVisible;

@end

@interface MADToolboxTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>

    //For popover view
    @property (nonatomic, assign) CGRect sourceRect;
    @property (nonatomic, strong) UIView *sourceView;
    @property (nonatomic, assign) UIPopoverArrowDirection permittedArrowDirections;

    @property (nonatomic, strong) UIView *passthroughContainer;
    @property (nonatomic, strong) NSSet *passthroughViews;

    @property (nonatomic, assign) id <UIPopoverPresentationControllerDelegate> popoverPresentationControllerDelegate;


@end
