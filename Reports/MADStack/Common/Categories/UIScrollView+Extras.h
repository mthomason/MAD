//
//  UIScrollView+Extras.h
//  MAD
//
//  Created by Michael Thomason on 8/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (Extras)

- (CGRect)visibleRect;
- (void)positionForRectOfInterest:(CGRect)rectOfInterest withAdjustment:(CGFloat)adjustment;

@end
