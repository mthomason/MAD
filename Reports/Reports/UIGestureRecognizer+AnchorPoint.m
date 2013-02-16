//
//  UIGestureRecognizer+AnchorPoint.m
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "UIGestureRecognizer+AnchorPoint.h"

@implementation UIGestureRecognizer (AnchorPoint)

+ (CGPoint)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint result = CGPointZero;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
        gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        CGPoint anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            piece.layer.anchorPoint = anchorPoint;
            piece.center = locationInSuperview;
        }
        result = locationInSuperview;
    }
    return result;
}

@end
