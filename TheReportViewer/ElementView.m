//
//  DataObject.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "ElementView.h"
#import <QuartzCore/QuartzCore.h>
#import "CGGeometry+Extras.h"
#import "UIViewResizeHandle.h"

@implementation ElementView

@synthesize delegate = _delegate;
@synthesize containerView = _parentView;

@synthesize originalSize;
@synthesize stringElm;
@synthesize originalPointCenter;

- (void)dealloc {
    [_parentView release];
	if (stringElm != nil) {
		[stringElm release];
		stringElm = nil;
	}
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame inView:[self superview]];
}

- (id)initWithFrame:(CGRect)frame inView:(UIScrollView *)pview {
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setExclusiveTouch: YES];
        [self setMultipleTouchEnabled:YES];
        [self setContainerView: pview];
		originalSize = self.frame.size;
		
		largeSize.width = self.frame.size.width * 1.0000f;
		largeSize.height = self.frame.size.height * 1.0000f;
        
		[self setOpaque: YES];
        
        UIViewResizeHandle *resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(-15.0000f, -15.0000f, 30.0000f, 30.0000f)];
        [self addSubview:resizeButton];
        [resizeButton release];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextAddPath(currentContext, path);
    [[UIColor whiteColor] setFill];
    [[UIColor blackColor] setStroke];
    CGContextSetLineWidth(currentContext, 1.0000f);
    CGContextDrawPath(currentContext, kCGPathFillStroke);
    CGPathRelease(path);
    
}

#pragma mark Points and Sizes

- (CGPoint)topLeftPoint {
	return CGPointMake(self.frame.origin.x,
					   self.frame.origin.y);
}

- (CGPoint)topRightPoint {
	return CGPointMake(self.frame.origin.x + self.frame.size.width,
					   self.frame.origin.y);
}

- (CGPoint)bottomLeftPoint {
	return CGPointMake(self.frame.origin.x, self.frame.origin.y + self.frame.size.height);	
}

- (CGPoint)bottomRightPoint {
	return CGPointMake(self.frame.origin.x + self.frame.size.width, self.frame.origin.y + self.frame.size.height);
}

#pragma mark Touch events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    [self.containerView bringSubviewToFront:self];
    [self.containerView setScrollEnabled:NO];

    //[UIView beginAnimations:@"makeLarge" context:nil];
    //[UIView setAnimationDuration:0.1000f];
    //[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    //[self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, largeSize.width, largeSize.height)];
    //self.center = [[touches anyObject] locationInView: [self containerView]];
    //[UIView commitAnimations];
    //lastTime = [[touches anyObject] timestamp];
    //lastPoint = [[touches anyObject] locationInView: [self containerView]];
    //lastPoint.y *= -1;
    //currentPoint = [[touches anyObject] locationInView: [self containerView]];
    //currentPoint.y *= -1;
    
    NSLog(@"Touches Began: %@", NSStringFromCGRect( self.frame ));
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event { }

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

    //lastTimePlusOne = lastTime;
    //lastTime = currentTime;
    //currentTime = [[touches anyObject] timestamp];
    
    //lastPointPlusOne = lastPoint;
    //lastPoint = currentPoint;

    //currentPoint = [[touches anyObject] locationInView: [self containerView]];
    //currentPoint.y *= -1;
    
    self.center = [[touches anyObject] locationInView: [self containerView]];

    NSLog(@"Touches Moved ([[touches anyObject] locationInView: delegate view]): %@", NSStringFromCGPoint( [[touches anyObject] locationInView: [self containerView]] ));
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    //Make small
    CGPoint newCenter = [[touches anyObject] locationInView: [self containerView]];
    newCenter.x = roundf(newCenter.x);
    newCenter.y = roundf(newCenter.y);
    [UIView beginAnimations:@"touchesMoved" context:nil];
    [UIView setAnimationDuration:0.1000f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, originalSize.width, originalSize.height)];
    [self setCenter:newCenter];
	[UIView commitAnimations];

    [self.containerView setScrollEnabled:YES];
}

@end