//
//  UITapGestureRecognizer+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UITapGestureRecognizer+Designer.h"

@implementation UITapGestureRecognizer (Designer)

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

@end
