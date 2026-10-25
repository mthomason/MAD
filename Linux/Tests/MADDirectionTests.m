//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDirectionTests.m
//  Linux/Tests
//
//  Ported from MADCocoaExtensionsTests/MADDirectionTests.m: the direction
//  enums and their mapping helpers -- MAD2dDirection, MADCompassDirection,
//  MADAspectRatio, MADDirection and MADResizeTypeForDirection.
//

#import "MADTestSupport.h"
#import <MADCocoaExtensions/MAD2dDirection.h>
#import <MADCocoaExtensions/MADCompassDirection.h>
#import <MADCocoaExtensions/MADAspectRatio.h>
#import <MADCocoaExtensions/MADResizeAspect.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#pragma mark - Enum raw values

static void testMAD2dDirectionValues(void) {
	MAD_PASS(horizontal == (MAD2dDirection)0, "horizontal is 0");
	MAD_PASS(vertical == (MAD2dDirection)1, "vertical is 1");
	MAD_PASS(diagonal == (MAD2dDirection)2, "diagonal is 2");
}

static void testMADCompassDirectionValues(void) {
	MAD_PASS(north == (MADCompassDirection)1, "north is 1");
	MAD_PASS(south == (MADCompassDirection)2, "south is 2");
	MAD_PASS(east == (MADCompassDirection)3, "east is 3");
	MAD_PASS(west == (MADCompassDirection)4, "west is 4");
	MAD_PASS(northEast == (MADCompassDirection)5, "northEast is 5");
	MAD_PASS(northWest == (MADCompassDirection)6, "northWest is 6");
	MAD_PASS(southEast == (MADCompassDirection)7, "southEast is 7");
	MAD_PASS(southWest == (MADCompassDirection)8, "southWest is 8");
}

static void testMADAspectRatioValues(void) {
	MAD_PASS(stretch == (MADAspectRatio)0, "stretch is 0");
	MAD_PASS(skew == (MADAspectRatio)1, "skew is 1");
	MAD_PASS(fixed == (MADAspectRatio)2, "fixed is 2");
}

static void testMADDirectionValues(void) {
	MAD_PASS(MADDirectionLeft == (MADDirection)1, "Left is 1");
	MAD_PASS(MADDirectionRight == (MADDirection)2, "Right is 2");
	MAD_PASS(MADDirectionUp == (MADDirection)3, "Up is 3");
	MAD_PASS(MADDirectionDown == (MADDirection)4, "Down is 4");
	MAD_PASS(MADDirectionNoDirection == (MADDirection)5, "NoDirection is 5");
}

#pragma mark - Specific direction of degrees

static void testSpecificDirectionOfDegrees(void) {
	MAD_PASS(MADSpecificDirectionOfDegrees(90) == north, "90 degrees is north");
	MAD_PASS(MADSpecificDirectionOfDegrees(270) == south, "270 degrees is south");
	MAD_PASS(MADSpecificDirectionOfDegrees(0) == east, "0 degrees is east");
	MAD_PASS(MADSpecificDirectionOfDegrees(180) == west, "180 degrees is west");
	MAD_PASS(MADSpecificDirectionOfDegrees(-90) == south, "out-of-range angles wrap");
	MAD_PASS(MADSpecificDirectionOfDegrees(450) == north, "angles past 360 wrap");
}

#pragma mark - Direction classification

static void testDirectionIsHorizontal(void) {
	MAD_PASS(MADDirectionIsHorizontal(MADDirectionLeft), "Left is horizontal");
	MAD_PASS(MADDirectionIsHorizontal(MADDirectionRight), "Right is horizontal");
	MAD_PASS(!MADDirectionIsHorizontal(MADDirectionUp), "Up is not horizontal");
	MAD_PASS(!MADDirectionIsHorizontal(MADDirectionDown), "Down is not horizontal");
	MAD_PASS(!MADDirectionIsHorizontal(MADDirectionNoDirection), "NoDirection is not horizontal");
}

static void testDirectionIsVertical(void) {
	MAD_PASS(MADDirectionIsVertical(MADDirectionUp), "Up is vertical");
	MAD_PASS(MADDirectionIsVertical(MADDirectionDown), "Down is vertical");
	MAD_PASS(!MADDirectionIsVertical(MADDirectionLeft), "Left is not vertical");
	MAD_PASS(!MADDirectionIsVertical(MADDirectionRight), "Right is not vertical");
}

#pragma mark - Horizontal/vertical direction of a segment

static void testHorizontalDirectionOfPoint(void) {
	CGPoint p1 = CGPointMake(0, 0);
	CGPoint p2 = CGPointMake(10, 0);
	MAD_PASS(MADDirectionHorizontalDirectionOfPoint(p1, p2) == MADDirectionRight, "rightward reports Right");
	MAD_PASS(MADDirectionHorizontalDirectionOfPoint(p2, p1) == MADDirectionLeft, "leftward reports Left");
	MAD_PASS(MADDirectionHorizontalDirectionOfPoint(CGPointMake(5, 0), CGPointMake(5, 10)) == MADDirectionNoDirection,
			 "the same x reports NoDirection");
}

static void testVerticalDirectionOfPoint(void) {
	MAD_PASS(MADDirectionVerticalDirectionOfPoint(CGPointMake(0, 0), CGPointMake(0, 10)) == MADDirectionDown,
			 "downward reports Down");
	MAD_PASS(MADDirectionVerticalDirectionOfPoint(CGPointMake(0, 10), CGPointMake(0, 0)) == MADDirectionUp,
			 "upward reports Up");
	MAD_PASS(MADDirectionVerticalDirectionOfPoint(CGPointMake(0, 0), CGPointMake(10, 0)) == MADDirectionNoDirection,
			 "the same y reports NoDirection");
}

#pragma mark - Resize aspect for compass direction

static void testResizeTypeForDirection(void) {
	struct MADResizeAspect r;

	r = MADResizeTypeForDirection(north);
	MAD_PASS(r.aspectRatio == stretch && r.direction == vertical, "north stretches vertically");

	r = MADResizeTypeForDirection(south);
	MAD_PASS(r.aspectRatio == stretch && r.direction == vertical, "south stretches vertically");

	r = MADResizeTypeForDirection(east);
	MAD_PASS(r.aspectRatio == stretch && r.direction == horizontal, "east stretches horizontally");

	r = MADResizeTypeForDirection(west);
	MAD_PASS(r.aspectRatio == stretch && r.direction == horizontal, "west stretches horizontally");

	r = MADResizeTypeForDirection(northEast);
	MAD_PASS(r.aspectRatio == fixed && r.direction == diagonal, "northEast is fixed diagonally");

	r = MADResizeTypeForDirection(northWest);
	MAD_PASS(r.aspectRatio == fixed && r.direction == diagonal, "northWest is fixed diagonally");

	r = MADResizeTypeForDirection(southEast);
	MAD_PASS(r.aspectRatio == fixed && r.direction == diagonal, "southEast is fixed diagonally");

	r = MADResizeTypeForDirection(southWest);
	MAD_PASS(r.aspectRatio == fixed && r.direction == diagonal, "southWest is fixed diagonally");
}

MAD_TEST_MAIN("MADDirectionTests",
	MAD_TEST(testMAD2dDirectionValues),
	MAD_TEST(testMADCompassDirectionValues),
	MAD_TEST(testMADAspectRatioValues),
	MAD_TEST(testMADDirectionValues),
	MAD_TEST(testSpecificDirectionOfDegrees),
	MAD_TEST(testDirectionIsHorizontal),
	MAD_TEST(testDirectionIsVertical),
	MAD_TEST(testHorizontalDirectionOfPoint),
	MAD_TEST(testVerticalDirectionOfPoint),
	MAD_TEST(testResizeTypeForDirection));
