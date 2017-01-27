//
//  UIGestureRecognizer+AnchorPoint.m
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIGestureRecognizer+AnchorPoint.h"
#import <CoreGraphics/CGBase.h>
#import <UIKit/UIView.h>
#import <QuartzCore/CALayer.h>

@implementation UIGestureRecognizer (AnchorPoint)

+ (CGPoint)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint result = CGPointZero;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
        gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        CGPoint anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width,
                                          locationInView.y / piece.bounds.size.height);
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            piece.layer.anchorPoint = anchorPoint;
            piece.center = locationInSuperview;
        }
        result = locationInSuperview;
    }
    return result;
}

+ (CGPoint)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
                                          inView:(UIView *)containerView {
    CGPoint result = CGPointZero;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
        gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint locationInView = [gestureRecognizer locationInView:containerView];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:containerView.superview];
        
        CGPoint anchorPoint = CGPointMake(locationInView.x / containerView.bounds.size.width, locationInView.y / containerView.bounds.size.height);
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            containerView.layer.anchorPoint = anchorPoint;
            containerView.center = locationInSuperview;
        }
        result = locationInSuperview;
    }
    return result;
}

@end
