//
//  CGGeometry+Extras.h
//  wordPuzzle
//
//  Created by Michael Thomason on 7/13/10.
//  Copyright 2010 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_CGGeometry_Extras_h
#define Reports_CGGeometry_Extras_h

#import <CoreGraphics/CGBase.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSDate.h>
#import <CoreGraphics/CGGeometry.h>
#import <stdlib.h>
#import <math.h>

#import <MADCocoaExtensions/MADNumericConstants.h>
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

extern const CGFloat MADFloatZero;
extern const CGFloat MADFloat_64;
extern const CGFloat MADFloat_320;
extern const CGFloat MADFloat_1024;
extern const CGFloat MTDefaultFingerSizeWidth;
extern const CGFloat MTDefaultFingerSizeHeight;

static inline double square (double x);
static inline double square (double x) {
    return ( (x) * (x) );
}

/* Lines. */

struct CGLine {
    CGFloat m;
    CGFloat b;
};
typedef struct CGLine CGLine;

struct MTCorners {
    CGPoint topLeft;
    CGPoint topRight;
    CGPoint bottomLeft;
    CGPoint bottomRight;
};
typedef struct MTCorners MTCorners;

typedef NS_ENUM(NSUInteger, MADDirection) {
    left = 1,
    right,
    up,
    down,
    noDirection
};

static inline CGSize MADSizeSquare(CGFloat length);
static inline CGSize MADSizeSquare(CGFloat length) {
    CGSize s; s.width = length; s.height = length; return s;
}

static inline CGRect MADRectOfSize(CGSize size);
static inline CGRect MADRectOfSize(CGSize size) {
    CGRect r; r.origin = CGPointZero; r.size = size; return r;
}

static inline CGPoint CGRectTopLeft(CGRect rect);
static inline CGPoint CGRectTopLeft(CGRect rect) {
    return rect.origin;
}

static inline CGPoint CGRectBottomLeft(CGRect rect);
static inline CGPoint CGRectBottomLeft(CGRect rect) {
    return CGPointMake(rect.origin.y + rect.size.height, rect.origin.x);
}

static inline CGPoint CGRectBottomRight(CGRect rect);
static inline CGPoint CGRectBottomRight(CGRect rect) {
    return CGPointMake(rect.origin.y + rect.size.height, rect.origin.x + rect.size.width);
}

static inline CGPoint CGRectTopRight(CGRect rect);
static inline CGPoint CGRectTopRight(CGRect rect) {
    return CGPointMake(rect.origin.y, rect.origin.x + rect.size.width);
}

static inline BOOL CGRectIsOffScreenWest(CGRect rect);
static inline BOOL CGRectIsOffScreenWest(CGRect rect) {
    return rect.origin.x < CGPointZero.x;
}
static inline BOOL CGRectIsOffScreenNorth(CGRect rect);
static inline BOOL CGRectIsOffScreenNorth(CGRect rect) {
    return rect.origin.y < CGPointZero.y;
}
static inline CGRect CGRectFlushLeft(CGRect rect);
static inline CGRect CGRectFlushLeft(CGRect rect) {
    return CGRectMake(CGPointZero.x, rect.origin.y, rect.size.width, rect.size.height);
}
static inline CGRect CGRectFlushTop(CGRect rect);
static inline CGRect CGRectFlushTop(CGRect rect) {
    return CGRectMake(rect.origin.x, CGPointZero.y, rect.size.width, rect.size.height);
}

CG_INLINE MTCorners
MTCornersMake(CGRect rect) {
    MTCorners corners;
    corners.topLeft = rect.origin;
    corners.topRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
    corners.bottomLeft = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
    corners.bottomRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    return corners;
}

CG_INLINE BOOL CGFloatCompare(CGFloat x, CGFloat y);
CG_INLINE BOOL
CGFloatCompare(CGFloat x, CGFloat y) {
    return (fabs(x-y) < .0001 * FLT_EPSILON * fabs(x+y) || fabs(x-y) < FLT_MIN);
}

CG_INLINE MADDirection MADDirectionHorizontalDirectionOfPoint(CGPoint p1, CGPoint p2);
CG_INLINE MADDirection MADDirectionHorizontalDirectionOfPoint(CGPoint p1, CGPoint p2) {
    return CGFloatCompare(p2.x, p1.x) ? noDirection : p2.x > p1.x ? left : right;
}

CG_INLINE MADDirection MADDirectionVerticalDirectionOfPoint(CGPoint p1, CGPoint p2);
CG_INLINE MADDirection MADDirectionVerticalDirectionOfPoint(CGPoint p1, CGPoint p2) {
    return CGFloatCompare(p2.x, p1.x) ? noDirection : p2.y > p1.y ? down : up;
}

CG_INLINE BOOL MADDirectionIsHorizontal(MADDirection d);
CG_INLINE BOOL MADDirectionIsHorizontal(MADDirection d) {
    return d == left || d == right;
}

CG_INLINE BOOL MADDirectionIsVertical(MADDirection d);
CG_INLINE BOOL MADDirectionIsVertical(MADDirection d) {
    return d == up || d == down;
}

CG_INLINE MADCompassDirection MADGeneralDirectionOfDegrees(CGFloat degrees);
CG_INLINE MADCompassDirection MADGeneralDirectionOfDegrees(CGFloat degrees) {
    while (degrees < 0.0000f) {
        degrees += 360.0000f;
    }
    while (degrees > 360.0000f) {
        degrees -= 360.0000f;
    }
    if (degrees > 60.0000f && degrees < 120.0000f) {
        return north;
    } else if (degrees > 30.0000f && degrees < 60.0000f) {
        return northEast;
    } else if ( degrees > 120.0000f && degrees < 150.0000f ) {
        return northWest;
    } else if ( degrees > 240.0000f && degrees < 300.0000f ) {
        return south;
    } else if ( degrees > 300.0000f && degrees < 330.0000f ) {
        return southEast;
    } else if ( degrees > 210.0000f && degrees < 240.0000f ) {
        return southWest;
    } else if ((degrees > 330.0000f && degrees < 360.0000f) || (degrees > 0.0000f && degrees < 30.0000f)) {
        return east;
    } else if ( degrees > 150.0000f && degrees < 210.0000f) {
        return west;
    } else {
        return north;
    }
}

CG_INLINE CGSize CGSizeFingerDefault();
CG_INLINE CGSize
CGSizeFingerDefault() {
    return CGSizeMake(MTDefaultFingerSizeWidth, MTDefaultFingerSizeHeight);
}

CG_INLINE CGLine CGLineMake(CGFloat m, CGFloat b);
CG_INLINE CGLine
CGLineMake(CGFloat m, CGFloat b) {
    CGLine line;
    line.m = m;
    line.b = b;
    return line;
}

CG_INLINE CGLineSegment CGLineSegmentMake(CGPoint p1, CGPoint p2);
CG_INLINE CGLineSegment
CGLineSegmentMake(CGPoint p1, CGPoint p2) {
    CGLineSegment lineSegment;
    lineSegment.start = p1;
    lineSegment.end = p2;
    return lineSegment;
}

CG_INLINE CGPoint CGPointContentOffsetTopOfRect(CGRect rect);
CG_INLINE
CGPoint CGPointContentOffsetTopOfRect(CGRect rect) {
    CGFloat yOffset = rect.origin.y;
    return CGPointMake(CGPointZero.x, yOffset);
}

CG_INLINE CGPoint CGPointContentOffsetBottomOfRect(CGRect rect, CGRect containerRect);
CG_INLINE
CGPoint CGPointContentOffsetBottomOfRect(CGRect rect, CGRect containerRect) {
    CGFloat yOffset = rect.origin.y - containerRect.size.height + rect.size.height;
    return CGPointMake(CGPointZero.x, yOffset);
}

CG_INLINE CGFloat CGDelta(CGFloat f1, CGFloat f2) {
    return f2 - f1;
}

CG_INLINE double CGDirectionInDegreesFromVelocity(CGPoint velocity);
CG_INLINE double CGDirectionInDegreesFromVelocity(CGPoint velocity) {
    return atan2(velocity.y, velocity.x);
}

CG_INLINE CGRect CGRectAdjustForScale(CGRect rect, CGFloat zoomScale);
CG_INLINE CGRect
CGRectAdjustForScale(CGRect rect, CGFloat zoomScale) {
    CGFloat scale = 1.0000f / zoomScale;
    if ( isless(scale, 1.0000f) ) {
        rect.origin.x *= scale;
        rect.origin.y *= scale;
        rect.size.width *= scale;
        rect.size.height *= scale;
    } else {
        rect.origin.x *= zoomScale;
        rect.origin.y *= zoomScale;
        rect.size.width *= zoomScale;
        rect.size.height *= zoomScale;
    }
    return rect;
}

CG_INLINE BOOL CGRectAboveRect(CGRect rect1, CGRect rect2);
CG_INLINE BOOL
CGRectAboveRect(CGRect rect1, CGRect rect2) {
    return rect1.origin.y + rect1.size.height < rect2.origin.y;
}

CG_INLINE BOOL CGRectBelowRect(CGRect rect1, CGRect rect2);
CG_INLINE BOOL
CGRectBelowRect(CGRect rect1, CGRect rect2) {
    return rect1.origin.y > rect2.origin.y + rect2.size.height;
}

CG_INLINE CGPoint CGCenterOfRect(CGRect rect);
CG_INLINE CGPoint
CGCenterOfRect(CGRect rect) {
    return CGPointMake(rect.origin.x + (rect.size.width / 2.0000f), rect.origin.y + (rect.size.height / 2.0000f));
}

CG_INLINE CGPoint CGRandomPointInRect(CGRect rect);
CG_INLINE
CGPoint CGRandomPointInRect(CGRect rect) {
    return CGPointMake((random() % (int)fabs(rect.origin.x + rect.size.width + 1.0000f)) + (int)rect.origin.x,
                       (random() % (int)fabs(rect.origin.y + rect.size.height + 1.0000f)) + (int)rect.origin.y);
}

CG_INLINE CGRect CGRectForDesiredRect(CGRect desiredFrame, CGRect viewControllerBounds);
CG_INLINE
CGRect CGRectForDesiredRect(CGRect desiredFrame, CGRect viewControllerBounds) {
    if (CGRectContainsRect(viewControllerBounds, desiredFrame) == NO) {
        
        //Is it to the left?
        if (desiredFrame.origin.x < viewControllerBounds.origin.x) {
            desiredFrame.origin.x = viewControllerBounds.origin.x + 20.0000f;
        }
        
        //Is it to the right?
        if (desiredFrame.origin.x + desiredFrame.size.width > viewControllerBounds.origin.x + viewControllerBounds.size.width) {
            desiredFrame.origin.x = viewControllerBounds.origin.x + viewControllerBounds.size.width - desiredFrame.size.width - 20.0000f;
        }
        
        //Are you too high?
        if (desiredFrame.origin.y < viewControllerBounds.origin.y) {
            desiredFrame.origin.y = viewControllerBounds.origin.y + 20.0000f;
        }
        
        //Is it too low?
        if (desiredFrame.origin.y + desiredFrame.size.height > viewControllerBounds.origin.y + viewControllerBounds.size.height) {
            desiredFrame.origin.y = viewControllerBounds.origin.y + viewControllerBounds.size.height - desiredFrame.size.height - 20.0000f;
        }
    }
    return desiredFrame;
}

CG_INLINE CGPoint CGPointMakeRandomOffscreen(CGFloat offSetSize);
CG_INLINE CGPoint
CGPointMakeRandomOffscreen(CGFloat offSetSize) {
        return rand()%2 == 0 ? (rand()%2 == 0 ? CGPointMake(rand() % (int)MADFloat_1024, 0.0000f - offSetSize) : CGPointMake(0.0000f - offSetSize, rand() % (int)MADFloat_1024)) :
                                rand()%2 == 0 ? CGPointMake(rand() % (int)MADFloat_1024, MADFloat_1024 + offSetSize) : CGPointMake(MADFloat_1024 + offSetSize, rand() % (int)MADFloat_1024);
}

CG_INLINE CGRect CGRectFrameAtRandomOffscreenLocation(CGSize size);
CG_INLINE CGRect
CGRectFrameAtRandomOffscreenLocation(CGSize size) {
    CGPoint offScreen = CGPointMakeRandomOffscreen(400.0000f);
	return CGRectMake(offScreen.x, offScreen.y, size.width, size.height);
}

CG_INLINE CGPoint CGPointCenterOfTileInsideRect(CGRect tileRect, CGRect containerRect, NSInteger onRow, NSInteger ofRows, NSInteger andOnCol, NSInteger ofCols, CGFloat withPaddingTop, CGFloat andPaddingBottom);
CG_INLINE CGPoint
CGPointCenterOfTileInsideRect(CGRect tileRect, CGRect containerRect, NSInteger onRow, NSInteger ofRows, NSInteger andOnCol, NSInteger ofCols, CGFloat withPaddingTop, CGFloat andPaddingBottom) {
	containerRect = CGRectMake(containerRect.origin.x, containerRect.origin.y, containerRect.size.width, containerRect.size.height - withPaddingTop - andPaddingBottom);
	CGFloat moveDistanceX = (containerRect.size.width - (tileRect.size.width * ofCols)) / (((ofCols - 1) * 2) + 2);
	CGFloat moveDistanceY = (containerRect.size.height - (tileRect.size.height * ofRows)) / (((ofRows - 1) * 2) + 2);
	return CGPointMake((tileRect.size.width * andOnCol) + (moveDistanceX * andOnCol * 2) + moveDistanceX,
					   (tileRect.size.width * onRow) + (moveDistanceY * onRow * 2) + moveDistanceY + withPaddingTop);
}

CG_INLINE CGPoint CGPointRoundPointToGrid(CGPoint point);
CG_INLINE CGPoint
CGPointRoundPointToGrid(CGPoint point) {
    return CGPointMake((CGFloat)round(point.x / 10.0000f) * 10.0000f, (CGFloat)round(point.y / 10.0000f) * 10.0000f);
}

CG_INLINE CGPoint CGCornerTopLeftPointInRect(CGRect frame);
CG_INLINE CGPoint
CGCornerTopLeftPointInRect(CGRect frame) {
	return CGPointMake(frame.origin.x,
					   frame.origin.y);
}

CG_INLINE CGPoint CGCornerTopRightPointInRect(CGRect frame);
CG_INLINE CGPoint
CGCornerTopRightPointInRect(CGRect frame) {
	return CGPointMake(frame.origin.x + frame.size.width,
					   frame.origin.y);
}

CG_INLINE CGPoint CGCornerBottomLeftPointInRect(CGRect frame);
CG_INLINE CGPoint
CGCornerBottomLeftPointInRect(CGRect frame) {
	return CGPointMake(frame.origin.x, frame.origin.y + frame.size.height);	
}

CG_INLINE CGPoint CGCenterRect(CGRect rect);
CG_INLINE CGPoint CGCenterRect(CGRect rect) {
    return CGPointMake((rect.origin.x + rect.size.width) / 2.0000f,
                       (rect.origin.y + rect.size.height) / 2.0000f);
}

CG_INLINE CGPoint CGCornerBottomRightPointInRect(CGRect frame);
CG_INLINE CGPoint
CGCornerBottomRightPointInRect(CGRect frame) {
	return CGPointMake(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height);
}

CG_INLINE CGPoint CGEdgeTopPointInRect(CGRect frame);
CG_INLINE CGPoint
CGEdgeTopPointInRect(CGRect frame) {
	return CGPointMake(frame.origin.x + (frame.size.width / 2.0000f),
					   frame.origin.y);
}

CG_INLINE CGPoint CGEdgeRightPointInRect(CGRect frame);
CG_INLINE CGPoint
CGEdgeRightPointInRect(CGRect frame) {
	return CGPointMake(frame.origin.x + frame.size.width,
					   frame.origin.y + (frame.size.height / 2.0000f));
}

CG_INLINE CGPoint CGEdgeBottomPointInRect(CGRect frame);
CG_INLINE CGPoint
CGEdgeBottomPointInRect(CGRect frame) {
	return CGPointMake(frame.origin.x + (frame.size.width / 2.0000f), frame.origin.y + frame.size.height);	
}

CG_INLINE CGPoint CGEdgeLeftPointInRect(CGRect frame);
CG_INLINE CGPoint
CGEdgeLeftPointInRect(CGRect frame) {
	return CGPointMake(frame.origin.x, frame.origin.y + (frame.size.height / 2.0000f));
}

CG_INLINE double MGPointsForInches(double inches);
CG_INLINE double MGPointsForInches(double inches) {
    return inches * 72.0;
}

CG_INLINE CGFloat fCGPointsForInches(CGFloat inches);
CG_INLINE CGFloat fCGPointsForInches(CGFloat inches) {
    return inches * 72.00000f;
}

CG_INLINE CGFloat CGFloatPointsForMillimeters(CGFloat millimeters);

CG_INLINE CGFloat
CGFloatPointsForMillimeters(CGFloat millimeters) {
    return millimeters * 0.0393701f * 72.0000f;
}

CG_INLINE CGFloat CGFloatInchesForPoints(CGFloat points);
CG_INLINE CGFloat CGFloatInchesForPoints(CGFloat points) {
    return points / 72.0000f;
}

CG_INLINE CGFloat CGFloatInchesForCentmeters(CGFloat centemeters);
CG_INLINE CGFloat CGFloatInchesForCentmeters(CGFloat centemeters) {
    return centemeters / 2.5400f;
}

CG_INLINE CGFloat CGFloatCentemetersForInches(CGFloat inches);
CG_INLINE CGFloat CGFloatCentemetersForInches(CGFloat inches) {
    return inches * 2.5400f;
}

CG_INLINE double CGRateOfChange(CGPoint p1, CGPoint p2, NSTimeInterval t1, NSTimeInterval t2);
CG_INLINE double
CGRateOfChange(CGPoint p1, CGPoint p2, NSTimeInterval t1, NSTimeInterval t2) {
	if (t2 - t1 != 0) return (MADDistance(p1, p2) / (CGFloat)((t2 - t1) * 3));
	else return 0;
}

CG_INLINE CGPoint CGSlide(CGFloat rateOfChange, CGPoint p1, CGPoint p2);
CG_INLINE CGPoint
CGSlide(CGFloat rateOfChange, CGPoint p1, CGPoint p2) {

    rateOfChange = rateOfChange;
	if (rateOfChange <= 0) {
        rateOfChange = 1;
    }
	CGPoint c = CGYInversePlusDistance(p1, p2, rateOfChange);
	if (!isnan(c.x) && !isnan(c.y)) {
		c.y = (-1) * (c.y);
	}
	return c;
}

CG_INLINE CGPoint CGLineIntercept(CGPoint point1a, CGPoint point1b, CGPoint point2a, CGPoint point2b);
CG_INLINE CGPoint
CGLineIntercept(CGPoint p1a, CGPoint p1b, CGPoint p2a, CGPoint p2b) {
    
	return CGPointMake(
					    ( (p1a.x * (-p1b.y) - (-p1a.y) * p1b.x) * (p2a.x - p2b.x) - ((  p1a.x  -    p1b.x) * (p2a.x *p2b.y -p2a.y * p2b.x) ) ) / ( (p1a.x - p1b.x) * (p2a.y - p2b.y) - ( ( (-p1a.y) - (-p1b.y) ) * (p2a.x - p2b.x) ) ),
					   -( (p1a.x * (-p1b.y) - (-p1a.y) * p1b.x) * (p2a.y - p2b.y) - (((-p1a.y) - (-p1b.y)) * (p2a.x *p2b.y -p2a.y * p2b.x) ) ) / ( (p1a.x - p1b.x) * (p2a.y - p2b.y) - ( ( (-p1a.y) - (-p1b.y) ) * (p2a.x - p2b.x) ) ) );
    
}

CG_INLINE CGFloat CGFloatMax(CGFloat n1, CGFloat n2);
CG_INLINE CGFloat
CGFloatMax(CGFloat n1, CGFloat n2) {
    return n1 > n2 ? n1 : n2;
}

CG_INLINE CGFloat CGFloatMin(CGFloat n1, CGFloat n2);
CG_INLINE CGFloat
CGFloatMin(CGFloat n1, CGFloat n2) {
    return n1 < n2 ? n1 : n2;
}

static inline bool CGSegmentIntercept(CGPoint point1a, CGPoint point1b, CGPoint point2a, CGPoint point2b);
static inline bool CGSegmentIntercept(CGPoint p1a, CGPoint p1b, CGPoint p2a, CGPoint p2b) {
    
    bool result = false;

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
            result = true;

    }
    
    return result;
    
}

static inline bool CGLineSegmentIntercept(CGLineSegment lineSegment1, CGLineSegment lineSegment2);
static inline bool
CGLineSegmentIntercept(CGLineSegment lineSegment1, CGLineSegment lineSegment2) {
    
    bool result =  false;
    
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
            result = true;
        
    }
    
    return result;
}

#endif
