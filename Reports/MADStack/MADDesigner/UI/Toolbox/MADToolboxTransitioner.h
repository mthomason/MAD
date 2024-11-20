//
//  MADToolboxTransitioner.h
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADToolboxTransitioner_h
#define MAD_Designer_MADToolboxTransitioner_h

#import <UIKit/UIViewControllerTransitioning.h>
#import <UIKit/UIPopoverSupport.h>

@protocol UIPopoverPresentationControllerDelegate;

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
    @property (nonatomic, strong) NSSet *passthroughContainers;
    @property (nonatomic, strong) NSSet *passthroughViews;

    @property (nonatomic, weak) id <UIPopoverPresentationControllerDelegate> popoverPresentationControllerDelegate;

@end

#endif
