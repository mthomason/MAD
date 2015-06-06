//
//  UITapGestureRecognizer+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UITapGestureRecognizer+Designer.h"

@implementation UIGestureRecognizer (Designer)

+ (instancetype)sectionToggleWithTarget:(id)target
                                 action:(SEL)action
                               delegate:(id<UIGestureRecognizerDelegate>)delegate {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: target action: action];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.delaysTouchesBegan = YES;
    tap.delaysTouchesEnded = NO;
    tap.delegate = delegate;
    return tap;
}

+ (instancetype)elementTouchWithTarget:(id)target
                                action:(SEL)action
                              delegate:(id<UIGestureRecognizerDelegate>)delegate {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: target action: action];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.delaysTouchesBegan = YES;
    tap.delaysTouchesEnded = NO;
    tap.delegate = delegate;
    return tap;
}

+ (instancetype)strayTouchWithTarget:(id)target
                              action:(SEL)action
                            delegate:(id<UIGestureRecognizerDelegate>)delegate {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: target action: action];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.delegate = delegate;
    tap.delaysTouchesBegan = YES;
    return tap;
}

+ (instancetype)elementPan:(id)target
                    action:(SEL)action
                  delegate:(id<UIGestureRecognizerDelegate>)delegate {
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget: target
                                                                                 action: action];
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 2;
    panGesture.delegate = delegate;
    return panGesture;
}

+ (instancetype)elementPinch:(id)target
                      action:(SEL)action
                    delegate:(id<UIGestureRecognizerDelegate>)delegate {
    UIPinchGestureRecognizer *panGesture = [[UIPinchGestureRecognizer alloc] initWithTarget: target
                                                                                     action: action];
    panGesture.delegate = delegate;
    return panGesture;
}

@end
