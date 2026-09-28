//
//  CGGeometry+Extras.h
//  wordPuzzle
//
//  Created by Michael Thomason on 7/13/10.
//  Copyright 2010 Michael Thomason. All rights reserved.
//

#ifndef Reports_CGGeometry_Extras_h
#define Reports_CGGeometry_Extras_h

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSDate.h>
#import <CoreGraphics/CGBase.h>
#import <CoreGraphics/CGGeometry.h>
#import <stdlib.h>
#import <math.h>

#import <MADCocoaExtensions/MADCompassDirection.h>
#import <MADCocoaExtensions/MADMathAlgebra.h>

extern const double MADZero;
extern const double MAD_2;
extern const double MAD_44;
extern const double MAD_45;
extern const double MAD_64;
extern const double MAD_320;
extern const double MAD_360;

extern const double MADDefaultHeight;
extern const double MADHeaderHeight;
extern const CGFloat MADFloatHeaderHeight;
extern const CGFloat MADFloatZero;
extern const CGFloat MADFloat_64;
extern const CGFloat MADFloat_320;
extern const CGFloat MADFloat_1024;
extern const CGFloat MTDefaultFingerSizeWidth;
extern const CGFloat MTDefaultFingerSizeHeight;

struct MADReportPosition {
	NSUInteger currentPage;
	NSUInteger totalPages;
};
typedef struct MADReportPosition MADReportPosition;

struct MADLine {
	CGFloat m;
	CGFloat b;
};
typedef struct MADLine MADLine;

struct MADCorners {
	CGPoint topLeft;
	CGPoint topRight;
	CGPoint bottomLeft;
	CGPoint bottomRight;
};
typedef struct MADCorners MADCorners;

typedef NS_ENUM(short, MADDirection) {
	MADDirectionLeft = 1,
	MADDirectionRight,
	MADDirectionUp,
	MADDirectionDown,
	MADDirectionNoDirection,
};

static inline BOOL MADLineSegmentIntercept(MADLineSegment, MADLineSegment);
static inline MADReportPosition MADReportPositionMake(NSUInteger, NSUInteger);
static inline double square (double);
static inline CGSize MADSizeSquare(CGFloat);
static inline CGRect MADRectOfSize(CGSize);
static inline CGPoint CGRectTopLeft(CGRect);
static inline CGPoint CGRectBottomLeft(CGRect);
static inline CGPoint CGRectBottomRight(CGRect);
static inline CGPoint CGRectTopRight(CGRect);
static inline BOOL CGRectIsOffScreenWest(CGRect);
static inline BOOL CGRectIsOffScreenNorth(CGRect);
static inline CGRect CGRectFlushLeft(CGRect);
static inline CGRect CGRectFlushTop(CGRect);
static inline BOOL CGFloatCompare(CGFloat x, CGFloat y);
static inline MADDirection MADDirectionHorizontalDirectionOfPoint(CGPoint p1, CGPoint p2);
static inline MADDirection MADDirectionVerticalDirectionOfPoint(CGPoint p1, CGPoint p2);
static inline BOOL MADDirectionIsHorizontal(MADDirection d);
static inline BOOL MADDirectionIsVertical(MADDirection d);
static inline MADCompassDirection MADGeneralDirectionOfDegrees(CGFloat degrees);
static inline CGSize CGSizeFingerDefault(void);
static inline MADLine CGLineMake(CGFloat, CGFloat);
static inline CGPoint CGPointContentOffsetTopOfRect(CGRect);
static inline CGPoint CGPointContentOffsetBottomOfRect(CGRect, CGRect);
__attribute__((unused)) static inline BOOL CGRectAboveRect(CGRect, CGRect);
__attribute__((unused)) static inline BOOL CGRectBelowRect(CGRect, CGRect);
static inline CGPoint CGCenterOfRect(CGRect);
__attribute__((unused)) static inline CGPoint CGRandomPointInRect(CGRect);
__attribute__((unused)) static inline CGRect CGRectForDesiredRect(CGRect, CGRect);
static inline CGPoint CGPointMakeRandomOffscreen(CGFloat);
__attribute__((unused)) static inline CGRect CGRectFrameAtRandomOffscreenLocation(CGSize);
__attribute__((unused)) static inline CGPoint CGPointCenterOfTileInsideRect(CGRect, CGRect, NSInteger, NSInteger, NSInteger, NSInteger, CGFloat, CGFloat);
__attribute__((unused)) static inline CGPoint CGPointRoundPointToGrid(CGPoint);
static inline CGPoint CGCornerTopLeftPointInRect(CGRect);
static inline CGPoint CGCornerTopRightPointInRect(CGRect);
static inline CGPoint CGCornerBottomLeftPointInRect(CGRect);
static inline CGPoint CGCenterRect(CGRect);
static inline CGPoint CGCornerBottomRightPointInRect(CGRect);
static inline CGPoint CGEdgeTopPointInRect(CGRect);
static inline CGPoint CGEdgeRightPointInRect(CGRect);
static inline CGPoint CGEdgeBottomPointInRect(CGRect);
static inline CGPoint CGEdgeLeftPointInRect(CGRect);
__attribute__((unused)) static inline double MGPointsForInches(double);
static inline CGFloat fCGPointsForInches(CGFloat);
static inline CGFloat CGFloatPointsForMillimeters(CGFloat);
__attribute__((unused)) static inline CGFloat CGFloatInchesForPoints(CGFloat);
__attribute__((unused)) static inline CGFloat CGFloatInchesForCentmeters(CGFloat);
__attribute__((unused)) static inline CGFloat CGFloatCentemetersForInches(CGFloat);
__attribute__((unused)) static inline double CGRateOfChange(CGPoint, CGPoint, NSTimeInterval, NSTimeInterval);
__attribute__((unused)) static inline CGPoint CGSlide(CGFloat, CGPoint, CGPoint);
__attribute__((unused)) static inline CGPoint CGLineIntercept(CGPoint, CGPoint, CGPoint, CGPoint);
__attribute__((unused)) static inline BOOL CGSegmentIntercept(CGPoint, CGPoint, CGPoint, CGPoint);
static inline CGRect CGRectAdjustForScale(CGRect, CGFloat);
__attribute__((unused)) static inline double CGDirectionInDegreesFromVelocity(CGPoint);

static inline double square (double x) { return ( (x) * (x) ); }
static inline MADReportPosition MADReportPositionMake(NSUInteger c, NSUInteger t) { MADReportPosition p; p.currentPage = c; p.totalPages = t; return p; }
static inline CGSize MADSizeSquare(CGFloat l) { CGSize s; s.width = l; s.height = l; return s; }
static inline CGRect MADRectOfSize(CGSize s) { CGRect r; r.origin = CGPointZero; r.size = s; return r; }
static inline CGPoint CGRectTopLeft(CGRect r) { return r.origin; }
static inline CGPoint CGRectBottomLeft(CGRect r) { return CGPointMake(r.origin.y + r.size.height, r.origin.x); }
static inline CGPoint CGRectBottomRight(CGRect r) { return CGPointMake(r.origin.y + r.size.height, r.origin.x + r.size.width); }
static inline CGPoint CGRectTopRight(CGRect r) { return CGPointMake(r.origin.y, r.origin.x + r.size.width); }
static inline BOOL CGRectIsOffScreenWest(CGRect r) { return r.origin.x < CGPointZero.x; }
static inline BOOL CGRectIsOffScreenNorth(CGRect r) { return r.origin.y < CGPointZero.y; }
static inline CGRect CGRectFlushLeft(CGRect r) { return CGRectMake(CGPointZero.x, r.origin.y, r.size.width, r.size.height); }
static inline CGRect CGRectFlushTop(CGRect r) { return CGRectMake(r.origin.x, CGPointZero.y, r.size.width, r.size.height); }
static inline BOOL MADDirectionIsHorizontal(MADDirection d) { return d == MADDirectionLeft || d == MADDirectionRight; }
static inline BOOL MADDirectionIsVertical(MADDirection d) { return d == MADDirectionUp || d == MADDirectionDown; }

static inline MADCorners MTCornersMake(CGRect r) {
	MADCorners c;
	c.topLeft = r.origin;
	c.topRight = CGPointMake(r.origin.x + r.size.width, r.origin.y);
	c.bottomLeft = CGPointMake(r.origin.x, r.origin.y + r.size.height);
	c.bottomRight = CGPointMake(r.origin.x + r.size.width, r.origin.y + r.size.height);
	return c;
}

static inline BOOL CGFloatCompare(CGFloat x, CGFloat y) { return (fabs(x-y) < .0001 * FLT_EPSILON * fabs(x+y) || fabs(x-y) < FLT_MIN); }

static inline MADDirection MADDirectionHorizontalDirectionOfPoint(CGPoint p1, CGPoint p2) {
	return CGFloatCompare(p2.x, p1.x) ? MADDirectionNoDirection : p2.x > p1.x ? MADDirectionLeft : MADDirectionRight;
}

static inline MADDirection MADDirectionVerticalDirectionOfPoint(CGPoint p1, CGPoint p2) {
	return CGFloatCompare(p2.x, p1.x) ? MADDirectionNoDirection : p2.y > p1.y ? MADDirectionDown : MADDirectionUp;
}

static inline MADCompassDirection MADGeneralDirectionOfDegrees(CGFloat degrees) {
	while (degrees < 0.0) {
		degrees += 360.0;
	}
	while (degrees > 360.0) {
		degrees -= 360.0;
	}
	if (degrees > 60.0 && degrees < 120.0) {
		return north;
	} else if (degrees > 30.0 && degrees < 60.0) {
		return northEast;
	} else if ( degrees > 120.0 && degrees < 150.0 ) {
		return northWest;
	} else if ( degrees > 240.0 && degrees < 300.0 ) {
		return south;
	} else if ( degrees > 300.0 && degrees < 330.0 ) {
		return southEast;
	} else if ( degrees > 210.0 && degrees < 240.0 ) {
		return southWest;
	} else if ((degrees > 330.0 && degrees < 360.0) || (degrees > 0.0 && degrees < 30.0)) {
		return east;
	} else if ( degrees > 150.0 && degrees < 210.0) {
		return west;
	} else {
		return north;
	}
}

static inline CGSize CGSizeFingerDefault(void) {
	return CGSizeMake(MTDefaultFingerSizeWidth, MTDefaultFingerSizeHeight);
}

static inline MADLine CGLineMake(CGFloat m, CGFloat b) {
	MADLine line; line.m = m; line.b = b; return line;
}

static inline CGPoint CGPointContentOffsetTopOfRect(CGRect rect) {
	CGFloat yOffset = rect.origin.y;
	return CGPointMake(CGPointZero.x, yOffset);
}

static inline CGPoint CGPointContentOffsetBottomOfRect(CGRect rect, CGRect containerRect) {
	CGFloat yOffset = rect.origin.y - containerRect.size.height + rect.size.height;
	return CGPointMake(CGPointZero.x, yOffset);
}

static inline CGFloat CGDelta(CGFloat f1, CGFloat f2) { return f2 - f1; }

__attribute__((unused)) static inline double CGDirectionInDegreesFromVelocity(CGPoint velocity) { return atan2(velocity.y, velocity.x); }

static inline CGRect CGRectAdjustForScale(CGRect r, CGFloat zoomScale) {
	CGFloat scale = 1.0 / zoomScale;
	if ( isless(scale, 1.0) ) {
		r.origin.x *= scale;
		r.origin.y *= scale;
		r.size.width *= scale;
		r.size.height *= scale;
	} else {
		r.origin.x *= zoomScale;
		r.origin.y *= zoomScale;
		r.size.width *= zoomScale;
		r.size.height *= zoomScale;
	}
	return r;
}

__attribute__((unused)) static inline BOOL CGRectAboveRect(CGRect r1, CGRect r2) {
	return r1.origin.y + r1.size.height < r2.origin.y;
}

__attribute__((unused)) static inline BOOL CGRectBelowRect(CGRect r1, CGRect r2) {
	return r1.origin.y > r2.origin.y + r2.size.height;
}

static inline CGPoint CGCenterOfRect(CGRect r) {
	return CGPointMake(r.origin.x + (r.size.width / 2.0), r.origin.y + (r.size.height / 2.0));
}

__attribute__((unused)) static inline CGPoint CGRandomPointInRect(CGRect r) {
	return CGPointMake((arc4random() % (uint32_t)fabs(r.origin.x + r.size.width + 1.0)) + (uint32_t)r.origin.x,
					   (arc4random() % (uint32_t)fabs(r.origin.y + r.size.height + 1.0)) + (uint32_t)r.origin.y);
}

__attribute__((unused)) static inline CGRect CGRectForDesiredRect(CGRect f, CGRect b) {
	if (CGRectContainsRect(b, f) == NO) {
		
		//Is it to the left?
		if (f.origin.x < b.origin.x) {
			f.origin.x = b.origin.x + 20.0;
		}
		
		//Is it to the right?
		if (f.origin.x + f.size.width > b.origin.x + b.size.width) {
			f.origin.x = b.origin.x + b.size.width - f.size.width - 20.0;
		}
		
		//Are you too high?
		if (f.origin.y < b.origin.y) {
			f.origin.y = b.origin.y + 20.0;
		}
		
		//Is it too low?
		if (f.origin.y + f.size.height > b.origin.y + b.size.height) {
			f.origin.y = b.origin.y + b.size.height - f.size.height - 20.0;
		}
	}
	return f;
}

static inline CGPoint CGPointMakeRandomOffscreen(CGFloat offSetSize) {
	return arc4random_uniform(2) == 0 ?
		   (arc4random_uniform(2) == 0 ?
			CGPointMake(arc4random_uniform((uint32_t)MADFloat_1024), 0.0 - offSetSize) :
			CGPointMake(0.0 - offSetSize, arc4random_uniform((uint32_t)MADFloat_1024))) :
		   (arc4random_uniform(2) == 0 ?
			CGPointMake(arc4random_uniform((uint32_t)MADFloat_1024), MADFloat_1024 + offSetSize) :
			CGPointMake(MADFloat_1024 + offSetSize, arc4random_uniform((uint32_t)MADFloat_1024)));
}

__attribute__((unused)) static inline CGRect CGRectFrameAtRandomOffscreenLocation(CGSize s) {
	CGPoint offScreen = CGPointMakeRandomOffscreen(400.0);
	return CGRectMake(offScreen.x, offScreen.y, s.width, s.height);
}

__attribute__((unused)) static inline CGPoint CGPointCenterOfTileInsideRect(CGRect tileRect, CGRect containerRect, NSInteger onRow, NSInteger ofRows, NSInteger andOnCol, NSInteger ofCols, CGFloat withPaddingTop, CGFloat andPaddingBottom) {
	containerRect = CGRectMake(containerRect.origin.x, containerRect.origin.y, containerRect.size.width, containerRect.size.height - withPaddingTop - andPaddingBottom);
	CGFloat moveDistanceX = (containerRect.size.width - (tileRect.size.width * (CGFloat)ofCols)) / (CGFloat)(((ofCols - 1) * 2) + 2);
	CGFloat moveDistanceY = (containerRect.size.height - (tileRect.size.height * (CGFloat)ofRows)) / (CGFloat)(((ofRows - 1) * 2) + 2);
	return CGPointMake((tileRect.size.width * (CGFloat)andOnCol) + (moveDistanceX * (CGFloat)andOnCol * 2) + moveDistanceX,
					   (tileRect.size.width * (CGFloat)onRow) + (moveDistanceY * (CGFloat)onRow * 2) + moveDistanceY + withPaddingTop);
}

__attribute__((unused)) static inline CGPoint CGPointRoundPointToGrid(CGPoint p) {
	return CGPointMake((CGFloat)round(p.x / 10.0) * 10.0, (CGFloat)round(p.y / 10.0) * 10.0);
}

static inline CGPoint CGCornerTopLeftPointInRect(CGRect frame) { return CGPointMake(frame.origin.x, frame.origin.y); }
static inline CGPoint CGCornerTopRightPointInRect(CGRect frame) { return CGPointMake(frame.origin.x + frame.size.width, frame.origin.y); }
static inline CGPoint CGCornerBottomLeftPointInRect(CGRect frame) { return CGPointMake(frame.origin.x, frame.origin.y + frame.size.height); }
static inline CGPoint CGCenterRect(CGRect rect) { return CGPointMake((rect.origin.x + rect.size.width) / 2.0, (rect.origin.y + rect.size.height) / 2.0); }
static inline CGPoint CGCornerBottomRightPointInRect(CGRect frame) { return CGPointMake(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height); }
static inline CGPoint CGEdgeTopPointInRect(CGRect frame) { return CGPointMake(frame.origin.x + (frame.size.width / 2.0), frame.origin.y); }
static inline CGPoint CGEdgeRightPointInRect(CGRect frame) { return CGPointMake(frame.origin.x + frame.size.width, frame.origin.y + (frame.size.height / 2.0)); }

static inline CGPoint CGEdgeBottomPointInRect(CGRect frame) { return CGPointMake(frame.origin.x + (frame.size.width / 2.0), frame.origin.y + frame.size.height); }

static inline CGPoint CGEdgeLeftPointInRect(CGRect frame) { return CGPointMake(frame.origin.x, frame.origin.y + (frame.size.height / 2.0)); }

__attribute__((unused)) static inline double MGPointsForInches(double inches) { return inches * 72.0; }

static inline CGFloat fCGPointsForInches(CGFloat inches) { return inches * 72.00000f; }

static inline CGFloat CGFloatPointsForMillimeters(CGFloat millimeters) { return millimeters * 0.0393701f * 72.0; }

__attribute__((unused)) static inline CGFloat CGFloatInchesForPoints(CGFloat points) { return points / 72.0; }

__attribute__((unused)) static inline CGFloat CGFloatInchesForCentmeters(CGFloat centemeters) { return centemeters / 2.54; }

__attribute__((unused)) static inline CGFloat CGFloatCentemetersForInches(CGFloat inches) { return inches * 2.54; }

__attribute__((unused)) static inline double CGRateOfChange(CGPoint p1, CGPoint p2, NSTimeInterval t1, NSTimeInterval t2) {
	if (t2 - t1 != 0) return (MADDistance(p1, p2) / (CGFloat)((t2 - t1) * 3));
	else return 0;
}

__attribute__((unused)) static inline CGPoint CGSlide(CGFloat rateOfChange, CGPoint p1, CGPoint p2) {
	if (rateOfChange <= 0) { rateOfChange = 1; }
	CGPoint c = CGYInversePlusDistance(p1, p2, rateOfChange);
	if (!isnan(c.x) && !isnan(c.y)) { c.y = (-1) * (c.y); }
	return c;
}

__attribute__((unused)) static inline CGPoint CGLineIntercept(CGPoint p1a, CGPoint p1b, CGPoint p2a, CGPoint p2b) {
	return CGPointMake(
						( (p1a.x * (-p1b.y) - (-p1a.y) * p1b.x) * (p2a.x - p2b.x) - ((  p1a.x  -    p1b.x) * (p2a.x *p2b.y -p2a.y * p2b.x) ) ) / ( (p1a.x - p1b.x) * (p2a.y - p2b.y) - ( ( (-p1a.y) - (-p1b.y) ) * (p2a.x - p2b.x) ) ),
					   -( (p1a.x * (-p1b.y) - (-p1a.y) * p1b.x) * (p2a.y - p2b.y) - (((-p1a.y) - (-p1b.y)) * (p2a.x *p2b.y -p2a.y * p2b.x) ) ) / ( (p1a.x - p1b.x) * (p2a.y - p2b.y) - ( ( (-p1a.y) - (-p1b.y) ) * (p2a.x - p2b.x) ) ) );
	
}

__attribute__((unused)) static inline BOOL CGSegmentIntercept(CGPoint p1a, CGPoint p1b, CGPoint p2a, CGPoint p2b) {
	
	BOOL result = NO;

	//If bounding rects intercept
	if (MAX(p1a.x, p1b.x) >= MIN(p2a.x, p2b.x) &&
		MAX(p2a.x, p2b.x) >= MIN(p1a.x, p1b.x) &&
		MAX(p1a.y, p1b.y) >= MIN(p2a.y, p2b.y) &&
		MAX(p2a.y, p2b.y) >= MIN(p1a.y, p1b.y)) {
		
		//Straddle test
		
		double z1, z2, z3, z4;
		int s1, s2, s3, s4;
		
		if ((z1 = ((p2a.x - p1a.x)*(p1b.y - p1a.y)) - ((p2a.y - p1a.y)*(p1b.x - p1a.x))) < 0)
			s1 = -1;
		else if (z1 > 0)
			s1 = 1;
		else
			s1 = 0;
		
		if ((z2 = ((p2b.x - p1a.x)*(p1b.y - p1a.y)) - ((p2b.y - p1a.y)*(p1b.x - p1a.x))) < 0)
			s2 = -1;
		else if (z2 > 0)
			s2 = 1;
		else
			s2 = 0;
		
		if ((z3 = ((p1a.x - p2a.x)*(p2b.y - p2a.y)) - ((p1a.y - p2a.y)*(p2b.x - p2a.x))) < 0)
			s3 = -1;
		else if (z3 > 0)
			s3 = 1;
		else
			s3 = 0;
		
		if ((z4 = ((p1b.x - p2a.x)*(p2b.y - p2a.y)) - ((p1b.y - p2a.y)*(p2b.x - p2a.x))) < 0)
			s4 = -1;
		else if (z4 > 0)
			s4 = 1;
		else
			s4 = 0;
		
		if ((s1 * s2 <= 0) && (s3 * s4 <= 0))
			result = YES;

	}
	
	return result;
	
}

static inline BOOL MADLineSegmentIntercept(MADLineSegment lineSegment1, MADLineSegment lineSegment2) {
	
	BOOL result =  NO;
	
	//If bounding rects intercept
	if (MAX(lineSegment1.start.x, lineSegment1.end.x) >= MIN(lineSegment2.start.x, lineSegment2.end.x) &&
		MAX(lineSegment2.start.x, lineSegment2.end.x) >= MIN(lineSegment1.start.x, lineSegment1.end.x) &&
		MAX(lineSegment1.start.y, lineSegment1.end.y) >= MIN(lineSegment2.start.y, lineSegment2.end.y) &&
		MAX(lineSegment2.start.y, lineSegment2.end.y) >= MIN(lineSegment1.start.y, lineSegment1.end.y)) {
		
		//Straddle test
		
		double z1, z2, z3, z4;
		int straddleTest1, straddleTest2; int straddleTest3; int straddleTest4;
		
		if ((z1 = ((lineSegment2.start.x - lineSegment1.start.x) *
				   (lineSegment1.end.y - lineSegment1.start.y)) - ((lineSegment2.start.y - lineSegment1.start.y) *
																   (lineSegment1.end.x - lineSegment1.start.x))) < 0)
			straddleTest1 = -1;
		else if (z1 > 0)
			straddleTest1 = 1;
		else
			straddleTest1 = 0;
		
		if ((z2 = ((lineSegment2.end.x - lineSegment1.start.x) *
				   (lineSegment1.end.y - lineSegment1.start.y)) - ((lineSegment2.end.y - lineSegment1.start.y) *
													  (lineSegment1.end.x - lineSegment1.start.x))) < 0)
			straddleTest2 = -1;
		else if (z2 > 0)
			straddleTest2 = 1;
		else
			straddleTest2 = 0;
		
		if ((z3 = ((lineSegment1.start.x - lineSegment2.start.x) *
				   (lineSegment2.end.y - lineSegment2.start.y)) - ((lineSegment1.start.y - lineSegment2.start.y) *
																   (lineSegment2.end.x - lineSegment2.start.x))) < 0)
			straddleTest3 = -1;
		else if (z3 > 0)
			straddleTest3 = 1;
		else
			straddleTest3 = 0;
		
		if ((z4 = ((lineSegment1.end.x - lineSegment2.start.x) *
				   (lineSegment2.end.y - lineSegment2.start.y)) - ((lineSegment1.end.y - lineSegment2.start.y) *
																   (lineSegment2.end.x - lineSegment2.start.x))) < 0)
			straddleTest4 = -1;
		else if (z4 > 0)
			straddleTest4 = 1;
		else
			straddleTest4 = 0;
		
		if ((straddleTest1 * straddleTest2 <= 0) && (straddleTest3 * straddleTest4 <= 0))
			result = YES;
		
	}
	
	return result;
}

#endif
