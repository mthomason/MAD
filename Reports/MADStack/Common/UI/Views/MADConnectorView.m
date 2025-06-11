//
//  MADConnectorView.m
//  Reports
//
//  Created by Michael Thomason on 2/16/13.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADConnectorView.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <UIKit/UIGraphics.h>
#import <UIKit/UIBezierPath.h>
#import <QuartzCore/CALayer.h>

static inline CGRect CGRectSafeInset(CGRect, CGFloat, CGFloat);
static inline CGRect CGRectSafeInset(CGRect rect, CGFloat insetX, CGFloat insetY) {
	CGFloat actualInsetX = MIN(insetX, rect.size.width / 2.0);
	CGFloat actualInsetY = MIN(insetY, rect.size.height / 2.0);
	
	return CGRectMake(rect.origin.x + actualInsetX,
					  rect.origin.y + actualInsetY,
					  rect.size.width - 2.0 * actualInsetX,
					  rect.size.height - 2.0 * actualInsetY);
}

@interface MADConnectorView ()

@property (nonatomic, strong) MADColor *forgroundColor;

@end

@implementation MADConnectorView

@synthesize identifier = _identifier;

- (instancetype)init {
	return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
	
	if (self = [super initWithFrame:frame]) {
		
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = NO;
		self.layer.masksToBounds = NO;
		self.contentMode = UIViewContentModeScaleAspectFit;
		
		UIColor *color = [MADColorEverydayApps newColorRed];
		MADColor *foregroundColor = [[MADColor alloc] initWithColor:color];
		self.forgroundColor = foregroundColor;
		
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect: rect];
	if (rect.size.width == CGSizeZero.width && rect.size.height == CGSizeZero.height) return;

	rect = CGRectSafeInset(rect, 10.0, 10.0);
	
	CGContextRef currentContext = UIGraphicsGetCurrentContext();
	CGContextSetShadow(currentContext, CGSizeMake(2.0, 2.0), 5.0);
	CGContextSetLineWidth(currentContext, 3.0);

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
		return leftToRight ? CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height) : rect.origin;
	};
	
	CGRect (^nobSize)(CGPoint, CGSize) = ^(CGPoint p, CGSize s) {
		return CGRectMake(p.x - (s.width / 2.0) + 1.0, p.y - (s.height / 2.0) + 1.0, s.width, s.height);
	};
	CGPoint (^getOriginPoint2)(BOOL, BOOL, CGPoint, CGPoint) =
	^CGPoint(BOOL leftToRight, BOOL leftInital, CGPoint p1, CGPoint p2) {
		return leftToRight ? (leftInital ? p1 : p2) : (leftInital ? p2 : p1);
	};
	
	CGPoint tangent[2];
	tangent[0] = originTangentPoint(_topLeftToBottomRight, rect);
	tangent[1] = destinationTangentPoint(_topLeftToBottomRight, rect);
	
	void(^drawLines)(CGPoint, CGPoint, CGPoint) = ^void(CGPoint startingPoint, CGPoint firstEndPoint, CGPoint endPoint) {
		UIBezierPath *path = [UIBezierPath bezierPath];
		[path moveToPoint:startingPoint];
		[path addLineToPoint:firstEndPoint];
		[path addLineToPoint:endPoint];
		path.lineWidth = 3.0;
		[path stroke];
	};
	
	CGFloat (^offsetX)(BOOL, CGFloat) = ^CGFloat(BOOL leftInital, CGFloat radius) {
		return leftInital ? -5.0 - radius : 10.0 + radius;
	};
	
	CGPoint(^startingPoint)(BOOL, CGFloat, CGPoint) = ^(BOOL leftInital, CGFloat radius, CGPoint start) {
		return CGPointMake(start.x + offsetX(leftInital, radius), start.y - radius);
	};
	
	CGPoint(^centerPoint)(BOOL, CGPoint) = ^CGPoint(BOOL leftInital, CGPoint start) {
		return CGPointMake(start.x + offsetX(leftInital, CGSizeZero.width), start.y);
	};
	
	CGPoint(^finalPoint)(BOOL, CGFloat, CGPoint) = ^CGPoint(BOOL leftInital, CGFloat radius, CGPoint start) {
		return CGPointMake(start.x + offsetX(leftInital, radius), start.y + radius);
	};
	
	CGPoint origin = originPoint(_topLeftToBottomRight, rect);
	CGPoint destination = destinationPoint(_topLeftToBottomRight, rect);

	CGRect connectorNobRect[2];
	connectorNobRect[0] = nobSize(getOriginPoint2(_topLeftToBottomRight, _leftViewIsInital, origin, destination), CGSizeMake(4.0, 4.0));
	connectorNobRect[1] = nobSize(getOriginPoint2(_topLeftToBottomRight, _leftViewIsInital, destination, origin), CGSizeMake(4.0, 4.0));

	CGContextAddEllipseInRect(currentContext, connectorNobRect[0]);
	CGContextAddEllipseInRect(currentContext, connectorNobRect[1]);
	CGContextMoveToPoint(currentContext, origin.x, origin.y);
	if (isfinite(tangent[0].x) || isfinite(tangent[0].y) || isfinite(tangent[1].x) || isfinite(tangent[1].y)) {
		CGContextAddCurveToPoint(currentContext,
								 tangent[0].x,
								 tangent[0].y,
								 tangent[1].x,
								 tangent[1].y,
								 destination.x,
								 destination.y);
	} else {
		CGContextAddLineToPoint(currentContext, destination.x, destination.y);
	}
	connectorNobRect[1].origin.y += 3.0;
	drawLines(startingPoint(_leftViewIsInital, 5.0, connectorNobRect[1].origin), centerPoint(_leftViewIsInital, connectorNobRect[1].origin), finalPoint(_leftViewIsInital, 5.0, connectorNobRect[1].origin));

}

- (id <NSCopying>)key {
	return @(self.identifier);
}

@end
