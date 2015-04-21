//
//  UIScrollView+Extras.m
//  MAD
//
//  Created by Michael Thomason on 8/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIScrollView+Extras.h"
#import "CGGeometry+Extras.h"

@implementation UIScrollView (Extras)

- (CGRect)visibleRect {
    CGRect visibleRect;
    visibleRect.origin = self.contentOffset;
    visibleRect.size = self.bounds.size;
    return CGRectAdjustForScale(visibleRect, self.zoomScale);
}

- (void)positionForRectOfInterest:(CGRect)rectOfInterest withAdjustment:(CGFloat)adjustment {
    
    CGRect visibleRect = [self visibleRect];
    CGRect visableRectAdjusted = CGRectMake(CGPointZero.x - (CGFLOAT_MAX / 2.0000f),
                                            visibleRect.origin.y + adjustment,
                                            CGFLOAT_MAX,
                                            visibleRect.size.height);
    CGRect rectOfInterestAdjusted = CGRectMake(rectOfInterest.origin.x,
                                               rectOfInterest.origin.y + adjustment,
                                               rectOfInterest.size.width,
                                               rectOfInterest.size.height);
    if (CGRectContainsRect(visableRectAdjusted, rectOfInterestAdjusted) == NO) {
        CGPoint contentOffset = CGPointContentOffsetBottomOfRect(rectOfInterest, visibleRect);
        contentOffset = CGPointMake(contentOffset.x, contentOffset.y * self.zoomScale);
        [self setContentOffset:contentOffset animated:YES];
    }
}

@end
