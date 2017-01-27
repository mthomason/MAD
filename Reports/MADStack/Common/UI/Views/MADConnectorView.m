//
//  MTConnectorView.m
//  Reports
//
//  Created by Michael Thomason on 2/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADConnectorView.h"
#import <MADCocoaExtensions/MADColor.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <UIKit/UIGraphics.h>
#import <QuartzCore/CALayer.h>
#import <UIKit/UIBezierPath.h>

@interface MADConnectorView ()

    @property (nonatomic, strong) MADColor *forgroundColor;

@end

@implementation MADConnectorView {
    CGSize _shadowSize;
    CGSize _smallCircleSize;
}

@synthesize objectIdTag = _objectIdTag;

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {

    if (self = [super initWithFrame:frame]) {

        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        self.layer.masksToBounds = NO;
        self.contentMode = UIViewContentModeScaleAspectFit;
        
        _shadowSize = CGSizeMake(2.0000f, 2.0000f);
        _smallCircleSize = CGSizeMake(4.0000f, 4.0000f);
        
        UIColor *color = [MADColorEverydayApps newColorRed];
        MADColor *foregroundColor = [[MADColor alloc] initWithColor:color];
        self.forgroundColor = foregroundColor;
        
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect: rect];

    if (rect.size.width == CGSizeZero.width && rect.size.height == CGSizeZero.height) return;
        
    rect = CGRectInset(rect, 10.0000f, 10.0000f);
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetShadow(currentContext, _shadowSize, 5.0000f);
    CGContextSetLineWidth(currentContext, 3.0000f);
    
    CGRect connectorNobRect[2];
    CGPoint origin, destination;
    CGPoint tangent[2];
    
    [self.forgroundColor.color set];
    
    CGPoint (^originPoint)(BOOL, CGRect) = ^CGPoint(BOOL leftToRight, CGRect r) {
        return leftToRight ? r.origin : CGPointMake(r.origin.x + r.size.width, r.origin.y);
    };
    CGPoint (^destinationPoint)(BOOL, CGRect) = ^CGPoint(BOOL leftToRight, CGRect r) {
        return leftToRight ? CGPointMake(r.origin.x + r.size.width, r.origin.y + r.size.height) :
        CGPointMake(r.origin.x, r.origin.y + r.size.height);
    };
    CGPoint (^originTangentPoint)(BOOL, CGRect) = ^CGPoint(BOOL leftToRight, CGRect r) {
        return leftToRight ? CGPointMake(rect.origin.x, rect.origin.y + rect.size.height) :
        CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    };
    CGPoint (^destinationTangentPoint)(BOOL, CGRect) = ^CGPoint(BOOL leftToRight, CGRect r) {
        return leftToRight ? CGPointMake(rect.origin.x + rect.size.width,
                                         rect.origin.y + rect.size.height) :
        rect.origin;
    };
    
    CGRect (^nobSize)(CGPoint, CGSize) = ^(CGPoint p, CGSize s) {
        return CGRectMake(p.x - (s.width / 2.0000f) + 1.0000f,
                          p.y - (s.height / 2.0000f) + 1.0000f,
                          s.width, s.height);
    };
    CGPoint (^getOriginPoint)(BOOL, CGPoint, CGPoint) = ^CGPoint(BOOL leftInital, CGPoint p1, CGPoint p2) {
        return leftInital ? p1 : p2;
    };

    origin = originPoint(_topLeftToBottomRight, rect);
    destination = destinationPoint(_topLeftToBottomRight, rect);
    
    tangent[0] = originTangentPoint(_topLeftToBottomRight, rect);
    tangent[1] = destinationTangentPoint(_topLeftToBottomRight, rect);
    
    connectorNobRect[0] = nobSize(getOriginPoint(_leftViewIsInital, origin, destination), _smallCircleSize);
    connectorNobRect[1] = nobSize(getOriginPoint(!_leftViewIsInital, origin, destination), _smallCircleSize);
    
    CGContextAddEllipseInRect(currentContext, connectorNobRect[0]);
    CGContextAddEllipseInRect(currentContext, connectorNobRect[1]);
    
    if (fpclassify(tangent[0].x) >= FP_ZERO &&
        fpclassify(tangent[0].y) >= FP_ZERO &&
        fpclassify(tangent[1].x) >= FP_ZERO &&
        fpclassify(tangent[1].y) >= FP_ZERO) {
        
        CGContextMoveToPoint(currentContext, origin.x, origin.y);
        CGContextAddCurveToPoint(currentContext,
                                 tangent[0].x,
                                 tangent[0].y,
                                 tangent[1].x,
                                 tangent[1].y,
                                 destination.x,
                                 destination.y);
        
        static CGFloat arrowRadius = 5.0000f;
        
        connectorNobRect[1].origin.y += 3.0000f;
        
        void(^drawLines)(CGPoint, CGPoint, CGPoint) =
        ^void(CGPoint startingPoint, CGPoint firstEndPoint, CGPoint endPoint) {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:startingPoint];
            [path addLineToPoint:firstEndPoint];
            [path addLineToPoint:endPoint];
            path.lineWidth = 3.0000f;
            [path stroke];
        };
        
        CGFloat (^offsetX)(BOOL, CGFloat) = ^CGFloat(BOOL leftInital, CGFloat radius) {
            return leftInital ? -5.0000f - radius : 10.0000f + radius;
        };
        
        CGPoint(^startingPoint)(BOOL, CGFloat, CGPoint) =
        ^(BOOL leftInital, CGFloat radius, CGPoint start) {
            return CGPointMake(start.x + offsetX(leftInital, radius), start.y - radius);
        };
        
        CGPoint(^centerPoint)(BOOL, CGPoint) = ^CGPoint(BOOL leftInital, CGPoint start) {
            return CGPointMake(start.x + offsetX(leftInital, CGSizeZero.width), start.y);
        };
        
        CGPoint(^finalPoint)(BOOL, CGFloat, CGPoint) =
        ^CGPoint(BOOL leftInital, CGFloat radius, CGPoint start) {
            return CGPointMake(start.x + offsetX(leftInital, radius), start.y + radius);
        };
        
        drawLines(startingPoint(_leftViewIsInital, arrowRadius, connectorNobRect[1].origin),
                  centerPoint(_leftViewIsInital, connectorNobRect[1].origin),
                  finalPoint(_leftViewIsInital, arrowRadius, connectorNobRect[1].origin));
    }
}

@end
