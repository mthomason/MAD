//
//  UITapGestureRecognizer+Designer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIGestureRecognizer_Designer_h
#define Reports_UIGestureRecognizer_Designer_h

#import <UIKit/UIKit.h>

@interface UIGestureRecognizer (Designer)

+ (instancetype)sectionToggleWithTarget:(id)target
                                 action:(SEL)action
                               delegate:(id<UIGestureRecognizerDelegate>)delegate;

+ (instancetype)elementTouchWithTarget:(id)target
                                action:(SEL)action
                              delegate:(id<UIGestureRecognizerDelegate>)delegate;

+ (instancetype)strayTouchWithTarget:(id)target
                              action:(SEL)action
                            delegate:(id<UIGestureRecognizerDelegate>)delegate;

+ (instancetype)elementPan:(id)target
                    action:(SEL)action
                  delegate:(id<UIGestureRecognizerDelegate>)delegate;

+ (instancetype)elementPinch:(id)target
                      action:(SEL)action
                    delegate:(id<UIGestureRecognizerDelegate>)delegate;

@end

#endif
