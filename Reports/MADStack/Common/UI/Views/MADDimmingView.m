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
    UIView *container = _container,
           *foundView;
    CGPoint pointNormalized = [container convertPoint: point fromView: self];
    CGRect rectNormalized;
    
    NSSet *passthroughViews = self.passthroughViews;
    for (foundView in passthroughViews) {
        
        rectNormalized = [foundView convertRect: foundView.bounds
                                         toView: container];

        if (CGRectContainsPoint(rectNormalized, pointNormalized)) {
            
            hitview = foundView;
            goto shortThisB;
            break;
        }
    }
    
    if (hitview == nil) {
        UIView *passthroughContainer;
        NSSet *passthroughContainers = self.passthroughContainers;
        for (passthroughContainer in passthroughContainers) {
            rectNormalized = [passthroughContainer convertRect: passthroughContainer.bounds
                                                        toView: container];
            if (CGRectContainsPoint(rectNormalized, pointNormalized)) {
                hitview = passthroughContainer;
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
