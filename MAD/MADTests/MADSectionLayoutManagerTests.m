//
//  MADSectionLayoutManagerTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization tests for MADSectionLayoutManager: the per-section collection of
//  MADSectionLayoutAttributes the designer lays elements out with.
//
//  Pinned behaviours, including the quirks:
//
//    * -initWithDocumentSection: walks only the *first* row's objects, numbering the
//      attributes' item index from zero in that order.
//    * -layout only positions anything when the last operation was an addition.
//    * -positionItem: clamps a negative origin to zero, snaps to a drop point within
//      24 points, and pushes overlapping items aside -- the deterministic two-item
//      scenario below ends with the added item at the origin and the resident item
//      flush to its right.
//    * -removeItemWithID: with a number that is not in the manager, the nil item's
//      indexPath reads a zero at every position, so every item's index is decremented
//      and the item at index zero underflows to NSUIntegerMax.  This is pinned as a
//      defect in docs/project/BUGS.md, not fixed.
//
//  The manager reads only the section's visibility (no getter, so not observable) and
//  its rows; the fixture below builds those in a real in-memory store.
//

#include <TargetConditionals.h>
#import <XCTest/XCTest.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#else
#import <UIKit/UIKit.h>
#endif

#import "MADSectionLayoutManager.h"
#import "MADSectionLayoutAttributes.h"
#import "MADocumentSectionType.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocumentElementLabel.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentSectionRows.h"
#import "RptqDocumentSectionRows+Extras.h"

@interface MADSectionLayoutManagerTests : XCTestCase

@property (nonatomic, strong) RptqStoreContext *context;

@end

@implementation MADSectionLayoutManagerTests

#pragma mark - Fixtures

- (RptqStoreContext *)inMemoryContext {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	XCTAssertTrue([context loadAllWithError:&error], @"load failed: %@", error);
	return context;
}

- (RptqDocumentElementLabel *)elementWithIdentifier:(int64_t)identifier
												  x:(CGFloat)x
												  y:(CGFloat)y
												  w:(CGFloat)w
												  h:(CGFloat)h {
	RptqDocumentElementLabel *element;
	element = (RptqDocumentElementLabel *)[self.context insertObjectForEntity:@"RptqDocumentElementLabel"
																   identifier:identifier];
	[element setOriginPoint:CGPointMake(x, y)];
	[element setSizeValue:CGSizeMake(w, h)];
	return element;
}

// A body section whose single row holds the given elements, in order.
- (RptqDocumentSection *)sectionWithElements:(NSArray <RptqDocumentElement *> *)elements {
	RptqDocumentSection *section;
	section = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeBody
									 forManagedObjectContext:self.context];
	RptqDocumentSectionRows *row;
	row = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:self.context];
	row.inSection = section;
	for (RptqDocumentElement *element in elements) {
		[row addHasObjectsObject:element];
	}
	section.hasRows = [[NSOrderedSet alloc] initWithObject:row];
	return section;
}

- (MADSectionLayoutAttributes *)itemForIdentifier:(int64_t)identifier
										 inManager:(MADSectionLayoutManager *)manager {
	return manager.items[@(identifier)];
}

#pragma mark - Lifecycle

- (void)setUp {
	[super setUp];
	self.context = [self inMemoryContext];
}

#pragma mark - Initialisation

- (void)testInitWithNilSectionProducesAnEmptyManager {
	MADSectionLayoutManager *manager;
	manager = [[MADSectionLayoutManager alloc] initWithDocumentSection:nil];

	XCTAssertEqual(manager.items.count, (NSUInteger)0);
	XCTAssertTrue(CGSizeEqualToSize(manager.size, CGSizeZero));
}

- (void)testInitBuildsOneAttributePerElementInRowOrder {
	RptqDocumentElementLabel *first = [self elementWithIdentifier:1 x:5.0 y:6.0 w:70.0 h:80.0];
	RptqDocumentElementLabel *second = [self elementWithIdentifier:2 x:100.0 y:10.0 w:20.0 h:20.0];
	RptqDocumentSection *section = [self sectionWithElements:@[ first, second ]];

	MADSectionLayoutManager *manager;
	manager = [[MADSectionLayoutManager alloc] initWithDocumentSection:section];

	XCTAssertEqual(manager.items.count, (NSUInteger)2);

	MADSectionLayoutAttributes *itemOne = [self itemForIdentifier:1 inManager:manager];
	MADSectionLayoutAttributes *itemTwo = [self itemForIdentifier:2 inManager:manager];
	XCTAssertNotNil(itemOne);
	XCTAssertNotNil(itemTwo);

	// Each attribute carries the element's identifier and frame ...
	XCTAssertEqual(itemOne.objectID, (int64_t)1);
	XCTAssertTrue(CGRectEqualToRect(itemOne.frame, first.frame));
	XCTAssertEqual(itemTwo.objectID, (int64_t)2);
	XCTAssertTrue(CGRectEqualToRect(itemTwo.frame, second.frame));

	// ... and its item index counts from zero in the row's order, in section zero.
	XCTAssertEqual([itemOne.indexPath indexAtPosition:0], (NSUInteger)0);
	XCTAssertEqual([itemOne.indexPath indexAtPosition:1], (NSUInteger)0);
	XCTAssertEqual([itemTwo.indexPath indexAtPosition:0], (NSUInteger)0);
	XCTAssertEqual([itemTwo.indexPath indexAtPosition:1], (NSUInteger)1);

	// The size is the furthest right and bottom edge of any item.
	XCTAssertTrue(CGSizeEqualToSize(manager.size, CGSizeMake(120.0, 86.0)));
}

- (void)testSizeOfAnEmptyManagerIsZero {
	RptqDocumentSection *section = [self sectionWithElements:@[]];
	MADSectionLayoutManager *manager;
	manager = [[MADSectionLayoutManager alloc] initWithDocumentSection:section];

	XCTAssertEqual(manager.items.count, (NSUInteger)0);
	XCTAssertTrue(CGSizeEqualToSize(manager.size, CGSizeZero));
}

#pragma mark - addItem: and layout

- (void)testAddItemPositionsItOnTheNextLayout {
	MADSectionLayoutManager *manager;
	manager = [[MADSectionLayoutManager alloc] initWithDocumentSection:nil];

	NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:0];
	MADSectionLayoutAttributes *item;
	item = [MADSectionLayoutAttributes newSectionLayoutAttributesWithIndex:path
																  objectID:9
																   andRect:CGRectMake(-20.0, -30.0, 40.0, 50.0)];
	[manager addItem:item];
	XCTAssertEqual(manager.items.count, (NSUInteger)1);

	[manager layout];

	// positionItem: clamps the negative origin to zero, and the origin is within the
	// 24-point snap tolerance, so the frame sits at (0, 0).
	XCTAssertTrue(CGRectEqualToRect(item.frame, CGRectMake(0.0, 0.0, 40.0, 50.0)));
}

- (void)testLayoutPushesAnOverlappingItemAside {
	// The resident item is added first, the incoming one last, so the incoming one is
	// the item -layout positions.
	RptqDocumentElementLabel *resident = [self elementWithIdentifier:1 x:0.0 y:0.0 w:100.0 h:100.0];
	RptqDocumentElementLabel *incoming = [self elementWithIdentifier:2 x:10.0 y:10.0 w:50.0 h:50.0];
	RptqDocumentSection *section = [self sectionWithElements:@[ resident, incoming ]];
	// The frame comes straight off the element; guard the zero-spacing defaults the
	// scenario depends on.
	XCTAssertTrue(CGRectEqualToRect(resident.frame, CGRectMake(0.0, 0.0, 100.0, 100.0)));
	XCTAssertTrue(CGRectEqualToRect(incoming.frame, CGRectMake(10.0, 10.0, 50.0, 50.0)));

	MADSectionLayoutManager *manager;
	manager = [[MADSectionLayoutManager alloc] initWithDocumentSection:section];
	[manager layout];

	// The incoming item snaps to the nearest drop point within 24 points -- the origin
	// -- and the resident item, pushed out of the way, lands on the incoming item's
	// right-hand drop point at x = 50.
	MADSectionLayoutAttributes *incomingItem = [self itemForIdentifier:2 inManager:manager];
	MADSectionLayoutAttributes *residentItem = [self itemForIdentifier:1 inManager:manager];
	XCTAssertTrue(CGRectEqualToRect(incomingItem.frame, CGRectMake(0.0, 0.0, 50.0, 50.0)));
	XCTAssertTrue(CGRectEqualToRect(residentItem.frame, CGRectMake(50.0, 0.0, 100.0, 100.0)));
}

- (void)testLayoutDoesNothingAfterARemoval {
	RptqDocumentElementLabel *resident = [self elementWithIdentifier:1 x:0.0 y:0.0 w:100.0 h:100.0];
	RptqDocumentElementLabel *incoming = [self elementWithIdentifier:2 x:10.0 y:10.0 w:50.0 h:50.0];
	RptqDocumentSection *section = [self sectionWithElements:@[ resident, incoming ]];

	MADSectionLayoutManager *manager;
	manager = [[MADSectionLayoutManager alloc] initWithDocumentSection:section];

	[manager removeItemWithID:@2];
	XCTAssertEqual(manager.items.count, (NSUInteger)1);

	// Move the survivor off screen; if layout ran, positionItem: would clamp it.
	MADSectionLayoutAttributes *survivor = [self itemForIdentifier:1 inManager:manager];
	survivor.frame = CGRectMake(-5.0, 0.0, 100.0, 100.0);

	[manager layout];

	// The last operation was a removal, so layout is a no-op.
	XCTAssertTrue(CGRectEqualToRect(survivor.frame, CGRectMake(-5.0, 0.0, 100.0, 100.0)));
}

#pragma mark - removeItemWithID:

- (void)testRemoveShiftsLaterItemIndexesDown {
	RptqDocumentElementLabel *one = [self elementWithIdentifier:1 x:0.0 y:0.0 w:10.0 h:10.0];
	RptqDocumentElementLabel *two = [self elementWithIdentifier:2 x:10.0 y:0.0 w:10.0 h:10.0];
	RptqDocumentElementLabel *three = [self elementWithIdentifier:3 x:20.0 y:0.0 w:10.0 h:10.0];
	RptqDocumentSection *section = [self sectionWithElements:@[ one, two, three ]];

	MADSectionLayoutManager *manager;
	manager = [[MADSectionLayoutManager alloc] initWithDocumentSection:section];

	[manager removeItemWithID:@1];

	XCTAssertEqual(manager.items.count, (NSUInteger)2);
	XCTAssertNil([self itemForIdentifier:1 inManager:manager]);
	// Items after the removed index shift down one.
	MADSectionLayoutAttributes *itemTwo = [self itemForIdentifier:2 inManager:manager];
	MADSectionLayoutAttributes *itemThree = [self itemForIdentifier:3 inManager:manager];
	XCTAssertEqual([itemTwo.indexPath indexAtPosition:1], (NSUInteger)0);
	XCTAssertEqual([itemThree.indexPath indexAtPosition:1], (NSUInteger)1);
}

- (void)testRemoveWithAnUnknownIDLeavesEveryIndexDecremented {
	RptqDocumentElementLabel *one = [self elementWithIdentifier:1 x:0.0 y:0.0 w:10.0 h:10.0];
	RptqDocumentElementLabel *two = [self elementWithIdentifier:2 x:10.0 y:0.0 w:10.0 h:10.0];
	RptqDocumentElementLabel *three = [self elementWithIdentifier:3 x:20.0 y:0.0 w:10.0 h:10.0];
	RptqDocumentSection *section = [self sectionWithElements:@[ one, two, three ]];

	MADSectionLayoutManager *manager;
	manager = [[MADSectionLayoutManager alloc] initWithDocumentSection:section];

	// Characterization of the defect: the lookup answers nil, whose indexPath reads
	// zero at every position, so the comparison passes for every item.  No key is
	// removed, but every item index is decremented -- and the item at index zero
	// underflows.
	[manager removeItemWithID:@999];

	XCTAssertEqual(manager.items.count, (NSUInteger)3);
	MADSectionLayoutAttributes *itemOne = [self itemForIdentifier:1 inManager:manager];
	MADSectionLayoutAttributes *itemTwo = [self itemForIdentifier:2 inManager:manager];
	MADSectionLayoutAttributes *itemThree = [self itemForIdentifier:3 inManager:manager];
	XCTAssertEqual([itemOne.indexPath indexAtPosition:1], NSUIntegerMax);
	XCTAssertEqual([itemTwo.indexPath indexAtPosition:1], (NSUInteger)0);
	XCTAssertEqual([itemThree.indexPath indexAtPosition:1], (NSUInteger)1);
}

@end
