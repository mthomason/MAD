//
//  UIView+Extras.m
//  MAD
//
//  Created by Michael Thomason on 8/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIView+Extras.h"

@implementation UIView (Extras)

- (CGRect)popoverRectForSelectedViews:(NSSet *)views {
    CGRect result;
    if (views.count == 0) {
        result = CGRectZero;
    } else if (views.count == 1) {
        UIView *elementView = [views anyObject];
        result = [elementView convertRect:[elementView frame] toView:self];
    } else {
        CGFloat minx = CGPointZero.x, miny = CGPointZero.y, maxx = CGPointZero.x, maxy = CGPointZero.y;
        NSUInteger counter = 0;
        for (UIView *elementView in views) {
            CGRect frame = [elementView convertRect:[elementView frame] toView:self];
            if (counter == 0) {
                minx = frame.origin.x;
                miny = frame.origin.y;
                maxx = frame.origin.x + frame.size.width;
                maxy = frame.origin.y + frame.size.height;
            } else {
                minx = minx < frame.origin.x ? minx : frame.origin.x;
                miny = miny < frame.origin.y ? miny : frame.origin.y;
                maxx = maxx > frame.origin.x + frame.size.width ? maxx : frame.origin.x + frame.size.width;
                maxy = maxy > frame.origin.y + frame.size.height ? maxy : frame.origin.y + frame.size.height;
            }
            counter++;
        }
        result = CGRectMake(minx, miny, maxx - minx, maxy - miny);
    }
    return result;
}

@end
