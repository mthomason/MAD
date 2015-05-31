//
//  UIView+Animations.m
//  Reports
//
//  Created by Michael Thomason on 2/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIView+Animations.h"

#define degreesToRadians(x) (M_PI * (x) / 180.0)
CGFloat const MTAnimationRotateDeg = 1.0000f;

@implementation UIView (Animations)

- (void)startWobble {
    [self.layer removeAllAnimations];
    NSInteger randomInt = arc4random() % 500;
    float r = (randomInt / 500.0000f) + 0.5000f;
    CGAffineTransform leftWobble = CGAffineTransformMakeRotation(degreesToRadians( (MTAnimationRotateDeg * -1.0) - r ));
    CGAffineTransform rightWobble = CGAffineTransformMakeRotation(degreesToRadians( MTAnimationRotateDeg + r ));
    [self setTransform: leftWobble];
    
    [self.layer setAnchorPoint:CGPointMake(0.5, 0.5)];

    __block UIView *v = self;
    [UIView animateWithDuration:0.3500
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                     animations:^{
                         [UIView setAnimationRepeatCount:NSNotFound];
                         v.transform = rightWobble;
                         v = nil;
                     }
                     completion:nil];
    
}

- (void)stopWobble {
    [self.layer removeAllAnimations];
    self.transform = CGAffineTransformIdentity;
}

@end
