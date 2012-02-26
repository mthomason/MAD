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

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0
#define kAnimationTranslateX 2.0
#define kAnimationTranslateY 2.0

@implementation ElementView

@synthesize delegate = _delegate;
@synthesize containerView = _parentView;
@synthesize designerView = _designerView;

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
    [_designerView release];
    [_parentView release];
    [_stringElm release];
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame inSectionView:(UIScrollView *)pview ofDesignerView:(UIScrollView *)dview {
    self = [super initWithFrame:frame];
    if (self) {
        [self setDesignerView: dview];
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

- (void)setParentScrollersEnabled:(BOOL)enabled {
    [[self containerView] setScrollEnabled:enabled];
    [[self containerView] flashScrollIndicators];
    if ([[[self containerView] superview] respondsToSelector:@selector(setScrollEnabled:)]) {
        if ([[[self containerView] superview] isKindOfClass:[UIScrollView class]]) {
            [(UIScrollView *)self.containerView.superview setScrollEnabled:enabled];
            [(UIScrollView *)self.containerView.superview flashScrollIndicators];
        }
    }
}

#pragma mark Touch events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //Animate the move to the touch
    CGPoint newCenter = [[touches anyObject] locationInView: [self containerView]];
    [UIView animateWithDuration: 0.2000f
                          delay: 0.0000f
                        options: UIViewAnimationOptionCurveLinear
                     animations: ^{
                         [self setCenter: newCenter];
                         [[self containerView] bringSubviewToFront: self];
                     } completion:^(BOOL finished) {
                         
                         //Don't animate the move outside of the goal, because it will jump around.
                         CGPoint outsideCenter = [[touches anyObject] locationInView: [self designerView]];
                         outsideCenter.x = roundf(outsideCenter.x);
                         outsideCenter.y = roundf(outsideCenter.y);

                         [self setCurrentTime: [[touches anyObject] timestamp]];
                         [self setParentScrollersEnabled: NO];
                         
                         [self startWobble: 1];

                         [[self designerView] addSubview: self];
                         [self setCenter: outsideCenter];
                         [[self containerView] bringSubviewToFront: self];
                     }];

}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    UIScrollView *newParent = (UIScrollView *)[[self hitTest:[self center] withEvent: nil] retain];
    if (newParent) {
        [self setContainerView: newParent];
        [newParent addSubview: self];
    }
    [newParent release];
    [self setParentScrollersEnabled: YES];
    [self stopWobble];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    self.lastTime = self.currentTime;
    self.currentTime = [[touches anyObject] timestamp];
    CGPoint newCenter = [[touches anyObject] locationInView: [self designerView]];
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
    
    CGPoint newCenter = [[touches anyObject] locationInView: [self designerView]];
    newCenter.x = roundf(newCenter.x);
    newCenter.y = roundf(newCenter.y);
    
    [UIView animateWithDuration: (self.currentTime - self.lastTime)
                          delay: 0.0000f
                        options: UIViewAnimationOptionCurveLinear
                     animations: ^{
                         [self setCenter:newCenter];
                     } completion:^(BOOL finished) {
                         UIScrollView *newParent = nil;
                         for (UIView *view in [[self designerView] subviews]) {
                             NSLog(@"%@ inside %@?", NSStringFromCGPoint([self center]), NSStringFromCGRect([view frame]));
                             if (CGRectContainsPoint([view frame], [self center]) && ![view isEqual:self]) {
                                 newParent = (UIScrollView *)[[view retain] autorelease];    //These should be the section views.
                             }
                         }
                         
                         if (newParent) {
                             [self setContainerView: newParent];
                             [newParent addSubview: self];
                         } else {
                             newParent = [[[self containerView] retain] autorelease];
                         }
                         
                         self.lastTime = self.currentTime;
                         self.currentTime = [[touches anyObject] timestamp];
                         
                         //Don't animate this, because of the change in views, the animation seems to jump.
                         CGPoint newCenter = [[touches anyObject] locationInView: newParent];
                         newCenter.x = roundf(newCenter.x);
                         newCenter.y = roundf(newCenter.y);
                         
                         [self setCenter: newCenter];
                         [self setParentScrollersEnabled: YES];
                         [self stopWobble];
 
                     }];
}

#pragma mark - Animations

- (void)startWobble:(NSInteger)count {
    NSInteger randomInt = arc4random()%500;
    float r = (randomInt/500.0)+0.5;
    
    CGAffineTransform leftWobble = CGAffineTransformMakeRotation(degreesToRadians( (kAnimationRotateDeg * -1.0) - r ));
    CGAffineTransform rightWobble = CGAffineTransformMakeRotation(degreesToRadians( kAnimationRotateDeg + r ));
    
    self.transform = leftWobble;  // starting point
    
    [[self layer] setAnchorPoint:CGPointMake(0.5, 0.5)];
    
    [UIView animateWithDuration:0.3500
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                     animations:^{ 
                         [UIView setAnimationRepeatCount:NSNotFound];
                         self.transform = rightWobble; }
                     completion:nil];

}

- (void)stopWobble {
    [self.layer removeAllAnimations];
    self.transform = CGAffineTransformIdentity;
}

@end