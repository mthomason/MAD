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

@synthesize stringElm = _stringElm;
@synthesize originalSize = _originalSize, originalPointCenter = _originalPointCenter;
@synthesize currentTime = _currentTime, lastTime = _lastTime;

@synthesize handleEdgeRight = _handleEdgeRight, handleEdgeLeft = _handleEdgeLeft, handleEdgeTop = _handleEdgeTop, handleEdgeBottom = _handleEdgeBottom, handleCornerTopLeft = _handleCornerTopLeft, handleCornerTopRight = _handleCornerTopRight, handleCornerBottomLeft = _handleCornerBottomLeft, handleCornerBottomRight = _handleCornerBottomRight;

- (void)dealloc {
    [_handleCornerBottomLeft release];
    [_handleCornerBottomRight release];
    [_handleCornerTopLeft release];
    [_handleCornerTopRight release];
    [_handleEdgeBottom release];
    [_handleEdgeLeft release];
    [_handleEdgeRight release];
    [_handleEdgeTop release];
    [_parentView release];
    [_stringElm release];
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame inView:(UIScrollView *)pview {
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setExclusiveTouch: YES];
        [self setMultipleTouchEnabled:YES];
        [self setContainerView: pview];
		self.originalSize = self.frame.size;
        
		[self setOpaque: YES];
        
        CGSize handleSize = CGSizeMake(30.0000f, 30.0000f);

        UIViewResizeHandle *resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:northWest];
        [resizeButton setCenter: CGCornerTopLeftPointInRect(frame)];
        [self addSubview:resizeButton];
        [self setHandleCornerTopLeft: resizeButton];
        [resizeButton release];
        resizeButton = nil;

        resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:northEast];
        [resizeButton setCenter: CGCornerTopRightPointInRect(frame)];
        [self addSubview:resizeButton];
        [self setHandleCornerTopRight: resizeButton];
        [resizeButton release];
        resizeButton = nil;

        resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:southEast];
        [resizeButton setCenter: CGCornerBottomRightPointInRect(frame)];
        [self addSubview:resizeButton];
        [self setHandleCornerBottomRight: resizeButton];
        [resizeButton release];
        resizeButton = nil;

        resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:southWest];
        [resizeButton setCenter: CGCornerBottomLeftPointInRect(frame)];
        [self addSubview:resizeButton];
        [self setHandleCornerBottomLeft: resizeButton];
        [resizeButton release];
        resizeButton = nil;

        resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:north];
        [resizeButton setCenter: CGEdgeTopPointInRect(frame)];
        [self addSubview:resizeButton];
        [self setHandleEdgeTop: resizeButton];
        [resizeButton release];
        resizeButton = nil;

        resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:south];
        [resizeButton setCenter: CGEdgeBottomPointInRect(frame)];
        [self addSubview:resizeButton];
        [self setHandleEdgeBottom: resizeButton];
        [resizeButton release];
        resizeButton = nil;

        resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:east];
        [resizeButton setCenter: CGEdgeRightPointInRect(frame)];
        [self addSubview:resizeButton];
        [self setHandleEdgeRight: resizeButton];
        [resizeButton release];
        resizeButton = nil;

        resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:west];
        [resizeButton setCenter: CGEdgeLeftPointInRect(frame)];
        [self addSubview:resizeButton];
        [self setHandleEdgeLeft: resizeButton];
        [resizeButton release];
        resizeButton = nil;

    }
    return self;
}

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

- (void)resizeHandle:(UIViewResizeHandle *)handle didMoveToPoint:(CGPoint)point {
    switch ([handle type]) {
        case west:
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
}

#pragma mark Touch events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint newCenter = [[touches anyObject] locationInView: [self containerView]];
    newCenter.x = roundf(newCenter.x);
    newCenter.y = roundf(newCenter.y);

    [self setCurrentTime: [[touches anyObject] timestamp]];

    [UIView animateWithDuration: 0.2000f
                          delay: 0.0000f
                        options: UIViewAnimationOptionCurveLinear
                     animations: ^{
                         [self setCenter:newCenter];
                         [[self containerView] bringSubviewToFront: self];
                     } completion:^(BOOL finished) {
                         
                     }];

    [self.containerView setScrollEnabled:NO];
    NSLog(@"Touches Began: %@", NSStringFromCGRect( self.frame ));
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event { }

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    self.lastTime = self.currentTime;
    self.currentTime = [[touches anyObject] timestamp];

    CGPoint newCenter = [[touches anyObject] locationInView: [self containerView]];
    newCenter.x = roundf(newCenter.x);
    newCenter.y = roundf(newCenter.y);
    
    [UIView animateWithDuration: (self.currentTime - self.lastTime)
                          delay: 0.0000f
                        options: UIViewAnimationOptionCurveLinear
                     animations: ^{
                         [self setCenter:newCenter];
                     } completion:^(BOOL finished) {
                         
                     }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.lastTime = self.currentTime;
    self.currentTime = [[touches anyObject] timestamp];

    CGPoint newCenter = [[touches anyObject] locationInView: [self containerView]];
    newCenter.x = roundf(newCenter.x);
    newCenter.y = roundf(newCenter.y);
    
    [UIView animateWithDuration: (self.currentTime - self.lastTime)
                          delay: 0.0000f
                        options: UIViewAnimationOptionCurveLinear
                     animations: ^{
                         [self setCenter:newCenter];
                     } completion:^(BOOL finished) {
                         [self.containerView setScrollEnabled:YES];
                     }];
}

@end