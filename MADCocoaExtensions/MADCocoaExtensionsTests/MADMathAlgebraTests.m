//
//  MADMathAlgebraTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the inline algebra helpers in MADMathAlgebra.h.
//

#import <XCTest/XCTest.h>

#import <MADCocoaExtensions/MADMathAlgebra.h>
#import <MADCocoaExtensions/MADLineSegment.h>

@interface MADMathAlgebraTests : XCTestCase
@end

@implementation MADMathAlgebraTests

- (void)testAngleBetweenTwoPoints {
	XCTAssertEqualWithAccuracy(CGAngleBetweenTwoPoints(CGPointMake(0, 0), CGPointMake(1, 1)), 45.0, 0.0001);
	XCTAssertEqualWithAccuracy(CGAngleBetweenTwoPoints(CGPointMake(0, 0), CGPointMake(1, 0)), 0.0, 0.0001);
	XCTAssertEqualWithAccuracy(CGAngleBetweenTwoPoints(CGPointMake(0, 0), CGPointMake(0, 1)), 90.0, 0.0001);
}

- (void)testDistance {
	XCTAssertEqualWithAccuracy(MADDistance(CGPointMake(0, 0), CGPointMake(3, 4)), 5.0, 0.0001);
	XCTAssertEqualWithAccuracy(MADDistance(CGPointMake(1, 1), CGPointMake(1, 1)), 0.0, 0.0001);
}

- (void)testSlope {
	XCTAssertEqualWithAccuracy(CGSlope(CGPointMake(0, 0), CGPointMake(2, 4)), 2.0, 0.0001);
	// Vertical line: dx == 0 -> guarded, returns 0.
	XCTAssertEqualWithAccuracy(CGSlope(CGPointMake(0, 0), CGPointMake(0, 5)), 0.0, 0.0001);
}

- (void)testIntercept {
	// Line through (0,0) and (2,4) is y = 2x; the x at y = 4 is 2.
	XCTAssertEqualWithAccuracy(CGIntercept(4.0, CGPointMake(0, 0), CGPointMake(2, 4)), 2.0, 0.0001);
}

- (void)testLineSegmentSlope {
	MADLineSegment segment = MADLineSegmentMake(CGPointMake(0, 0), CGPointMake(2, 4));
	XCTAssertEqualWithAccuracy(MADLineSegmentSlope(segment), 2.0, 0.0001);
}

- (void)testInterceptBySlope {
	// p2 = (3,7), m = 2 -> b = 7 - 2*3 = 1.
	XCTAssertEqualWithAccuracy(CGInterceptBySlope(CGPointMake(3, 7), 2.0), 1.0, 0.0001);
}

- (void)testLineSegmentMake {
	MADLineSegment s = MADLineSegmentMake(CGPointMake(1, 2), CGPointMake(3, 4));
	XCTAssertEqual(s.start.x, (CGFloat)1);
	XCTAssertEqual(s.start.y, (CGFloat)2);
	XCTAssertEqual(s.end.x, (CGFloat)3);
	XCTAssertEqual(s.end.y, (CGFloat)4);
}

- (void)testYInversePlusDistanceNegativeReturnsZero {
	CGPoint p = CGYInversePlusDistance(CGPointMake(0, 0), CGPointMake(10, 0), -1);
	XCTAssertTrue(CGPointEqualToPoint(p, CGPointZero));
}

- (void)testYInversePlusDistanceProducesFinitePoint {
	CGPoint p = CGYInversePlusDistance(CGPointMake(0, 0), CGPointMake(10, 0), 5);
	XCTAssertFalse(isnan(p.x));
	XCTAssertFalse(isnan(p.y));
	XCTAssertFalse(isinf(p.x));
	XCTAssertFalse(isinf(p.y));
}

@end
