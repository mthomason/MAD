//
//  MADToolboxTransitioner.h
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MADToolboxAnimatedTransitioningProtocol <NSObject>

- (void)performAnimations;

@end

@interface MADToolboxAnimatedTransitioning : NSObject <UIViewControllerAnimatedTransitioning>

    @property (nonatomic, weak) id <MADToolboxAnimatedTransitioningProtocol> delegate;
    @property (nonatomic, weak) UIView *passthroughContainer;
    @property (nonatomic, assign, getter=isToolboxVisible) BOOL toolboxVisible;

@end

@interface MADToolboxTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>

    @property (nonatomic, strong, readonly) UIPresentationController *presentationController;
    @property (nonatomic, assign, readonly) BOOL popoverStyle;

    //For popover view
    @property (nonatomic, assign) CGRect sourceRect;
    @property (nonatomic, weak) UIView *sourceView;
    @property (nonatomic, assign) UIPopoverArrowDirection permittedArrowDirections;

    @property (nonatomic, weak) UIView *container;
    @property (nonatomic, weak) UIView *passthroughContainer;
    @property (nonatomic, strong) NSSet *passthoughContainers;
    @property (nonatomic, strong) NSSet *passthroughViews;

    @property (nonatomic, weak) id <UIPopoverPresentationControllerDelegate> popoverPresentationControllerDelegate;

@end
