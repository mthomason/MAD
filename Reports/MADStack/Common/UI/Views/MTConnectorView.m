//
//  MTConnectorView.m
//  Reports
//
//  Created by Michael Thomason on 2/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTConnectorView.h"

@interface MTConnectorView ()

@property (nonatomic, strong) UIColor *forgroundColor;

@property (nonatomic, assign) CGSize shadowSize;
@property (nonatomic, assign) CGSize smallCircleSize;

- (instancetype)init;

@end

@implementation MTConnectorView

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        CGSize shadowSize = CGSizeMake(2.0000f, 2.0000f);
        [self setShadowSize:shadowSize];

        CGSize smallCircleSize = CGSizeMake(4.0000f, 4.0000f);
        [self setSmallCircleSize:smallCircleSize];
        
        UIView *anchorLeft = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 1.0000f, 1.0000f)];
        UIView *anchorRight = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height, 1.0000f, 1.0000f)];
        
        anchorLeft.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        anchorRight.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        
        UIColor *color = [UIColor tintColorRed];
        [self setForgroundColor:color];
        
        [self setAnchorViewLeft:anchorLeft];
        [self setAnchorViewRight:anchorRight];

        [self addSubview:[self anchorViewLeft]];
        [self addSubview:[self anchorViewRight]];
        
        
        [self setClipsToBounds:NO];
        [[self layer] setMasksToBounds:NO];
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (instancetype)initWithOriginView:(CGPoint)originPoint andDestinationPoint:(CGPoint)destinationPoint {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setOriginPoint:originPoint andDestinationPoint:destinationPoint];
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)setOriginPoint:(CGPoint)originPoint andDestinationPoint:(CGPoint)destinationPoint {
    CGRect frame = [self rectForOriginPoint:originPoint andDestinationPoint:destinationPoint];
    [self setFrame:frame];
}

- (CGRect)rectForOriginPoint:(CGPoint)originPoint andDestinationPoint:(CGPoint)destinationPoint {
    CGFloat originX, originY, sizeWidth, sizeHeight;
    BOOL topLeftToBottomRight;
    
    if (originPoint.x < destinationPoint.x && originPoint.y < destinationPoint.y) {
        topLeftToBottomRight = YES;
        originX = originPoint.x;
        originY = originPoint.y;
        sizeWidth = destinationPoint.x - originPoint.x;
        sizeHeight = destinationPoint.y - originPoint.y;
    } else if (originPoint.x > destinationPoint.x && originPoint.y > destinationPoint.y) {
        topLeftToBottomRight = YES;
        originX = destinationPoint.x;
        originY = destinationPoint.y;
        sizeWidth = originPoint.x - destinationPoint.x;
        sizeHeight = originPoint.y - destinationPoint.y;
    } else {
        topLeftToBottomRight = NO;
        if (originPoint.x < destinationPoint.x) {
            originX = originPoint.x;
            originY = destinationPoint.y;
            sizeWidth = destinationPoint.x - originPoint.x;
            sizeHeight = originPoint.y - destinationPoint.y;
        } else {
            originX = destinationPoint.x;
            originY = originPoint.y;
            sizeWidth = originPoint.x - destinationPoint.x;
            sizeHeight = destinationPoint.y - originPoint.y;
        }
    }

    NSNumber *topLeftToBottomRightWrapper = @(topLeftToBottomRight);
    [self setTopLeftToBottomRight:topLeftToBottomRightWrapper];
    
    [self setNeedsDisplay];
    
    return CGRectMake(originX, originY, sizeWidth, sizeHeight);
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    //[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (rect.size.width != CGSizeZero.width && rect.size.height != CGSizeZero.height) {
        rect = CGRectInset(rect, 10.0000f, 10.0000f);
        
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        CGContextSetShadow(currentContext, self.shadowSize, 5.0000f);
        CGContextSetLineWidth(currentContext, 3.0000f);
        
        CGRect connectorNobRectOrigin;
        CGRect connectorNobRectDestination;
        
        CGFloat largeCircleRadius = 3.0000f;
        CGSize smallCircleSize = self.smallCircleSize;
        CGFloat smallCircleRadius = 2.0000f;
        
        CGPoint origin, destination;
        CGPoint tangent[2];
        
        [self.forgroundColor set];
        
        if (self.topLeftToBottomRight.boolValue) {
            
            
            origin = CGPointMake(rect.origin.x, rect.origin.y);
            destination = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
            
            if (self.leftViewIsInital) {   //origin is the back point of the arrow
                connectorNobRectOrigin = CGRectMake(origin.x - smallCircleRadius, origin.y - smallCircleRadius, smallCircleSize.width, smallCircleSize.height);
                connectorNobRectDestination = CGRectMake(destination.x - smallCircleRadius, destination.y - smallCircleRadius, smallCircleSize.width, smallCircleSize.height);
            } else {
                connectorNobRectOrigin = CGRectMake(destination.x - smallCircleRadius, destination.y - smallCircleRadius, smallCircleSize.width, smallCircleSize.height);
                connectorNobRectDestination = CGRectMake(origin.x - smallCircleRadius, origin.y - smallCircleRadius, smallCircleSize.width, smallCircleSize.height);
            }
            tangent[0] = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
            tangent[1] = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
            
        } else {
            
            origin = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
            destination = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
            
            if ([self leftViewIsInital]) {   //Origin is the front part of the arrow
                connectorNobRectDestination = CGRectMake(origin.x - largeCircleRadius, origin.y - largeCircleRadius, smallCircleSize.width, smallCircleSize.height);
                connectorNobRectOrigin = CGRectMake(destination.x - smallCircleRadius, destination.y - smallCircleRadius, smallCircleSize.width, smallCircleSize.height);
            } else {
                connectorNobRectDestination = CGRectMake(destination.x - smallCircleRadius, destination.y - smallCircleRadius, smallCircleSize.width, smallCircleSize.height);
                connectorNobRectOrigin = CGRectMake(origin.x - smallCircleRadius, origin.y - smallCircleRadius, smallCircleSize.width, smallCircleSize.height);
            }
            tangent[0] = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
            tangent[1] = CGPointMake(rect.origin.x, rect.origin.y);
        }
        
        CGContextAddEllipseInRect(currentContext, connectorNobRectOrigin);
        CGContextAddEllipseInRect(currentContext, connectorNobRectDestination);
        
        if (fpclassify(tangent[0].x) == FP_NORMAL &&
            fpclassify(tangent[0].y) == FP_NORMAL &&
            fpclassify(tangent[1].x) == FP_NORMAL &&
            fpclassify(tangent[1].y) == FP_NORMAL) {
            
            CGContextMoveToPoint(currentContext, origin.x, origin.y);
            CGContextAddCurveToPoint(currentContext, tangent[0].x, tangent[0].y, tangent[1].x, tangent[1].y, destination.x, destination.y);
            
            CGFloat arrowRadius = 5.0000f;
            UIBezierPath *path = [UIBezierPath bezierPath];
            CGPoint pathOrigin = connectorNobRectDestination.origin;
            pathOrigin.y += 3.0000f;
            if (self.topLeftToBottomRight.boolValue) {
                if (self.leftViewIsInital) {
                    pathOrigin.x -= 5.0000f;
                    [path moveToPoint:CGPointMake(pathOrigin.x - arrowRadius, pathOrigin.y - arrowRadius)];
                    [path addLineToPoint:CGPointMake(pathOrigin.x, pathOrigin.y)];
                    [path addLineToPoint:CGPointMake(pathOrigin.x - arrowRadius, pathOrigin.y + arrowRadius)];
                } else {
                    pathOrigin.x += 10.0000f;
                    [path moveToPoint:CGPointMake(pathOrigin.x + arrowRadius, pathOrigin.y - arrowRadius)];
                    [path addLineToPoint:CGPointMake(pathOrigin.x, pathOrigin.y)];
                    [path addLineToPoint:CGPointMake(pathOrigin.x + arrowRadius, pathOrigin.y + arrowRadius)];
                }
            } else {
                if (self.leftViewIsInital) {
                    pathOrigin.x -= 5.0000f;
                    [path moveToPoint:CGPointMake(pathOrigin.x - arrowRadius, pathOrigin.y - arrowRadius)];
                    [path addLineToPoint:CGPointMake(pathOrigin.x, pathOrigin.y)];
                    [path addLineToPoint:CGPointMake(pathOrigin.x - arrowRadius, pathOrigin.y + arrowRadius)];
                } else {
                    pathOrigin.x += 10.0000f;
                    [path moveToPoint:CGPointMake(pathOrigin.x + arrowRadius, pathOrigin.y - arrowRadius)];
                    [path addLineToPoint:CGPointMake(pathOrigin.x, pathOrigin.y)];
                    [path addLineToPoint:CGPointMake(pathOrigin.x + arrowRadius, pathOrigin.y + arrowRadius)];
                }
            }
            path.lineWidth = 3.0000f;
            [path stroke];
        }
    }
}

@end
