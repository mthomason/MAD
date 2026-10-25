//
//  MADGeometryExtrasTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the inline geometry helpers in CGGeometry+Extras.h.  The corner
//  helpers and CGCenterRect were once wrong; the tests now pin the corrected
//  values.  CGRectAdjustForScale is deliberately left alone -- see its comment
//  in the header and BUGS.md.
//

#import <XCTest/XCTest.h>

#import <MADCocoaExtensions/CGGeometry+Extras.h>

@interface MADGeometryExtrasTests : XCTestCase
@end

@implementation MADGeometryExtrasTests

static inline BOOL MADPointEqualToPoint(CGPoint a, CGPoint b) {
	return a.x == b.x && a.y == b.y;
}

#pragma mark - Basic factories

- (void)testSquare {
	XCTAssertEqual(square(4.0), 16.0);
	XCTAssertEqual(square(-3.0), 9.0);
}

- (void)testReportPositionMake {
	MADReportPosition p = MADReportPositionMake(2, 5);
	XCTAssertEqual(p.currentPage, (NSUInteger)2);
	XCTAssertEqual(p.totalPages, (NSUInteger)5);
}

- (void)testSizeSquare {
	CGSize s = MADSizeSquare(44);
	XCTAssertEqual(s.width, (CGFloat)44);
	XCTAssertEqual(s.height, (CGFloat)44);
}

- (void)testRectOfSize {
	CGRect r = MADRectOfSize(CGSizeMake(10, 20));
	XCTAssertTrue(CGPointEqualToPoint(r.origin, CGPointZero));
	XCTAssertEqual(r.size.width, (CGFloat)10);
	XCTAssertEqual(r.size.height, (CGFloat)20);
}

#pragma mark - Corners

- (void)testCornerPoints {
	CGRect r = CGRectMake(10, 20, 30, 40);

	XCTAssertTrue(MADPointEqualToPoint(CGCornerTopLeftPointInRect(r), CGPointMake(10, 20)));
	XCTAssertTrue(MADPointEqualToPoint(CGCornerTopRightPointInRect(r), CGPointMake(40, 20)));
	XCTAssertTrue(MADPointEqualToPoint(CGCornerBottomLeftPointInRect(r), CGPointMake(10, 60)));
	XCTAssertTrue(MADPointEqualToPoint(CGCornerBottomRightPointInRect(r), CGPointMake(40, 60)));
}

- (void)testCGRectCornerFunctions {
	// Agrees with the CGCorner*PointInRect variants below.
	CGRect r = CGRectMake(10, 20, 30, 40);

	XCTAssertTrue(MADPointEqualToPoint(CGRectTopLeft(r), CGPointMake(10, 20)));
	XCTAssertTrue(MADPointEqualToPoint(CGRectTopRight(r), CGPointMake(40, 20)));
	XCTAssertTrue(MADPointEqualToPoint(CGRectBottomLeft(r), CGPointMake(10, 60)));
	XCTAssertTrue(MADPointEqualToPoint(CGRectBottomRight(r), CGPointMake(40, 60)));
}

#pragma mark - Centers

- (void)testCenterOfRect {
	CGRect r = CGRectMake(10, 20, 30, 40);
	XCTAssertTrue(MADPointEqualToPoint(CGCenterOfRect(r), CGPointMake(25, 40)));
}

- (void)testCenterRect {
	// Now agrees with CGCenterOfRect, including for a non-zero origin.
	CGRect r = CGRectMake(10, 20, 30, 40);
	XCTAssertTrue(MADPointEqualToPoint(CGCenterRect(r), CGPointMake(25, 40)));

	CGRect zeroOrigin = CGRectMake(0, 0, 30, 40);
	XCTAssertTrue(MADPointEqualToPoint(CGCenterRect(zeroOrigin), CGPointMake(15, 20)));
}

#pragma mark - Offscreen / flush

- (void)testOffscreen {
	XCTAssertTrue(CGRectIsOffScreenWest(CGRectMake(-5, 0, 10, 10)));
	XCTAssertFalse(CGRectIsOffScreenWest(CGRectMake(5, 0, 10, 10)));
	XCTAssertTrue(CGRectIsOffScreenNorth(CGRectMake(0, -5, 10, 10)));
	XCTAssertFalse(CGRectIsOffScreenNorth(CGRectMake(0, 5, 10, 10)));
}

- (void)testFlush {
	CGRect r = CGRectMake(10, 20, 30, 40);
	XCTAssertTrue(MADPointEqualToPoint(CGRectFlushLeft(r).origin, CGPointMake(0, 20)));
	XCTAssertTrue(MADPointEqualToPoint(CGRectFlushTop(r).origin, CGPointMake(10, 0)));
}

#pragma mark - Compare

- (void)testCGFloatCompare {
	XCTAssertTrue(CGFloatCompare(1.0, 1.0));
	XCTAssertFalse(CGFloatCompare(1.0, 2.0));
}

#pragma mark - General direction

- (void)testGeneralDirectionOfDegrees {
	XCTAssertEqual(MADGeneralDirectionOfDegrees(90), north);
	XCTAssertEqual(MADGeneralDirectionOfDegrees(45), northEast);
	XCTAssertEqual(MADGeneralDirectionOfDegrees(135), northWest);
	XCTAssertEqual(MADGeneralDirectionOfDegrees(270), south);
	XCTAssertEqual(MADGeneralDirectionOfDegrees(315), southEast);
	XCTAssertEqual(MADGeneralDirectionOfDegrees(225), southWest);
	XCTAssertEqual(MADGeneralDirectionOfDegrees(15), east);
	XCTAssertEqual(MADGeneralDirectionOfDegrees(180), west);
	// Exact octant boundaries no longer fall through to north: each belongs to
	// the octant it starts.
	XCTAssertEqual(MADGeneralDirectionOfDegrees(0), east);
	XCTAssertEqual(MADGeneralDirectionOfDegrees(360), east);
	XCTAssertEqual(MADGeneralDirectionOfDegrees(30), northEast);
	XCTAssertEqual(MADGeneralDirectionOfDegrees(60), north);
	XCTAssertEqual(MADGeneralDirectionOfDegrees(330), east);
}

#pragma mark - Finger size / line / content offsets

- (void)testFingerDefaultSize {
	CGSize s = CGSizeFingerDefault();
	XCTAssertEqual(s.width, (CGFloat)44);
	XCTAssertEqual(s.height, (CGFloat)44);
}

- (void)testLineMake {
	MADLine line = CGLineMake(2, 3);
	XCTAssertEqual(line.m, (CGFloat)2);
	XCTAssertEqual(line.b, (CGFloat)3);
}

- (void)testContentOffsets {
	CGRect rect = CGRectMake(10, 20, 30, 40);
	CGRect container = CGRectMake(0, 0, 0, 100);
	XCTAssertTrue(MADPointEqualToPoint(CGPointContentOffsetTopOfRect(rect), CGPointMake(0, 20)));
	XCTAssertTrue(MADPointEqualToPoint(CGPointContentOffsetBottomOfRect(rect, container), CGPointMake(0, -40)));
}

#pragma mark - Above / below

- (void)testAboveAndBelow {
	CGRect a = CGRectMake(0, 0, 10, 10);
	CGRect b = CGRectMake(0, 20, 10, 10);
	XCTAssertTrue(CGRectAboveRect(a, b));
	XCTAssertTrue(CGRectBelowRect(b, a));
	XCTAssertFalse(CGRectAboveRect(b, a));
}

#pragma mark - Unit conversions

- (void)testPointsForInches {
	XCTAssertEqual(fCGPointsForInches(1), (CGFloat)72);
	XCTAssertEqual(CGFloatInchesForPoints(72), (CGFloat)1);
}

- (void)testPointsForMillimeters {
	XCTAssertEqualWithAccuracy(CGFloatPointsForMillimeters(25.4), (CGFloat)72, (CGFloat)0.01);
}

#pragma mark - Scale / rounding

- (void)testAdjustForScale {
	// Deliberate: both branches shrink. The two MADDesignerScrollView callers
	// each reach a different branch on purpose; see BUGS.md before changing this.
	CGRect r = CGRectMake(10, 20, 100, 200);
	CGRect zoomIn = CGRectAdjustForScale(r, 2.0);
	XCTAssertEqual(zoomIn.size.width, (CGFloat)50);
	XCTAssertEqual(zoomIn.size.height, (CGFloat)100);

	CGRect zoomOut = CGRectAdjustForScale(r, 0.5);
	XCTAssertEqual(zoomOut.size.width, (CGFloat)50);
	XCTAssertEqual(zoomOut.size.height, (CGFloat)100);
}

- (void)testRoundPointToGrid {
	XCTAssertTrue(MADPointEqualToPoint(CGPointRoundPointToGrid(CGPointMake(14, 16)), CGPointMake(10, 20)));
}

#pragma mark - Corners struct / edges

- (void)testCornersMake {
	CGRect r = CGRectMake(10, 20, 30, 40);
	MADCorners c = MTCornersMake(r);
	XCTAssertTrue(MADPointEqualToPoint(c.topLeft, CGPointMake(10, 20)));
	XCTAssertTrue(MADPointEqualToPoint(c.topRight, CGPointMake(40, 20)));
	XCTAssertTrue(MADPointEqualToPoint(c.bottomLeft, CGPointMake(10, 60)));
	XCTAssertTrue(MADPointEqualToPoint(c.bottomRight, CGPointMake(40, 60)));
}

- (void)testEdgePoints {
	CGRect r = CGRectMake(10, 20, 30, 40);
	XCTAssertTrue(MADPointEqualToPoint(CGEdgeTopPointInRect(r), CGPointMake(25, 20)));
	XCTAssertTrue(MADPointEqualToPoint(CGEdgeRightPointInRect(r), CGPointMake(40, 40)));
	XCTAssertTrue(MADPointEqualToPoint(CGEdgeBottomPointInRect(r), CGPointMake(25, 60)));
	XCTAssertTrue(MADPointEqualToPoint(CGEdgeLeftPointInRect(r), CGPointMake(10, 40)));
}

@end
