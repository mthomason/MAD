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

- (CGRect)visableRect {
    CGRect visibleRect;
    visibleRect.origin = self.contentOffset;
    visibleRect.size = self.bounds.size;
    return CGRectAdjustForScale(visibleRect, self.zoomScale);
}

@end
