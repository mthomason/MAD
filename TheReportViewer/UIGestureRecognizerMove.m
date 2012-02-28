//
//  UIGestureRecognizerMove.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/28/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIGestureRecognizerMove.h"

@implementation UIGestureRecognizerMove

/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //Animate the move to the touch
    CGPoint newCenter = [[touches anyObject] locationInView: [self containerView]];
    [UIView animateWithDuration: 0.2000f
                          delay: 0.0000f
                        options: UIViewAnimationOptionCurveLinear
                     animations: ^{
                         [self setCenter: newCenter];
                         [[self containerView] bringSubviewToFront: self];
                     } completion:^(BOOL finished) {
                         
                         //Don't animate the move outside of the goal, because it will jump around.
                         CGPoint outsideCenter = [[touches anyObject] locationInView: [self designerView]];
                         outsideCenter.x = roundf(outsideCenter.x);
                         outsideCenter.y = roundf(outsideCenter.y);
                         
                         [self setCurrentTime: [[touches anyObject] timestamp]];
                         [self setParentScrollersEnabled: NO];
                         
                         [self startWobble: 1];
                         
                         if (![[self designerView] isEqual:self]) {
                             [[self designerView] addSubview: self];
                         }
                         [self setCenter: outsideCenter];
                         [[self containerView] bringSubviewToFront: self];
                     }];
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    UIScrollView *newParent = (UIScrollView *)[[self hitTest:[self center] withEvent: nil] retain];
    if (newParent) {
        if (![newParent isEqual: self]) {
            [self setContainerView: newParent];
            [newParent addSubview: self];
        }
    }
    [newParent release];
    [self setParentScrollersEnabled: YES];
    [self stopWobble];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    self.lastTime = self.currentTime;
    self.currentTime = [[touches anyObject] timestamp];
    CGPoint newCenter = [[touches anyObject] locationInView: [self designerView]];
    [UIView animateWithDuration: (self.currentTime - self.lastTime)
                          delay: 0.0000f
                        options: UIViewAnimationOptionCurveLinear
                     animations: ^{
                         [self setCenter:newCenter];
                     } completion:^(BOOL finished) {
                         
                     }];
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.lastTime = self.currentTime;
    self.currentTime = [[touches anyObject] timestamp];
    
    CGPoint newCenter = [[touches anyObject] locationInView: [self designerView]];
    newCenter.x = roundf(newCenter.x);
    newCenter.y = roundf(newCenter.y);
    
    [UIView animateWithDuration: (self.currentTime - self.lastTime)
                          delay: 0.0000f
                        options: UIViewAnimationOptionCurveLinear
                     animations: ^{
                         [self setCenter:newCenter];
                     } completion:^(BOOL finished) {
                         UIScrollView *newParent = nil;
                         for (UIView *view in [[self designerView] subviews]) {
                             NSLog(@"%@ inside %@?", NSStringFromCGPoint([self center]), NSStringFromCGRect([view frame]));
                             if (CGRectContainsPoint([view frame], [self center]) && ![view isEqual:self]) {
                                 newParent = (UIScrollView *)[[view retain] autorelease];    //These should be the section views.
                             }
                         }
                         
                         if (newParent) {
                             if (![newParent isEqual: self]) {
                                 [self setContainerView: newParent];
                                 [newParent addSubview: self];
                             }
                         } else {
                             newParent = [[[self containerView] retain] autorelease];
                         }
                         
                         self.lastTime = self.currentTime;
                         self.currentTime = [[touches anyObject] timestamp];
                         
                         //Don't animate this, because of the change in views, the animation seems to jump.
                         CGPoint newCenter = [[touches anyObject] locationInView: newParent];
                         newCenter.x = roundf(newCenter.x);
                         newCenter.y = roundf(newCenter.y);
                         
                         [self setCenter: newCenter];
                         [self setParentScrollersEnabled: YES];
                         [self stopWobble];
                         
                     }];
}
*/

@end