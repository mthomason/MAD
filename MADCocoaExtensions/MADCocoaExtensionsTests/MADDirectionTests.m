//
//  MADDirectionTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the direction enums and their mapping helpers:
//  MAD2dDirection, MADCompassDirection, MADAspectRatio, MADDirection, and
//  MADResizeTypeForDirection.  Also documents the copy-paste defects in the
//  MADDirectionHorizontal/VerticalDirectionOfPoint helpers.
//

#import <XCTest/XCTest.h>

#import <MADCocoaExtensions/MAD2dDirection.h>
#import <MADCocoaExtensions/MADCompassDirection.h>
#import <MADCocoaExtensions/MADAspectRatio.h>
#import <MADCocoaExtensions/MADResizeAspect.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

@interface MADDirectionTests : XCTestCase
@end

@implementation MADDirectionTests

#pragma mark - Enum raw values

- (void)testMAD2dDirectionValues {
	XCTAssertEqual(horizontal, (MAD2dDirection)0);
	XCTAssertEqual(vertical, (MAD2dDirection)1);
	XCTAssertEqual(diagonal, (MAD2dDirection)2);
}

- (void)testMADCompassDirectionValues {
	XCTAssertEqual(north, (MADCompassDirection)1);
	XCTAssertEqual(south, (MADCompassDirection)2);
	XCTAssertEqual(east, (MADCompassDirection)3);
	XCTAssertEqual(west, (MADCompassDirection)4);
	XCTAssertEqual(northEast, (MADCompassDirection)5);
	XCTAssertEqual(northWest, (MADCompassDirection)6);
	XCTAssertEqual(southEast, (MADCompassDirection)7);
	XCTAssertEqual(southWest, (MADCompassDirection)8);
}

- (void)testMADAspectRatioValues {
	XCTAssertEqual(stretch, (MADAspectRatio)0);
	XCTAssertEqual(skew, (MADAspectRatio)1);
	XCTAssertEqual(fixed, (MADAspectRatio)2);
}

- (void)testMADDirectionValues {
	XCTAssertEqual(MADDirectionLeft, (MADDirection)1);
	XCTAssertEqual(MADDirectionRight, (MADDirection)2);
	XCTAssertEqual(MADDirectionUp, (MADDirection)3);
	XCTAssertEqual(MADDirectionDown, (MADDirection)4);
	XCTAssertEqual(MADDirectionNoDirection, (MADDirection)5);
}

#pragma mark - Specific direction of degrees

- (void)testSpecificDirectionOfDegrees {
	XCTAssertEqual(MADSpecificDirectionOfDegrees(90), north);
	XCTAssertEqual(MADSpecificDirectionOfDegrees(270), south);
	XCTAssertEqual(MADSpecificDirectionOfDegrees(0), east);
	XCTAssertEqual(MADSpecificDirectionOfDegrees(180), west);
	// Wraps out-of-range angles.
	XCTAssertEqual(MADSpecificDirectionOfDegrees(-90), south);
	XCTAssertEqual(MADSpecificDirectionOfDegrees(450), north);
}

#pragma mark - Direction classification

- (void)testDirectionIsHorizontal {
	XCTAssertTrue(MADDirectionIsHorizontal(MADDirectionLeft));
	XCTAssertTrue(MADDirectionIsHorizontal(MADDirectionRight));
	XCTAssertFalse(MADDirectionIsHorizontal(MADDirectionUp));
	XCTAssertFalse(MADDirectionIsHorizontal(MADDirectionDown));
	XCTAssertFalse(MADDirectionIsHorizontal(MADDirectionNoDirection));
}

- (void)testDirectionIsVertical {
	XCTAssertTrue(MADDirectionIsVertical(MADDirectionUp));
	XCTAssertTrue(MADDirectionIsVertical(MADDirectionDown));
	XCTAssertFalse(MADDirectionIsVertical(MADDirectionLeft));
	XCTAssertFalse(MADDirectionIsVertical(MADDirectionRight));
}

#pragma mark - Horizontal/vertical direction of a segment

- (void)testHorizontalDirectionOfPoint {
	// The direction of travel from p1 to p2: rightward reports Right.
	CGPoint p1 = CGPointMake(0, 0);
	CGPoint p2 = CGPointMake(10, 0);
	XCTAssertEqual(MADDirectionHorizontalDirectionOfPoint(p1, p2), MADDirectionRight);
	XCTAssertEqual(MADDirectionHorizontalDirectionOfPoint(p2, p1), MADDirectionLeft);

	// Same x -> NoDirection.
	XCTAssertEqual(MADDirectionHorizontalDirectionOfPoint(CGPointMake(5, 0), CGPointMake(5, 10)),
				   MADDirectionNoDirection);
}

- (void)testVerticalDirectionOfPoint {
	// The alignment guard compares Y, so a purely vertical segment classifies.
	XCTAssertEqual(MADDirectionVerticalDirectionOfPoint(CGPointMake(0, 0), CGPointMake(0, 10)),
				   MADDirectionDown);
	XCTAssertEqual(MADDirectionVerticalDirectionOfPoint(CGPointMake(0, 10), CGPointMake(0, 0)),
				   MADDirectionUp);

	// Same y -> NoDirection.
	XCTAssertEqual(MADDirectionVerticalDirectionOfPoint(CGPointMake(0, 0), CGPointMake(10, 0)),
				   MADDirectionNoDirection);
}

#pragma mark - Resize aspect for compass direction

- (void)testResizeTypeForDirection {
	struct MADResizeAspect r;

	r = MADResizeTypeForDirection(north);
	XCTAssertEqual(r.aspectRatio, stretch);
	XCTAssertEqual(r.direction, vertical);

	r = MADResizeTypeForDirection(south);
	XCTAssertEqual(r.aspectRatio, stretch);
	XCTAssertEqual(r.direction, vertical);

	r = MADResizeTypeForDirection(east);
	XCTAssertEqual(r.aspectRatio, stretch);
	XCTAssertEqual(r.direction, horizontal);

	r = MADResizeTypeForDirection(west);
	XCTAssertEqual(r.aspectRatio, stretch);
	XCTAssertEqual(r.direction, horizontal);

	r = MADResizeTypeForDirection(northEast);
	XCTAssertEqual(r.aspectRatio, fixed);
	XCTAssertEqual(r.direction, diagonal);

	r = MADResizeTypeForDirection(northWest);
	XCTAssertEqual(r.aspectRatio, fixed);
	XCTAssertEqual(r.direction, diagonal);

	r = MADResizeTypeForDirection(southEast);
	XCTAssertEqual(r.aspectRatio, fixed);
	XCTAssertEqual(r.direction, diagonal);

	r = MADResizeTypeForDirection(southWest);
	XCTAssertEqual(r.aspectRatio, fixed);
	XCTAssertEqual(r.direction, diagonal);
}

@end
