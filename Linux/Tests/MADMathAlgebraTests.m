//
//  MADMathAlgebraTests.m
//  Linux/Tests
//
//  Ported from MADCocoaExtensionsTests/MADMathAlgebraTests.m: the inline
//  algebra helpers in MADMathAlgebra.h and the line-segment type.
//

#import "MADTestSupport.h"
#import <MADCocoaExtensions/MADMathAlgebra.h>
#import <MADCocoaExtensions/MADLineSegment.h>

static void testAngleBetweenTwoPoints(void) {
	MAD_PASS(fabs(CGAngleBetweenTwoPoints(CGPointMake(0, 0), CGPointMake(1, 1)) - 45.0) < 0.0001, "a 45-degree diagonal");
	MAD_PASS(fabs(CGAngleBetweenTwoPoints(CGPointMake(0, 0), CGPointMake(1, 0)) - 0.0) < 0.0001, "a horizontal line");
	MAD_PASS(fabs(CGAngleBetweenTwoPoints(CGPointMake(0, 0), CGPointMake(0, 1)) - 90.0) < 0.0001, "a vertical line");
}

static void testDistance(void) {
	MAD_PASS(fabs(MADDistance(CGPointMake(0, 0), CGPointMake(3, 4)) - 5.0) < 0.0001, "the 3-4-5 triangle");
	MAD_PASS(fabs(MADDistance(CGPointMake(1, 1), CGPointMake(1, 1)) - 0.0) < 0.0001, "a point is zero from itself");
}

static void testSlope(void) {
	MAD_PASS(fabs(CGSlope(CGPointMake(0, 0), CGPointMake(2, 4)) - 2.0) < 0.0001, "a slope of 2");
	MAD_PASS(fabs(CGSlope(CGPointMake(0, 0), CGPointMake(0, 5)) - 0.0) < 0.0001, "a vertical line is guarded to zero");
}

static void testIntercept(void) {
	MAD_PASS(fabs(CGIntercept(4.0, CGPointMake(0, 0), CGPointMake(2, 4)) - 2.0) < 0.0001, "the x at y=4 on y=2x");
}

static void testLineSegmentSlope(void) {
	MADLineSegment segment = MADLineSegmentMake(CGPointMake(0, 0), CGPointMake(2, 4));
	MAD_PASS(fabs(MADLineSegmentSlope(segment) - 2.0) < 0.0001, "the segment's slope");
}

static void testInterceptBySlope(void) {
	MAD_PASS(fabs(CGInterceptBySlope(CGPointMake(3, 7), 2.0) - 1.0) < 0.0001, "the intercept from a point and slope");
}

static void testLineSegmentMake(void) {
	MADLineSegment s = MADLineSegmentMake(CGPointMake(1, 2), CGPointMake(3, 4));
	MAD_PASS(s.start.x == (CGFloat)1, "start x");
	MAD_PASS(s.start.y == (CGFloat)2, "start y");
	MAD_PASS(s.end.x == (CGFloat)3, "end x");
	MAD_PASS(s.end.y == (CGFloat)4, "end y");
}

static void testYInversePlusDistanceNegativeReturnsZero(void) {
	CGPoint p = CGYInversePlusDistance(CGPointMake(0, 0), CGPointMake(10, 0), -1);
	MAD_PASS(CGPointEqualToPoint(p, CGPointZero), "a negative distance yields the zero point");
}

static void testYInversePlusDistanceProducesFinitePoint(void) {
	CGPoint p = CGYInversePlusDistance(CGPointMake(0, 0), CGPointMake(10, 0), 5);
	MAD_PASS(!isnan(p.x) && !isnan(p.y), "the coordinates are numbers");
	MAD_PASS(!isinf(p.x) && !isinf(p.y), "the coordinates are finite");
}

MAD_TEST_MAIN("MADMathAlgebraTests",
	MAD_TEST(testAngleBetweenTwoPoints),
	MAD_TEST(testDistance),
	MAD_TEST(testSlope),
	MAD_TEST(testIntercept),
	MAD_TEST(testLineSegmentSlope),
	MAD_TEST(testInterceptBySlope),
	MAD_TEST(testLineSegmentMake),
	MAD_TEST(testYInversePlusDistanceNegativeReturnsZero),
	MAD_TEST(testYInversePlusDistanceProducesFinitePoint));
