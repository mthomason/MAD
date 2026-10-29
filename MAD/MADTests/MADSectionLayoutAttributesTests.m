//
//  MADSectionLayoutAttributesTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization tests for MADSectionLayoutAttributes: the per-element layout
//  record the designer's section layout uses.  The behaviours pinned here are the
//  drop-point and intersection rules the layout manager leans on, including the
//  quirks:
//
//    * -validDropPoint:givenPlacedItems: does not skip the receiver, so a drop that
//      coincides with the receiver's own frame is reported as invalid.
//    * -placeItemGivenAttributes: considers {CGPointZero} plus the corners of the
//      *other* items, measuring from the distance to CGPointZero -- so a far corner
//      never wins over the origin.  With no other item at all there is nothing to
//      snap to and the item stays where it was placed.
//    * -moveOnScreen only corrects negative origins; items beyond the right or bottom
//      edge are left alone.
//
//  These tests need only UIKit: no store, no data source.
//

#include <TargetConditionals.h>
#import <XCTest/XCTest.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#else
#import <UIKit/UIKit.h>
#endif

#import "MADSectionLayoutAttributes.h"

// -debugQuickLookObject is implemented but declared nowhere public; this test-only
// category is the deliberate bridge.
@interface MADSectionLayoutAttributes (TestQuickLook)
- (id)debugQuickLookObject;
@end

@interface MADSectionLayoutAttributesTests : XCTestCase
@end

@implementation MADSectionLayoutAttributesTests

#pragma mark - Fixtures

- (MADSectionLayoutAttributes *)attributeWithID:(int64_t)objectID frame:(CGRect)frame {
	NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:0];
	return [MADSectionLayoutAttributes newSectionLayoutAttributesWithIndex:path
																  objectID:objectID
																   andRect:frame];
}

#pragma mark - The factory

- (void)testFactorySetsClassIndexPathObjectIDAndFrame {
	NSIndexPath *path = [NSIndexPath indexPathForItem:3 inSection:2];
	CGRect frame = CGRectMake(10.0, 20.0, 30.0, 40.0);

	MADSectionLayoutAttributes *attribute;
	attribute = [MADSectionLayoutAttributes newSectionLayoutAttributesWithIndex:path
																	   objectID:99
																		andRect:frame];

	XCTAssertEqualObjects(NSStringFromClass([attribute class]), @"MADSectionLayoutAttributes");
	XCTAssertEqualObjects(attribute.indexPath, path);
	XCTAssertEqual(attribute.objectID, (int64_t)99);
	XCTAssertTrue(CGRectEqualToRect(attribute.frame, frame));
}

#pragma mark - intersectsAnItemInArray:

- (void)testIntersectsAnItemInArrayReportsOverlapWithADifferentID {
	MADSectionLayoutAttributes *item = [self attributeWithID:1 frame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
	MADSectionLayoutAttributes *other = [self attributeWithID:2 frame:CGRectMake(50.0, 50.0, 100.0, 100.0)];

	NSArray <MADSectionLayoutAttributes *> *items = @[ other ];
	XCTAssertTrue([item intersectsAnItemInArray:items]);
}

- (void)testIntersectsAnItemInArraySkipsTheSameObjectID {
	MADSectionLayoutAttributes *item = [self attributeWithID:5 frame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
	// A different attribute for the same object: overlapping, but the objectID test wins.
	MADSectionLayoutAttributes *sameObject = [self attributeWithID:5 frame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

	NSArray <MADSectionLayoutAttributes *> *items = @[ sameObject ];
	XCTAssertFalse([item intersectsAnItemInArray:items]);
}

- (void)testIntersectsAnItemInArrayWithNoItemsIsNo {
	MADSectionLayoutAttributes *item = [self attributeWithID:1 frame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

	XCTAssertFalse([item intersectsAnItemInArray:@[]]);
}

#pragma mark - validDropPoint:givenPlacedItems:

- (void)testValidDropPointDoesNotSkipTheReceiverItself {
	MADSectionLayoutAttributes *item = [self attributeWithID:5 frame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

	// Characterization of the quirk: the receiver is not filtered out of placedItems,
	// so dropping it on its own frame intersects itself and reads as invalid.
	NSArray <MADSectionLayoutAttributes *> *items = @[ item ];
	XCTAssertFalse([item validDropPoint:CGPointMake(0.0, 0.0) givenPlacedItems:items]);
	// One point to the right, the frames only touch and the drop is valid.
	XCTAssertTrue([item validDropPoint:CGPointMake(100.0, 0.0) givenPlacedItems:items]);
}

- (void)testValidDropPointReportsOverlapWithAnotherItem {
	MADSectionLayoutAttributes *item = [self attributeWithID:5 frame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
	MADSectionLayoutAttributes *other = [self attributeWithID:6 frame:CGRectMake(200.0, 0.0, 100.0, 100.0)];

	NSArray <MADSectionLayoutAttributes *> *items = @[ other ];
	XCTAssertFalse([item validDropPoint:CGPointMake(150.0, 0.0) givenPlacedItems:items]);
	// Just clear of the other item's left edge.
	XCTAssertTrue([item validDropPoint:CGPointMake(100.0, 0.0) givenPlacedItems:items]);
}

- (void)testValidDropPointUsesTheReceiversOwnSize {
	MADSectionLayoutAttributes *narrow = [self attributeWithID:5 frame:CGRectMake(0.0, 0.0, 30.0, 30.0)];
	MADSectionLayoutAttributes *wide = [self attributeWithID:5 frame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
	MADSectionLayoutAttributes *other = [self attributeWithID:6 frame:CGRectMake(40.0, 0.0, 100.0, 100.0)];

	NSArray <MADSectionLayoutAttributes *> *items = @[ other ];
	// The draft rectangle is the receiver's size, not a unit rect.
	XCTAssertTrue([narrow validDropPoint:CGPointMake(0.0, 0.0) givenPlacedItems:items]);
	XCTAssertFalse([wide validDropPoint:CGPointMake(0.0, 0.0) givenPlacedItems:items]);
}

- (void)testValidDropPointWithNoPlacedItemsIsAlwaysValid {
	MADSectionLayoutAttributes *item = [self attributeWithID:1 frame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

	XCTAssertTrue([item validDropPoint:CGPointMake(-500.0, -500.0) givenPlacedItems:@[]]);
}

#pragma mark - moveOnScreen

- (void)testMoveOnScreenFlushesNegativeOriginsToZero {
	MADSectionLayoutAttributes *west = [self attributeWithID:1 frame:CGRectMake(-10.0, 5.0, 30.0, 40.0)];
	XCTAssertTrue([west moveOnScreen]);
	XCTAssertTrue(CGRectEqualToRect(west.frame, CGRectMake(0.0, 5.0, 30.0, 40.0)));

	MADSectionLayoutAttributes *north = [self attributeWithID:2 frame:CGRectMake(10.0, -5.0, 30.0, 40.0)];
	XCTAssertTrue([north moveOnScreen]);
	XCTAssertTrue(CGRectEqualToRect(north.frame, CGRectMake(10.0, 0.0, 30.0, 40.0)));

	MADSectionLayoutAttributes *both = [self attributeWithID:3 frame:CGRectMake(-10.0, -5.0, 30.0, 40.0)];
	XCTAssertTrue([both moveOnScreen]);
	XCTAssertTrue(CGRectEqualToRect(both.frame, CGRectMake(0.0, 0.0, 30.0, 40.0)));
}

- (void)testMoveOnScreenLeavesOnScreenAndEastSouthItemsAlone {
	MADSectionLayoutAttributes *onScreen = [self attributeWithID:1 frame:CGRectMake(10.0, 20.0, 30.0, 40.0)];
	XCTAssertFalse([onScreen moveOnScreen]);
	XCTAssertTrue(CGRectEqualToRect(onScreen.frame, CGRectMake(10.0, 20.0, 30.0, 40.0)));

	// Only west and north are corrected; an item past the right or bottom edge is
	// considered on screen and reported as not moved.
	MADSectionLayoutAttributes *eastSouth = [self attributeWithID:2 frame:CGRectMake(600.0, 900.0, 30.0, 40.0)];
	XCTAssertFalse([eastSouth moveOnScreen]);
	XCTAssertTrue(CGRectEqualToRect(eastSouth.frame, CGRectMake(600.0, 900.0, 30.0, 40.0)));
}

#pragma mark - placeItemGivenAttributes:

- (void)testPlaceItemWithNoOtherItemsStaysWhereItWas {
	MADSectionLayoutAttributes *item = [self attributeWithID:1 frame:CGRectMake(10.0, 10.0, 20.0, 20.0)];

	// Nothing to snap against: the origin is not a drop point, so an item that was
	// already somewhere sensible stays there.  (It used to be yanked to CGPointZero.)
	[item placeItemGivenAttributes:@[]];
	XCTAssertTrue(CGRectEqualToRect(item.frame, CGRectMake(10.0, 10.0, 20.0, 20.0)));

	// The item itself is not a thing to snap against either.
	MADSectionLayoutAttributes *again = [self attributeWithID:2 frame:CGRectMake(10.0, 10.0, 20.0, 20.0)];
	MADSectionLayoutAttributes *sameObject = [self attributeWithID:2 frame:CGRectMake(80.0, 80.0, 5.0, 5.0)];
	NSArray <MADSectionLayoutAttributes *> *onlySelf = @[ sameObject ];
	[again placeItemGivenAttributes:onlySelf];
	XCTAssertTrue(CGRectEqualToRect(again.frame, CGRectMake(10.0, 10.0, 20.0, 20.0)));
}

- (void)testPlaceItemSnapsToTheNearestOtherCorner {
	MADSectionLayoutAttributes *item = [self attributeWithID:1 frame:CGRectMake(10.0, 10.0, 20.0, 20.0)];
	MADSectionLayoutAttributes *other = [self attributeWithID:2 frame:CGRectMake(12.0, 12.0, 10.0, 10.0)];

	NSArray <MADSectionLayoutAttributes *> *items = @[ other ];
	[item placeItemGivenAttributes:items];

	// (12, 12) is the other item's top-left corner, 2.83 away from the item's origin --
	// nearer than the origin at 14.14.
	XCTAssertTrue(CGRectEqualToRect(item.frame, CGRectMake(12.0, 12.0, 20.0, 20.0)));
}

- (void)testPlaceItemPrefersTheOriginOverADistantCorner {
	MADSectionLayoutAttributes *item = [self attributeWithID:1 frame:CGRectMake(10.0, 10.0, 20.0, 20.0)];
	MADSectionLayoutAttributes *far = [self attributeWithID:2 frame:CGRectMake(200.0, 200.0, 10.0, 10.0)];

	NSArray <MADSectionLayoutAttributes *> *items = @[ far ];
	[item placeItemGivenAttributes:items];

	// Every corner of the far item is farther from (10, 10) than CGPointZero is, and the
	// origin is where the search starts -- so the item lands at the origin.
	XCTAssertTrue(CGRectEqualToRect(item.frame, CGRectMake(0.0, 0.0, 20.0, 20.0)));
}

#pragma mark - Drop point lists

- (void)testCopyDropPointsIsCornersInTopRowFirstOrder {
	MADSectionLayoutAttributes *item = [self attributeWithID:1 frame:CGRectMake(10.0, 20.0, 30.0, 40.0)];

	NSArray <NSValue *> *points = [item copyDropPoints];
	XCTAssertEqual(points.count, (NSUInteger)4);
	XCTAssertTrue(CGPointEqualToPoint(points[0].CGPointValue, CGPointMake(10.0, 20.0)));
	XCTAssertTrue(CGPointEqualToPoint(points[1].CGPointValue, CGPointMake(40.0, 20.0)));
	XCTAssertTrue(CGPointEqualToPoint(points[2].CGPointValue, CGPointMake(10.0, 60.0)));
	XCTAssertTrue(CGPointEqualToPoint(points[3].CGPointValue, CGPointMake(40.0, 60.0)));
}

- (void)testCopyDropPointsHorizontalIsBottomRightThenTopRight {
	MADSectionLayoutAttributes *item = [self attributeWithID:1 frame:CGRectMake(10.0, 20.0, 30.0, 40.0)];

	NSArray <NSValue *> *points = [item copyDropPointsHorizontal];
	XCTAssertEqual(points.count, (NSUInteger)2);
	XCTAssertTrue(CGPointEqualToPoint(points[0].CGPointValue, CGPointMake(40.0, 60.0)));
	XCTAssertTrue(CGPointEqualToPoint(points[1].CGPointValue, CGPointMake(40.0, 20.0)));
}

#pragma mark - NSCopying and debugQuickLookObject

- (void)testCopyWithZoneKeepsTheObjectIDAndFrame {
	MADSectionLayoutAttributes *item = [self attributeWithID:77 frame:CGRectMake(10.0, 20.0, 30.0, 40.0)];

	MADSectionLayoutAttributes *copy = [item copy];

	XCTAssertFalse(copy == item);
	XCTAssertEqual(copy.objectID, (int64_t)77);
	XCTAssertTrue(CGRectEqualToRect(copy.frame, CGRectMake(10.0, 20.0, 30.0, 40.0)));
}

- (void)testDebugQuickLookObjectDescribesIDAndFrame {
	MADSectionLayoutAttributes *item = [self attributeWithID:5 frame:CGRectMake(10.0, 20.0, 30.0, 40.0)];

	XCTAssertEqualObjects([item debugQuickLookObject], @"5\t\t{{10, 20}, {30, 40}}");
}

@end
