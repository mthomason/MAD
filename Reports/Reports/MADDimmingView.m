//
//  MADDimmingView.m
//  MAD
//
//  Created by Michael Thomason on 11/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDimmingView.h"

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
        if (CGRectContainsPoint(normalized, point)) {  // Touched, nice
            hitview = foundView;
            break;
        }
    }
    
    if (hitview == nil) {
        if (self.passthroughContainer != nil) {
            hitview = self.passthroughContainer;
        } else {
            hitview = [super hitTest:point withEvent:event];
        }
    }

    return hitview;
}

@end
