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

@interface ElementView ()

@property (nonatomic, retain) UICollectionView *origionalSuperview;

@property (assign) CGPoint origionalCenter;

@property (nonatomic, retain) UIViewResizeHandle *handleEdgeRight;
@property (nonatomic, retain) UIViewResizeHandle *handleEdgeLeft;
@property (nonatomic, retain) UIViewResizeHandle *handleEdgeTop;
@property (nonatomic, retain) UIViewResizeHandle *handleEdgeBottom;
@property (nonatomic, retain) UIViewResizeHandle *handleCornerTopRight;
@property (nonatomic, retain) UIViewResizeHandle *handleCornerTopLeft;
@property (nonatomic, retain) UIViewResizeHandle *handleCornerBottomRight;
@property (nonatomic, retain) UIViewResizeHandle *handleCornerBottomLeft;

@end

@implementation ElementView

- (void)dealloc {
    if (_origionalSuperview != nil) [_origionalSuperview release];
    [_objectID release];
    [_handleCornerBottomLeft release];
    [_handleCornerBottomRight release];
    [_handleCornerTopLeft release];
    [_handleCornerTopRight release];
    [_handleEdgeBottom release];
    [_handleEdgeLeft release];
    [_handleEdgeRight release];
    [_handleEdgeTop release];
    [_designerView release];
    [_containerView release];
    [_stringElm release];
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame inSectionView:nil ofDesignerView:nil];
}
- (id)initWithFrame:(CGRect)frame inSectionView:(UICollectionView *)pview ofDesignerView:(UIScrollView *)dview {
    self = [super initWithFrame:frame];
    if (self) {
        [self setDesignerView: dview];
        [self setExclusiveTouch: YES];
        [self setMultipleTouchEnabled:YES];
        [self setContainerView: pview];
		[self setOriginalSize: self.frame.size];
        
		[self setOpaque: YES];
        [self setHighlight: NO];
        [[self layer] setCornerRadius: 5.0000f];
        
        //UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotatePiece:)];
        //[self addGestureRecognizer:rotationGesture];
        //[rotationGesture release];
        
        //UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scalePiece:)];
        //[pinchGesture setDelegate:self];
        //[self addGestureRecognizer:pinchGesture];
        //[pinchGesture release];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
        [panGesture setMaximumNumberOfTouches:1];
        [panGesture setDelegate:self];
        [self addGestureRecognizer:panGesture];
        [panGesture release];
        
        CGSize handleSize = CGSizeMake(10.0000f, 10.0000f);

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
/*
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
 */

    }
    return self;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
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

    UIFont *font = [UIFont systemFontOfSize:([UIFont systemFontSize])];        
    [[self stringElm] drawInRect: rect
                        withFont: font
                   lineBreakMode: NSLineBreakByClipping
                       alignment: NSTextAlignmentLeft];
    
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
    @synchronized([self containerView]) {
        if ([self containerView] != nil) {
            if ([[self containerView] respondsToSelector:@selector(setScrollEnabled:)]) {
                [[self containerView] setScrollEnabled:enabled];
                [[self containerView] flashScrollIndicators];
                @synchronized([[self containerView] superview]) {
                    if ([[[self containerView] superview] respondsToSelector:@selector(setScrollEnabled:)]) {
                        if ([[[self containerView] superview] isKindOfClass:[UIScrollView class]]) {
                            [(UIScrollView *)self.containerView.superview setScrollEnabled:enabled];
                            [(UIScrollView *)self.containerView.superview flashScrollIndicators];
                        }
                    }
                }
            }
        }
    }
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

#pragma mark - Touch events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [[self containerView] bringSubviewToFront: self];
    [self setHighlight: YES];
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
}

#pragma mark - Actions

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer {
    [self setOrigionalCenter: [self center]];
    
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    switch ([gestureRecognizer state]) {
            
        case UIGestureRecognizerStateBegan: {
            
            [self setOrigionalSuperview: (UICollectionView *)[self superview]];

            CGPoint newCenter = [gestureRecognizer locationInView:[self containerView]];
            [self setCenter: newCenter];
            [[self containerView] bringSubviewToFront: self];
            newCenter = [gestureRecognizer locationInView:[self designerView]];
            
            [self setParentScrollersEnabled: NO];
            
            [self startWobble: 1];
            
            if (![[self designerView] isEqual:self]) {
                [self setCenter: newCenter];
                [[self designerView] addSubview: self];
            }
            [[self containerView] bringSubviewToFront: self];

            [[self delegate] elementDidBeginPan:self];
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint newCenter = [gestureRecognizer locationInView:[self designerView]];
            [self setCenter: newCenter];
            break;
        }
        case UIGestureRecognizerStatePossible: {
            CGPoint newCenter = [gestureRecognizer locationInView:[self containerView]];
            [self setCenter: newCenter];
            break;
        }
        case UIGestureRecognizerStateCancelled: {
#warning FIXME - This should go back to origional postion
            /*
            if ([self origionalSuperview]) {
                if (![[self origionalSuperview] isEqual: self]) {
                    [self setContainerView: [self origionalSuperview]];
                    [[self origionalSuperview] addSubview: self];
                }
            }
             */
            [self setParentScrollersEnabled: YES];
            [self stopWobble];
            break;
        }
        case UIGestureRecognizerStateFailed: {
#warning FIXME - This should go back to origional postion
            /*
            if ([self origionalSuperview]) {
                if (![[self origionalSuperview] isEqual: self]) {
                    [self setContainerView: [self origionalSuperview]];
                    [[self origionalSuperview] addSubview: self];
                }
            }
            */
            [self setParentScrollersEnabled: YES];
            [self stopWobble];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            
            
            // MARK: Remove the element from one section and place it into the next new section
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designerView]];
            UICollectionView *newParent = nil;
            
            // MARK: Try to find the section to place the element view into.
            BOOL addedToNewParent = NO;
            for (UICollectionView *view in [[self designerView] subviews]) {
                if (CGRectContainsPoint([view frame], [self center]) && ![view isEqual:self]) {
                    if ([view isKindOfClass:[UICollectionView class]]) {
                        newParent = [[view retain] autorelease];
                        addedToNewParent = YES;
                        newCenter = [gestureRecognizer locationInView:newParent];
                        [self setCenter: newCenter];
                        break;
                    }
                }
            }
            if (!addedToNewParent) {                                            //OK, lets be less choosie, and get the first one, yo
                for (UICollectionView *view in [[self designerView] subviews]) {
                    if ([view isKindOfClass: [UICollectionView class]]) {
                        newParent = [[view retain] autorelease];
                        addedToNewParent = YES;
                        newCenter = CGPointMake(self.frame.size.width / 2.0000f, self.frame.size.height / 2.0000f);
                        [self setCenter: newCenter];
                        break;
                    }
                }
            }

            
            
            if (addedToNewParent) {
                if (newParent) {
                    if (![newParent isEqual: self]) {
                        [self setContainerView: newParent];
                        
                        //[newParent addSubview: self];
                    }
                } else {
                    newParent = [[[self origionalSuperview] retain] autorelease];
                    [self setContainerView: [self origionalSuperview]];
                    //[[self origionalSuperview] addSubview: self];
                    [self setCenter: [self origionalCenter]];
                    newCenter = [self origionalCenter];
                }
            } else {
                newParent = [[[self origionalSuperview] retain] autorelease];
                [self setContainerView: [self origionalSuperview]];
                //[[self origionalSuperview] addSubview: self];
                [self setCenter: [self origionalCenter]];
                newCenter = [self origionalCenter];
            }
            
            self.lastTime = self.currentTime;
            newCenter = CGPointRoundPointToGrid(newCenter);
            
            [self setCenter: newCenter];
            [self setParentScrollersEnabled: YES];
            [self stopWobble];
            [[self delegate] elementDidFinishPan:self];
            [self setHighlight: NO];
            [self setNeedsDisplay];
            break;
        }
        default:
            break;
    }
}

// rotate the piece by the current rotation
// reset the gesture recognizer's rotation to 0 after applying so the next callback is a delta from the current rotation
- (void)rotatePiece:(UIRotationGestureRecognizer *)gestureRecognizer {
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        [gestureRecognizer view].transform = CGAffineTransformRotate([[gestureRecognizer view] transform], [gestureRecognizer rotation]);
        [gestureRecognizer setRotation:0];
    }
}

// scale the piece by the current scale
// reset the gesture recognizer's rotation to 0 after applying so the next callback is a delta from the current scale
- (void)scalePiece:(UIPinchGestureRecognizer *)gestureRecognizer {
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        [gestureRecognizer view].transform = CGAffineTransformScale([[gestureRecognizer view] transform], [gestureRecognizer scale], [gestureRecognizer scale]);
        [gestureRecognizer setScale:1];
    }
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

// display a menu with a single item to allow the piece's transform to be reset
- (void)showResetMenu:(UILongPressGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:@"Reset" action:@selector(resetPiece:)];
        CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
        
        [self becomeFirstResponder];
        [menuController setMenuItems:[NSArray arrayWithObject:resetMenuItem]];
        [menuController setTargetRect:CGRectMake(location.x, location.y, 0, 0) inView:[gestureRecognizer view]];
        [menuController setMenuVisible:YES animated:YES];
        
        pieceForReset = [gestureRecognizer view];
        
        [resetMenuItem release];
    }
}
- (void)resetPiece:(UIMenuController *)controller {
    CGPoint locationInSuperview = [pieceForReset convertPoint:CGPointMake(CGRectGetMidX(pieceForReset.bounds), CGRectGetMidY(pieceForReset.bounds)) toView:[pieceForReset superview]];
    
    [[pieceForReset layer] setAnchorPoint:CGPointMake(0.5, 0.5)];
    [pieceForReset setCenter:locationInSuperview];
    
    [UIView beginAnimations:nil context:nil];
    [pieceForReset setTransform:CGAffineTransformIdentity];
    [UIView commitAnimations];
}

#pragma mark Animations

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
                         self.transform = rightWobble;
                     }
                     completion:nil];

}

- (void)stopWobble {
    [self.layer removeAllAnimations];
    self.transform = CGAffineTransformIdentity;
}

@end