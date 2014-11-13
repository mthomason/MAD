//
//  MADDimmingView.m
//  MAD
//
//  Created by Michael Thomason on 11/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDimmingView.h"
#import "MADBackgroundScrollView.h"
@implementation MADDimmingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIColor *backgroundColor = [UIColor colorWithWhite: 0.0000f
                                                     alpha: 0.3333f];
        self.backgroundColor = backgroundColor;
        self.alpha = 0.0000f;
        
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id hitview = nil;
    for (UIView *foundView in self.passthoughViews) {
        CGRect normalized = [self convertRect: foundView.frame
                                     fromView: foundView];

        if (CGRectContainsPoint(normalized, point)) {
            
            CGRect visibleRect = [self.passthroughContainer convertRect: self.passthroughContainer.bounds
                                                                 toView: ((MADBackgroundScrollView *)self.passthroughContainer).container];
            if (CGRectContainsPoint(visibleRect, point)) {
                hitview = foundView;
                goto shortThisB;
                break;
            }
        }
    }
    
    if (hitview == nil) {
        
        for (UIView *v in self.passthoughContainers) {
            CGRect normalized = [self.passthroughContainer convertRect: v.frame
                                                              fromView:v];
            CGPoint normalizedPoint = [v convertPoint: point
                                               toView: self.passthroughContainer];
            if (CGRectContainsPoint(normalized, normalizedPoint)) {
                hitview = v;
                goto shortThisB;
                break;
            }
        }
        
        if (hitview == nil && self.passthroughContainer != nil) {
            hitview = self.passthroughContainer;
        } else if (hitview == nil) {
            hitview = [super hitTest:point withEvent:event];
        }
    }
shortThisB:
    return hitview;
}

@end
