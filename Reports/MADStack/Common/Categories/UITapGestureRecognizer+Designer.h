//
//  UITapGestureRecognizer+Designer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/5/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIGestureRecognizer_Designer_h
#define Reports_UIGestureRecognizer_Designer_h

#import <UIKit/UITapGestureRecognizer.h>
#import <UIKit/UIPanGestureRecognizer.h>
#import <UIKit/UIPinchGestureRecognizer.h>


@interface MADTapGestureRecognizer : UITapGestureRecognizer

    + (instancetype)newTapGestureRecognizerSectionToggleWithTarget:(id)target
                                                            action:(SEL)action
                                                          delegate:(id<UIGestureRecognizerDelegate>)delegate;

    + (instancetype)newTapGestureRecognizerTapWithTarget:(id)target
                                                  action:(SEL)action
                                                delegate:(id<UIGestureRecognizerDelegate>)delegate;

    + (instancetype)newTapGestureRecognizerStrayTouchWithTarget:(id)target
                                                         action:(SEL)action
                                                       delegate:(id<UIGestureRecognizerDelegate>)delegate;

@end

@interface MADPanGestureRecognizer : UIPanGestureRecognizer

    + (instancetype)newPanGestureRecognizerElement:(id)target
                                            action:(SEL)action
                                          delegate:(id<UIGestureRecognizerDelegate>)delegate;

@end

@interface MADPinchGestureRecognizer : UIPinchGestureRecognizer

    + (instancetype)newPinchGestureRecognizerElement:(id)target
                                              action:(SEL)action
                                            delegate:(id<UIGestureRecognizerDelegate>)delegate;

@end

#endif
