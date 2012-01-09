//
//  UIViewLasso.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewLasso.h"

@implementation UIViewLasso

- (void)drawRect:(CGRect)rect {
    [[UIColor blueColor] setStroke];

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    
    CGContextClosePath(context);
    
    [[UIColor blueColor] setStroke];

    CGContextDrawPath(context, kCGPathStroke);
}

@end