//
//  MADGeometryExtrasTests.m
//  Linux/Tests
//
//  Ported from MADCocoaExtensionsTests/MADGeometryExtrasTests.m: the inline
//  geometry helpers in CGGeometry+Extras.h.  CGRectAdjustForScale is pinned
//  deliberately as it is -- see its comment in the header and BUGS.md.
//

#import "MADTestSupport.h"
#import <MADCocoaExtensions/CGGeometry+Extras.h>

static BOOL MADPointEqualToPoint(CGPoint a, CGPoint b) {
	return a.x == b.x && a.y == b.y;
}

#pragma mark - Basic factories

static void testSquare(void) {
	MAD_PASS(square(4.0) == 16.0, "four squared is sixteen");
	MAD_PASS(square(-3.0) == 9.0, "minus three squared is nine");
}

static void testReportPositionMake(void) {
	MADReportPosition p = MADReportPositionMake(2, 5);
	MAD_PASS(p.currentPage == (NSUInteger)2, "the current page comes back");
	MAD_PASS(p.totalPages == (NSUInteger)5, "the total page count comes back");
}

static void testSizeSquare(void) {
	CGSize s = MADSizeSquare(44);
	MAD_PASS(s.width == (CGFloat)44, "the width is the side");
	MAD_PASS(s.height == (CGFloat)44, "the height is the side");
}

static void testRectOfSize(void) {
	CGRect r = MADRectOfSize(CGSizeMake(10, 20));
	MAD_PASS(MADPointEqualToPoint(r.origin, CGPointZero), "the origin is zero");
	MAD_PASS(r.size.width == (CGFloat)10, "the width comes back");
	MAD_PASS(r.size.height == (CGFloat)20, "the height comes back");
}

#pragma mark - Corners

static void testCornerPoints(void) {
	CGRect r = CGRectMake(10, 20, 30, 40);
	MAD_PASS(MADPointEqualToPoint(CGCornerTopLeftPointInRect(r), CGPointMake(10, 20)), "the top-left corner");
	MAD_PASS(MADPointEqualToPoint(CGCornerTopRightPointInRect(r), CGPointMake(40, 20)), "the top-right corner");
	MAD_PASS(MADPointEqualToPoint(CGCornerBottomLeftPointInRect(r), CGPointMake(10, 60)), "the bottom-left corner");
	MAD_PASS(MADPointEqualToPoint(CGCornerBottomRightPointInRect(r), CGPointMake(40, 60)), "the bottom-right corner");
}

static void testCGRectCornerFunctions(void) {
	CGRect r = CGRectMake(10, 20, 30, 40);
	MAD_PASS(MADPointEqualToPoint(CGRectTopLeft(r), CGPointMake(10, 20)), "the top-left agrees with the corner helper");
	MAD_PASS(MADPointEqualToPoint(CGRectTopRight(r), CGPointMake(40, 20)), "the top-right agrees");
	MAD_PASS(MADPointEqualToPoint(CGRectBottomLeft(r), CGPointMake(10, 60)), "the bottom-left agrees");
	MAD_PASS(MADPointEqualToPoint(CGRectBottomRight(r), CGPointMake(40, 60)), "the bottom-right agrees");
}

#pragma mark - Centers

static void testCenterOfRect(void) {
	CGRect r = CGRectMake(10, 20, 30, 40);
	MAD_PASS(MADPointEqualToPoint(CGCenterOfRect(r), CGPointMake(25, 40)), "the center of a non-zero-origin rect");
}

static void testCenterRect(void) {
	CGRect r = CGRectMake(10, 20, 30, 40);
	MAD_PASS(MADPointEqualToPoint(CGCenterRect(r), CGPointMake(25, 40)), "the center agrees with CGCenterOfRect");
	CGRect zeroOrigin = CGRectMake(0, 0, 30, 40);
	MAD_PASS(MADPointEqualToPoint(CGCenterRect(zeroOrigin), CGPointMake(15, 20)), "the center at the origin");
}

#pragma mark - Offscreen / flush

static void testOffscreen(void) {
	MAD_PASS(CGRectIsOffScreenWest(CGRectMake(-5, 0, 10, 10)), "a rect starting west of zero is offscreen");
	MAD_PASS(!CGRectIsOffScreenWest(CGRectMake(5, 0, 10, 10)), "a rect inside is not offscreen");
	MAD_PASS(CGRectIsOffScreenNorth(CGRectMake(0, -5, 10, 10)), "a rect starting north of zero is offscreen");
	MAD_PASS(!CGRectIsOffScreenNorth(CGRectMake(0, 5, 10, 10)), "a rect below is not offscreen");
}

static void testFlush(void) {
	CGRect r = CGRectMake(10, 20, 30, 40);
	MAD_PASS(MADPointEqualToPoint(CGRectFlushLeft(r).origin, CGPointMake(0, 20)), "flushing left keeps y");
	MAD_PASS(MADPointEqualToPoint(CGRectFlushTop(r).origin, CGPointMake(10, 0)), "flushing top keeps x");
}

#pragma mark - Compare

static void testCGFloatCompare(void) {
	MAD_PASS(CGFloatCompare(1.0, 1.0), "equal values compare true");
	MAD_PASS(!CGFloatCompare(1.0, 2.0), "unequal values compare false");
}

#pragma mark - General direction

static void testGeneralDirectionOfDegrees(void) {
	MAD_PASS(MADGeneralDirectionOfDegrees(90) == north, "90 is north");
	MAD_PASS(MADGeneralDirectionOfDegrees(45) == northEast, "45 is northEast");
	MAD_PASS(MADGeneralDirectionOfDegrees(135) == northWest, "135 is northWest");
	MAD_PASS(MADGeneralDirectionOfDegrees(270) == south, "270 is south");
	MAD_PASS(MADGeneralDirectionOfDegrees(315) == southEast, "315 is southEast");
	MAD_PASS(MADGeneralDirectionOfDegrees(225) == southWest, "225 is southWest");
	MAD_PASS(MADGeneralDirectionOfDegrees(15) == east, "15 is east");
	MAD_PASS(MADGeneralDirectionOfDegrees(180) == west, "180 is west");
	MAD_PASS(MADGeneralDirectionOfDegrees(0) == east, "the 0 boundary belongs to east");
	MAD_PASS(MADGeneralDirectionOfDegrees(360) == east, "the 360 boundary belongs to east");
	MAD_PASS(MADGeneralDirectionOfDegrees(30) == northEast, "the 30 boundary belongs to northEast");
	MAD_PASS(MADGeneralDirectionOfDegrees(60) == north, "the 60 boundary belongs to north");
	MAD_PASS(MADGeneralDirectionOfDegrees(330) == east, "the 330 boundary belongs to east");
}

#pragma mark - Finger size / line / content offsets

static void testFingerDefaultSize(void) {
	CGSize s = CGSizeFingerDefault();
	MAD_PASS(s.width == (CGFloat)44, "the default finger width");
	MAD_PASS(s.height == (CGFloat)44, "the default finger height");
}

static void testLineMake(void) {
	MADLine line = CGLineMake(2, 3);
	MAD_PASS(line.m == (CGFloat)2, "the slope comes back");
	MAD_PASS(line.b == (CGFloat)3, "the intercept comes back");
}

static void testContentOffsets(void) {
	CGRect rect = CGRectMake(10, 20, 30, 40);
	CGRect container = CGRectMake(0, 0, 0, 100);
	MAD_PASS(MADPointEqualToPoint(CGPointContentOffsetTopOfRect(rect), CGPointMake(0, 20)), "the top content offset");
	MAD_PASS(MADPointEqualToPoint(CGPointContentOffsetBottomOfRect(rect, container), CGPointMake(0, -40)),
			 "the bottom content offset");
}

#pragma mark - Above / below

static void testAboveAndBelow(void) {
	CGRect a = CGRectMake(0, 0, 10, 10);
	CGRect b = CGRectMake(0, 20, 10, 10);
	MAD_PASS(CGRectAboveRect(a, b), "a is above b");
	MAD_PASS(CGRectBelowRect(b, a), "b is below a");
	MAD_PASS(!CGRectAboveRect(b, a), "b is not above a");
}

#pragma mark - Unit conversions

static void testPointsForInches(void) {
	MAD_PASS(fCGPointsForInches(1) == (CGFloat)72, "an inch is 72 points");
	MAD_PASS(CGFloatInchesForPoints(72) == (CGFloat)1, "72 points is an inch");
}

static void testPointsForMillimeters(void) {
	MAD_PASS(fabs(CGFloatPointsForMillimeters(25.4) - (CGFloat)72) < (CGFloat)0.01, "25.4 mm is 72 points");
}

#pragma mark - Scale / rounding

static void testAdjustForScale(void) {
	// Deliberate: both branches shrink. The two MADDesignerScrollView callers
	// each reach a different branch on purpose; see BUGS.md before changing.
	CGRect r = CGRectMake(10, 20, 100, 200);
	CGRect zoomIn = CGRectAdjustForScale(r, 2.0);
	MAD_PASS(zoomIn.size.width == (CGFloat)50, "zooming in halves the width");
	MAD_PASS(zoomIn.size.height == (CGFloat)100, "zooming in halves the height");

	CGRect zoomOut = CGRectAdjustForScale(r, 0.5);
	MAD_PASS(zoomOut.size.width == (CGFloat)50, "zooming out halves the width");
	MAD_PASS(zoomOut.size.height == (CGFloat)100, "zooming out halves the height");
}

static void testRoundPointToGrid(void) {
	MAD_PASS(MADPointEqualToPoint(CGPointRoundPointToGrid(CGPointMake(14, 16)), CGPointMake(10, 20)),
			 "the point rounds to the nearest grid line");
}

#pragma mark - Corners struct / edges

static void testCornersMake(void) {
	CGRect r = CGRectMake(10, 20, 30, 40);
	MADCorners c = MTCornersMake(r);
	MAD_PASS(MADPointEqualToPoint(c.topLeft, CGPointMake(10, 20)), "the top-left corner");
	MAD_PASS(MADPointEqualToPoint(c.topRight, CGPointMake(40, 20)), "the top-right corner");
	MAD_PASS(MADPointEqualToPoint(c.bottomLeft, CGPointMake(10, 60)), "the bottom-left corner");
	MAD_PASS(MADPointEqualToPoint(c.bottomRight, CGPointMake(40, 60)), "the bottom-right corner");
}

static void testEdgePoints(void) {
	CGRect r = CGRectMake(10, 20, 30, 40);
	MAD_PASS(MADPointEqualToPoint(CGEdgeTopPointInRect(r), CGPointMake(25, 20)), "the top edge midpoint");
	MAD_PASS(MADPointEqualToPoint(CGEdgeRightPointInRect(r), CGPointMake(40, 40)), "the right edge midpoint");
	MAD_PASS(MADPointEqualToPoint(CGEdgeBottomPointInRect(r), CGPointMake(25, 60)), "the bottom edge midpoint");
	MAD_PASS(MADPointEqualToPoint(CGEdgeLeftPointInRect(r), CGPointMake(10, 40)), "the left edge midpoint");
}

MAD_TEST_MAIN("MADGeometryExtrasTests",
	MAD_TEST(testSquare),
	MAD_TEST(testReportPositionMake),
	MAD_TEST(testSizeSquare),
	MAD_TEST(testRectOfSize),
	MAD_TEST(testCornerPoints),
	MAD_TEST(testCGRectCornerFunctions),
	MAD_TEST(testCenterOfRect),
	MAD_TEST(testCenterRect),
	MAD_TEST(testOffscreen),
	MAD_TEST(testFlush),
	MAD_TEST(testCGFloatCompare),
	MAD_TEST(testGeneralDirectionOfDegrees),
	MAD_TEST(testFingerDefaultSize),
	MAD_TEST(testLineMake),
	MAD_TEST(testContentOffsets),
	MAD_TEST(testAboveAndBelow),
	MAD_TEST(testPointsForInches),
	MAD_TEST(testPointsForMillimeters),
	MAD_TEST(testAdjustForScale),
	MAD_TEST(testRoundPointToGrid),
	MAD_TEST(testCornersMake),
	MAD_TEST(testEdgePoints));
