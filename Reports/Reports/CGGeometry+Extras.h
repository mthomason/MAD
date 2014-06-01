//
//  CGGeometry+Extras.h
//  wordPuzzle
//
//  Created by Michael Thomason on 7/13/10.
//  Copyright 2010 Everyday Apps LLC. All rights reserved.
//

#import "Constants.h"

/* Make a point from `(x, y)'. */

#define            SQUARE(x)             ( (x) * (x) )

//#define            MIN(x, y)             (((x) < (y)) ? (x) : (y))
//#define            MAX(x, y)             (((x) > (y)) ? (x) : (y))

#define            DEGTORAD(deg)         (((deg) * 2.0 * PI) / 360.0)
#define            RADTODEG(rad)         (((rad) * 360.0) / (2.0 * PI))

/* Lines. */

struct CGLine {
    CGFloat m;
    CGFloat b;
};
typedef struct CGLine CGLine;

struct CGLineSegment {
    CGPoint start;
    CGPoint end;
};
typedef struct CGLineSegment CGLineSegment;

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

CG_INLINE CGPoint CGPointMakeRandomOffscreen();
CG_INLINE CGPoint
CGPointMakeRandomOffscreen() {
	CGPoint offScreen;
	CGFloat offSetSize = 200.0000f * 2;
	if (rand()%2 == 0) {
		if (rand()%2 == 0) {
			//offscreen top
			offScreen = CGPointMake(rand() % (int)1024.0000f, 0.0000f - offSetSize);
		} else {
			//offscreen left
			offScreen = CGPointMake(0.0000f - offSetSize, rand() % (int)1024.0000f);
		}
		
	} else {
		if (rand()%2 == 0) {
			//offscreen bottom
			offScreen = CGPointMake(rand() % (int)1024.0000f, 1024.0000f + offSetSize);
		} else {
			//offscreen right
			offScreen = CGPointMake(1024.0000f + offSetSize, rand() % (int)1024.0000f);
		}
	}
	return offScreen;
}

CG_INLINE CGRect CGRectFrameAtRandomOffscreenLocation(CGSize size);
CG_INLINE CGRect
CGRectFrameAtRandomOffscreenLocation(CGSize size) {
    CGPoint offScreen = CGPointMakeRandomOffscreen();
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
    return CGPointMake(roundf(point.x / 10.0000f) * 10.0000f, roundf(point.y / 10.0000f) * 10.0000f);
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

CG_INLINE CGFloat CGFloatPointsForInches(CGFloat inches);

CG_INLINE CGFloat
CGFloatPointsForInches(CGFloat inches) {
    return inches * 72.0000f;
}

CG_INLINE CGFloat CGFloatPointsForMillimeters(CGFloat millimeters);

CG_INLINE CGFloat
CGFloatPointsForMillimeters(CGFloat millimeters) {
    CGFloat inches = millimeters * 0.0393701f;
    return inches * 72.0000f;
}

CG_INLINE CGFloat CGFloatInchesForPoints(CGFloat points);

CG_INLINE CGFloat
CGFloatInchesForPoints(CGFloat points) {
    return points / 72.0000f;
}

CG_INLINE CGFloat CGFloatInchesForCentmeters(CGFloat centemeters);

CG_INLINE CGFloat
CGFloatInchesForCentmeters(CGFloat centemeters) {
    return centemeters / 2.5400f;
}

CG_INLINE CGFloat CGFloatCentemetersForInches(CGFloat inches);

CG_INLINE CGFloat
CGFloatCentemetersForInches(CGFloat inches) {
    return inches * 2.5400f;
}

CG_INLINE CGFloat CGIntercept(CGFloat y, CGPoint p1, CGPoint p2);

CG_INLINE CGFloat
CGIntercept(CGFloat y, CGPoint p1, CGPoint p2) {
	//y = m x + b;
	CGFloat m = ((p2.y - p1.y) / (p2.x - p1.x));
	CGFloat b = p1.y - (m * p1.x);
	return (y - b) / m;
}

CG_INLINE CGFloat CGDistance(CGPoint p1, CGPoint p2);
CG_INLINE CGFloat
CGDistance(CGPoint p1, CGPoint p2) {
	return sqrt(pow((p2.x - p1.x), 2) + pow((p2.y - p1.y), 2));
}

CG_INLINE CGFloat CGSlope(CGPoint p1, CGPoint p2);
CG_INLINE CGFloat
CGSlope(CGPoint p1, CGPoint p2) {
    CGFloat d = (p2.x - p1.x);
	return d > FLT_EPSILON ? ((p2.y - p1.y) / d) : 0.0000f;
}

CG_INLINE CGFloat CGLineSegmentSlope(CGLineSegment lineSegment);
CG_INLINE CGFloat
CGLineSegmentSlope(CGLineSegment lineSegment) {
	return CGSlope(lineSegment.start, lineSegment.end);
}

CG_INLINE CGFloat CGInterceptBySlope(CGPoint p2, CGFloat m);
CG_INLINE CGFloat CGInterceptBySlope(CGPoint p2, CGFloat m) {
	return (p2.y - (m * p2.x));
}

CG_INLINE CGFloat CGRateOfChange(CGPoint p1, CGPoint p2, NSTimeInterval t1, NSTimeInterval t2);
CG_INLINE CGFloat
CGRateOfChange(CGPoint p1, CGPoint p2, NSTimeInterval t1, NSTimeInterval t2) {
	if (t2 - t1 != 0) return (CGDistance(p1, p2) / ((t2 - t1) * 3));
	else return 0;
}

CG_INLINE CGPoint CGYInversePlusDistance(CGPoint p1, CGPoint p2, long d);
CG_INLINE CGPoint CGYInversePlusDistance(CGPoint p1, CGPoint p2, long d) {
	CGPoint returnVal;
	long double m = -1 * CGDistance(p1, p2);
	long double b = CGInterceptBySlope(p2, m);
	BOOL movingUp;
	if (p1.y < p2.y) movingUp = YES;
        else movingUp = NO;
            
            long double x = p2.x;
            long double y = p2.y;
            
            if (d >= 0) {		
                long double mPow2 = pow(m, 2);
                long double bPow2 = pow(b, 2);
                long double dPow2 = pow(d, 2);
                long double u = p2.x;
                long double v = p2.y;
                long double sqrtPart = 0.0;
                sqrtPart = (mPow2)*( ((-1)*(bPow2)) + ((dPow2)*(1+mPow2)) - (pow((((-1)*(m)*(u)) + v),2)) + (b*(((-1)*(2)*(m)*(u))+((2)*(v)))) );
                if (!isnan(sqrtPart)) {
                    if (movingUp) y = ((b)+((m)*(u))+((mPow2)*(v))+sqrt(sqrtPart)) / (1+mPow2);
                        else y = ((b)+((m)*(u))+((mPow2)*(v))-sqrt(sqrtPart)) / (1+mPow2);
                            
                            x=(y-b)/m;
                            }
                if (!isnan(x) && !isnan(y)) {
                    returnVal.x = x;
                    returnVal.y = y;
                } else {
                    returnVal.x = p2.x;
                    returnVal.y = p2.y;			
                }
            }
	return returnVal;
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

CG_INLINE BOOL CGFloatCompare(CGFloat x, CGFloat y);
CG_INLINE BOOL
CGFloatCompare(CGFloat x, CGFloat y) {
    return (fabs(x-y) < .0001 * FLT_EPSILON * fabs(x+y) || fabs(x-y) < FLT_MIN);
}

CG_INLINE BOOL CGFloatMax(CGFloat n1, CGFloat n2);
CG_INLINE BOOL
CGFloatMax(CGFloat n1, CGFloat n2) {
    return n1 > n2 ? n1 : n2;
}

CG_INLINE BOOL CGFloatMin(CGFloat n1, CGFloat n2);
CG_INLINE BOOL
CGFloatMin(CGFloat n1, CGFloat n2) {
    return n1 < n2 ? n1 : n2;
}

CG_INLINE BOOL CGSegmentIntercept(CGPoint point1a, CGPoint point1b, CGPoint point2a, CGPoint point2b);
CG_INLINE BOOL
CGSegmentIntercept(CGPoint p1a, CGPoint p1b, CGPoint p2a, CGPoint p2b) {
    
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

CG_INLINE BOOL CGLineSegmentIntercept(CGLineSegment lineSegment1, CGLineSegment lineSegment2);
CG_INLINE BOOL
CGLineSegmentIntercept(CGLineSegment lineSegment1, CGLineSegment lineSegment2) {
    
    BOOL result = NO;
    
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
