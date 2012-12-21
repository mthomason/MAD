//
//  CGGeometry+Extras.h
//  wordPuzzle
//
//  Created by Michael Thomason on 7/13/10.
//  Copyright 2010 Everyday Apps LLC. All rights reserved.
//

/* Make a point from `(x, y)'. */

#define square(x) ( (x) * (x) )

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
	return ((p2.y - p1.y) / (p2.x - p1.x));
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