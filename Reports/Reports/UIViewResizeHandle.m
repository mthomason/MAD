//
//  UIViewResizeHandle.m
//  Reports
//
//  Created by Michael Thomason on 2/17/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewResizeHandle.h"

@implementation UIViewResizeHandle

@synthesize delegate = _delegate;
@synthesize type = _type;
@synthesize initalPoint = _initalPoint;
@synthesize highlighted = _highlighted;

- (id)initWithFrame:(CGRect)frame andType:(MNSCompusPosition)position {
    self = [super initWithFrame:frame];
    if (self) {
        //NSLog(@"Inital Point: %@", NSStringFromCGPoint( [self center] ));

        [self setInitalPoint:[self center]];
        [self setType: position];
        [self setHighlighted: NO];
        // Initialization code
		CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
		CGFloat colors[] = {
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

    CGContextDrawRadialGradient(currentContext, gradient, start, startRadius, end, endRadius, options);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touches Began: %@", NSStringFromCGRect( self.frame ));
    NSLog(@"Touches A: %@", NSStringFromCGPoint( [[touches anyObject] locationInView: [self superview]] ));
    [self setHighlighted: YES];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setHighlighted: NO];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touches A: %@", NSStringFromCGPoint( [[touches anyObject] locationInView: [self superview]] ));    
        
    CGPoint pointAfterMove = [self center];
    switch ([self type]) {
        case west:
            pointAfterMove = CGPointMake([[touches anyObject] locationInView: [self superview]].x, [self initalPoint].y);
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
    [[self delegate] resizeHandle:self didMoveToPoint:pointAfterMove];

    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setHighlighted: NO];
}

@end