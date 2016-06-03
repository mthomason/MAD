//
//  MADMathAlgebra.h
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADMathAlgebra_h
#define MADMathAlgebra_h

#import "MADLineSegment.h"

static inline double CGAngleBetweenTwoPoints(CGPoint p1, CGPoint p2);
static inline double CGAngleBetweenTwoPoints(CGPoint p1, CGPoint p2) {
    return atan2(p2.y - p1.y, p2.x - p1.x) * (180.0000 / M_PI);
}

static inline double MADDistance(CGPoint p1, CGPoint p2);
static inline double MADDistance(CGPoint p1, CGPoint p2) {
    return sqrt(pow((p2.x - p1.x), 2) + pow((p2.y - p1.y), 2));
}

static inline CGFloat CGSlope(CGPoint p1, CGPoint p2);
static inline CGFloat CGSlope(CGPoint p1, CGPoint p2) {
    CGFloat d = (p2.x - p1.x);
    return d > FLT_EPSILON ? ((p2.y - p1.y) / d) : 0.0000f;
}

static inline CGFloat CGIntercept(CGFloat y, CGPoint p1, CGPoint p2);
static inline CGFloat CGIntercept(CGFloat y, CGPoint p1, CGPoint p2) {
    //y = m x + b;
    CGFloat m = ((p2.y - p1.y) / (p2.x - p1.x));
    CGFloat b = p1.y - (m * p1.x);
    return (y - b) / m;
}

static inline CGFloat CGLineSegmentSlope(CGLineSegment lineSegment);
static inline CGFloat CGLineSegmentSlope(CGLineSegment lineSegment) {
    return CGSlope(lineSegment.start, lineSegment.end);
}

static inline double CGInterceptBySlope(CGPoint p2, double m);
static inline double CGInterceptBySlope(CGPoint p2, double m) {
    return (p2.y - (m * p2.x));
}

static inline CGPoint CGYInversePlusDistance(CGPoint p1, CGPoint p2, CGFloat d);
static inline CGPoint CGYInversePlusDistance(CGPoint p1, CGPoint p2, CGFloat d) {
    CGPoint returnVal = CGPointZero;
    double m = -1 * MADDistance(p1, p2);
    double b = CGInterceptBySlope(p2, m);
    double x = p2.x;
    double y = p2.y;
    bool movingUp = p1.y < p2.y;
    
    if (d >= 0) {
        double mPow2 = pow(m, 2);
        double bPow2 = pow(b, 2);
        double dPow2 = pow(d, 2);
        double u = p2.x;
        double v = p2.y;
        double sqrtPart = 0.0;
        sqrtPart = (mPow2)*( ((-1)*(bPow2)) + ((dPow2)*(1+mPow2)) -
                            (pow((((-1)*(m)*(u)) + v),2)) + (b*(((-1)*(2)*(m)*(u))+((2)*(v)))) );
        if (!isnan(sqrtPart)) {
            if (movingUp) y = ((b)+((m)*(u))+((mPow2)*(v))+sqrt(sqrtPart)) / (1+mPow2);
            else y = ((b)+((m)*(u))+((mPow2)*(v))-sqrt(sqrtPart)) / (1+mPow2);
            
            x=(y-b)/m;
        }
        if (!isnan(x) && !isnan(y)) {
            returnVal.x = (CGFloat)x;
            returnVal.y = (CGFloat)y;
        } else {
            returnVal.x = p2.x;
            returnVal.y = p2.y;
        }
    }
    return returnVal;
}

#endif /* MADMathAlgebra_h */
