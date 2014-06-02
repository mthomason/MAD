//
//  UIGestureRecognizer+AnchorPoint.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIGestureRecognizer_AnchorPoint_h
#define Reports_UIGestureRecognizer_AnchorPoint_h

#import <UIKit/UIKit.h>

@interface UIGestureRecognizer (AnchorPoint)

+ (CGPoint)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
+ (CGPoint)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer inView:(UIView *)containerView;

@end

#endif
