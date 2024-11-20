//
//  UIViewResizeHandle.m
//  Reports
//
//  Created by Michael Thomason on 2/17/12.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADResizeHandleView.h"
#import <UIKit/UIGraphics.h>

@interface MADResizeHandleView()

@end

@implementation MADResizeHandleView

static const CGFloat colors[] = {
    204.0 / 255.0, 224.0 / 255.0, 244.0 / 255.0, 1.0,
    29.0 / 255.0, 156.0 / 255.0, 215.0 / 255.0, 1.0,
    0.0 / 255.0,  50.0 / 255.0, 126.0 / 255.0, 1.0,
};

- (instancetype)initWithFrame:(CGRect)frame andType:(MADCompassDirection)position {

    if (self = [self initWithFrame:frame]) {

        self.initalPoint = self.center;
        self.type = position;
        self.highlighted = NO;
        self.backgroundColor =  [UIColor clearColor];

    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect: rect];

    CGContextRef currentContext = UIGraphicsGetCurrentContext();
	CGGradientDrawingOptions options = kCGGradientDrawsBeforeStartLocation;

    CGPoint start, end;
    CGFloat startRadius, endRadius;
    start = end = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
	CGFloat r = rect.size.width < rect.size.height ? rect.size.width : rect.size.height;
	startRadius = r * (0.50 / 8.0);
	endRadius = r * 0.25;
    
    [[UIColor clearColor] setFill];
    CGContextDrawPath(currentContext, kCGPathFillStroke);
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, sizeof(colors)/(sizeof(colors[0])*4));
    CGContextDrawRadialGradient(currentContext, gradient, start, startRadius, end, endRadius, options);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(rgb);
}

@end
