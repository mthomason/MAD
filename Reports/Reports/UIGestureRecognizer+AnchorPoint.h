//
//  UIGestureRecognizer+AnchorPoint.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
@interface UIGestureRecognizer (AnchorPoint)

+ (CGPoint)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
+ (CGPoint)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer inView:(UIView *)containerView;

@end
