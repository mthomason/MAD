//
//  UIViewResizeHandle.m
//  Reports
//
//  Created by Michael Thomason on 2/17/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADResizeHandleView.h"
#import <UIKit/UIGraphics.h>

@interface MADResizeHandleView()

@end

@implementation MADResizeHandleView

static const CGFloat colors[] = {
    204.0000f / 255.0000f, 224.0000f / 255.0000f, 244.0000f / 255.0000f, 1.00000f,
    29.0000f / 255.0000f, 156.0000f / 255.0000f, 215.0000f / 255.0000f, 1.00000f,
    0.0000f / 255.0000f,  50.0000f / 255.0000f, 126.0000f / 255.0000f, 1.00000f,
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
	startRadius = r * 0.06250f;
	endRadius = r * 0.2500f;
    
    [[UIColor clearColor] setFill];
    CGContextDrawPath(currentContext, kCGPathFillStroke);
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, sizeof(colors)/(sizeof(colors[0])*4));
    CGContextDrawRadialGradient(currentContext, gradient, start, startRadius, end, endRadius, options);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(rgb);
}

@end
