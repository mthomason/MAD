//
//  UIViewResizeHandle.m
//  Reports
//
//  Created by Michael Thomason on 2/17/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTResizeHandleView.h"

@implementation MTResizeHandleView

- (instancetype)initWithFrame:(CGRect)frame andType:(MADCompusDirection)position {
    self = [super initWithFrame:frame];
    if (self) {

        self.initalPoint = self.center;
        self.type = position;
        self.highlighted = NO;

        // Initialization code
		CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
		CGFloat colors[] = {
			204.0000f / 255.0000f, 224.0000f / 255.0000f, 244.0000f / 255.0000f, 1.00000f,
            29.0000f / 255.0000f, 156.0000f / 255.0000f, 215.0000f / 255.0000f, 1.00000f,
            0.0000f / 255.0000f,  50.0000f / 255.0000f, 126.0000f / 255.0000f, 1.00000f,
		};
		_gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, sizeof(colors)/(sizeof(colors[0])*4));
		CGColorSpaceRelease(rgb);
        self.backgroundColor =  [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {

    CGContextRef currentContext = UIGraphicsGetCurrentContext();
	CGGradientDrawingOptions options = kCGGradientDrawsBeforeStartLocation;

    CGPoint start, end;
    CGFloat startRadius, endRadius;
    start = end = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
	CGFloat r = rect.size.width < rect.size.height ? rect.size.width : rect.size.height;
	startRadius = r * 0.0625;
	endRadius = r * 0.25;
    
    [[UIColor clearColor] setFill];
    CGContextDrawPath(currentContext, kCGPathFillStroke);

    CGContextDrawRadialGradient(currentContext, _gradient, start, startRadius, end, endRadius, options);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.highlighted = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.highlighted = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint pointAfterMove = [self center];
    switch (self.type) {
        case west:
            pointAfterMove = CGPointMake([touches.anyObject locationInView: self.superview].x, self.initalPoint.y);
            break;
        case northWest:
            break;
        case north:
            break;
        case northEast:
            break;
        case east:
            break;
        case southEast:
            break;
        case south:
            break;
        case southWest:
            break;
        default:
            break;
    }
    [self.delegate resizeHandle:self didMoveToPoint:pointAfterMove];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setHighlighted: NO];
}

@end
