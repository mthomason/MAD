//
//  UILabelStrikethrough.m
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADLabelStrikethrough.h"
#import <UIKit/UIGraphics.h>

@implementation MADLabelStrikethrough

- (void)drawRect:(CGRect)rect {
    [super drawRect: rect];
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    CGFloat red[4] = {1.0f, 0.0f, 0.0f, 1.0f};
    CGContextSetStrokeColor(c, red);
    CGContextBeginPath(c);
    CGContextMoveToPoint(c, 5.0f, 5.0f);
    CGContextAddLineToPoint(c, 50.0f, 50.0f);
    CGContextStrokePath(c);
}

@end
