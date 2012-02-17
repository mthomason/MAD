//
//  UIViewResizeHandle.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/17/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewResizeHandle.h"

@implementation UIViewResizeHandle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
		CGFloat colors[] =
		{
			204.0 / 255.0, 224.0 / 255.0, 244.0 / 255.0, 1.00,
            29.0 / 255.0, 156.0 / 255.0, 215.0 / 255.0, 1.00,
            0.0 / 255.0,  50.0 / 255.0, 126.0 / 255.0, 1.00,
		};
		gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, sizeof(colors)/(sizeof(colors[0])*4));
		CGColorSpaceRelease(rgb);
        [self setBackgroundColor: [UIColor clearColor]];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {

    //CGMutablePathRef path = CGPathCreateMutable();
    //CGPathAddRect(path, NULL, rect);

CGContextRef currentContext = UIGraphicsGetCurrentContext();
    //CGContextClearRect(currentContext, rect);
    //CGContextAddArc (currentContext, .5, .5, .3, 0, 6.28318531, 0);

    //CGContextClosePath (currentContext);  //6.28318531 corresponds to 2*pi which is a whole circle
    //CGContextClip (currentContext);

    //    CGContextDrawLinearGradient(currentContext, gradient, CGPointZero, CGPointMake(CGPointZero.x, rect.size.height), 0);
    
    //[[UIColor whiteColor] setFill];
    //[[UIColor blackColor] setStroke];
    //CGContextSetLineWidth(currentContext, 1.0000f);
    //CGContextDrawPath(currentContext, kCGPathFillStroke);
    //CGPathRelease(path);
    
    
    // Use the clip bounding box, sans a generous border
	
	CGGradientDrawingOptions options = kCGGradientDrawsBeforeStartLocation;

    
			// A radial gradient requires a start & end point as well as a start & end radius.
			// Logically a radial gradient is created by linearly interpolating the center, radius and color of each
			// circle using the start and end point for the center, start and end radius for the radius, and the color ramp
			// inherant to the gradient to create a set of stroked circles that fill the area completely.
			// The gradient options specify if this interpolation continues past the start or end points as it does with
			// linear gradients.
    CGPoint start, end;
    CGFloat startRadius, endRadius;
    start = end = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
	CGFloat r = rect.size.width < rect.size.height ? rect.size.width : rect.size.height;
	startRadius = r * 0.0625;
	endRadius = r * 0.25;
    
    [[UIColor clearColor] setFill];
    CGContextDrawPath(currentContext, kCGPathFillStroke);

    CGContextDrawRadialGradient(currentContext, gradient, start, startRadius, end, endRadius, options);
//			CGContextRestoreGState(currentContext);
	
	// Show the clip rect
	//CGContextSetRGBStrokeColor(currentContext, 1.0, 0.0, 0.0, 1.0);
	//CGContextStrokeRectWithWidth(currentContext, rect, 2.0);

}

@end