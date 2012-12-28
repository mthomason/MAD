//
//  DataObject.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTElementView.h"
#import <QuartzCore/QuartzCore.h>
#import "CGGeometry+Extras.h"
#import "UIViewResizeHandle.h"

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0
#define kAnimationTranslateX 2.0
#define kAnimationTranslateY 2.0

@interface MTElementView ()

@property (nonatomic, retain) UIViewResizeHandle *handleEdgeRight;
@property (nonatomic, retain) UIViewResizeHandle *handleEdgeLeft;
@property (nonatomic, retain) UIViewResizeHandle *handleEdgeTop;
@property (nonatomic, retain) UIViewResizeHandle *handleEdgeBottom;
@property (nonatomic, retain) UIViewResizeHandle *handleCornerTopRight;
@property (nonatomic, retain) UIViewResizeHandle *handleCornerTopLeft;
@property (nonatomic, retain) UIViewResizeHandle *handleCornerBottomRight;
@property (nonatomic, retain) UIViewResizeHandle *handleCornerBottomLeft;

@property (assign) BOOL displayResizeHandlesVisable;
@property (assign) BOOL displayWobbling;
@property (assign) BOOL displayHighlighted;

@end

@implementation MTElementView

#pragma mark - NSObject

- (void)dealloc {
    [_handleCornerBottomLeft release];
    [_handleCornerBottomRight release];
    [_handleCornerTopLeft release];
    [_handleCornerTopRight release];
    [_handleEdgeBottom release];
    [_handleEdgeLeft release];
    [_handleEdgeRight release];
    [_handleEdgeTop release];
	[super dealloc];
}

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setDisplayWobbling: NO];
        [self setDisplayHighlighted: NO];
        [self setDisplayResizeHandlesVisable: NO];        
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
    if (![self isHighlighted]) {
        [[UIColor blackColor] setStroke];
    } else {
        [[UIColor redColor] setStroke];
    }
    float dashPhase = 0.0;
    float dashLengths[] = { 7, 3, 7, 3, 7, 3 };
    CGContextSetLineDash(currentContext,
                         dashPhase, dashLengths,
                         sizeof( dashLengths ) / sizeof( float ) );
    CGContextSetLineWidth(currentContext, 5.0000f);
    CGContextDrawPath(currentContext, kCGPathFillStroke);
    if (![self isHighlighted]) {
        [[UIColor blackColor] set];
    } else {
        [[UIColor redColor] set];
    }

    CGPathRelease(path);
    
}

#pragma mark - Members

- (void)setResizeHandlesVisable:(BOOL)visable {
    
    [self setDisplayResizeHandlesVisable:visable];
    
    if (visable) {

        if ([[self handleCornerBottomLeft] isEqual:nil]) {
        
            CGSize handleSize = CGSizeMake(10.0000f, 10.0000f);

            UIViewResizeHandle *resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:northWest];
            [resizeButton setCenter: CGCornerTopLeftPointInRect([self frame])];
            [self addSubview:resizeButton];
            [self setHandleCornerTopLeft: resizeButton];
            [resizeButton release];
            resizeButton = nil;
            
            resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:northEast];
            [resizeButton setCenter: CGCornerTopRightPointInRect([self frame])];
            [self addSubview:resizeButton];
            [self setHandleCornerTopRight: resizeButton];
            [resizeButton release];
            resizeButton = nil;
            
            resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:southEast];
            [resizeButton setCenter: CGCornerBottomRightPointInRect([self frame])];
            [self addSubview:resizeButton];
            [self setHandleCornerBottomRight: resizeButton];
            [resizeButton release];
            resizeButton = nil;
            
            resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:southWest];
            [resizeButton setCenter: CGCornerBottomLeftPointInRect([self frame])];
            [self addSubview:resizeButton];
            [self setHandleCornerBottomLeft: resizeButton];
            [resizeButton release];
            resizeButton = nil;
            
            resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:north];
            [resizeButton setCenter: CGEdgeTopPointInRect([self frame])];
            [self addSubview:resizeButton];
            [self setHandleEdgeTop: resizeButton];
            [resizeButton release];
            resizeButton = nil;
            
            resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:south];
            [resizeButton setCenter: CGEdgeBottomPointInRect([self frame])];
            [self addSubview:resizeButton];
            [self setHandleEdgeBottom: resizeButton];
            [resizeButton release];
            resizeButton = nil;
            
            resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:east];
            [resizeButton setCenter: CGEdgeRightPointInRect([self frame])];
            [self addSubview:resizeButton];
            [self setHandleEdgeRight: resizeButton];
            [resizeButton release];
            resizeButton = nil;
            
            resizeButton = [[UIViewResizeHandle alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height) andType:west];
            [resizeButton setCenter: CGEdgeLeftPointInRect([self frame])];
            [self addSubview:resizeButton];
            [self setHandleEdgeLeft: resizeButton];
            [resizeButton release];
            resizeButton = nil;
        }
        
    }
    
    [[self handleCornerBottomLeft] setHidden:!visable];
    [[self handleCornerBottomRight] setHidden:!visable];
    [[self handleCornerTopLeft] setHidden:!visable];
    [[self handleCornerTopRight] setHidden:!visable];
    [[self handleEdgeBottom] setHidden:!visable];
    [[self handleEdgeLeft] setHidden:!visable];
    [[self handleEdgeRight] setHidden:!visable];
    [[self handleEdgeLeft] setHidden:!visable];
}

- (BOOL)handlesVisable {
    return [self displayResizeHandlesVisable];
}

- (void)setWobbleRunning:(BOOL)running {
    [self setDisplayWobbling:running];
    if (running) {
        NSInteger randomInt = arc4random() % 500;
        float r = (randomInt / 500.0000f) + 0.5000f;
        
        CGAffineTransform leftWobble = CGAffineTransformMakeRotation(degreesToRadians( (kAnimationRotateDeg * -1.0) - r ));
        CGAffineTransform rightWobble = CGAffineTransformMakeRotation(degreesToRadians( kAnimationRotateDeg + r ));
        
        [self setTransform: leftWobble];
        
        [[self layer] setAnchorPoint:CGPointMake(0.5, 0.5)];
        
        [UIView animateWithDuration:0.3500
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                         animations:^{
                             [UIView setAnimationRepeatCount:NSNotFound];
                             self.transform = rightWobble;
                         }
                         completion:nil];
        
    } else {
        [[self layer] removeAllAnimations];
        [self setTransform: CGAffineTransformIdentity];
    }
}

- (BOOL)isWobbleRunning {
    return [self displayWobbling];
}

- (void)setHighlighted:(BOOL)selected {
    [self setDisplayHighlighted:selected];
    [self setNeedsDisplay];
}

- (BOOL)isHighlighted {
    return [self displayHighlighted];
}

@end