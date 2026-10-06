//
//  MADDataTableVirtualTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADDataTableVirtual, the in-memory MADDataTable.  The row/sort/cache
//  behaviour is also exercised by MADDataTableRegressionTests in the MAD bundle; this
//  file completes the picture inside MADFoundationTests and adds the pieces that
//  suite does not reach: the columns enumerator, -objectAtIndex:, the sortIndex key
//  that Virtual adds to the plist, the NSCoding round trip, and the column desync a
//  short row leaves behind.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableVirtual.h>

// -objectAtIndex: is implemented on the class but declared in no header; this
// test-only category is the deliberate bridge.
@interface MADDataTableVirtual (TestIndex)
- (id)objectAtIndex:(NSUInteger)index;
@end

@interface MADDataTableVirtualTests : XCTestCase
@end

@implementation MADDataTableVirtualTests

#pragma mark - Fixture

- (MADDataTableVirtual *)twoColumnTable {
	MADDataTableVirtual *table = [[MADDataTableVirtual alloc] initWithId:1];
	MADDataColumn *first = [MADDataColumn newDataColumnWithIdentifier:@"a"];
	first.type = MADDataTypeString;
	MADDataColumn *second = [MADDataColumn newDataColumnWithIdentifier:@"b"];
	second.type = MADDataTypeInteger;
	[table addColumn:first];
	[table addColumn:second];
	return table;
}

#pragma mark - Construction and rows

- (void)testInitDefaults {
	MADDataTableVirtual *table = [[MADDataTableVirtual alloc] init];

	XCTAssertEqualObjects(table.name, @"");
	XCTAssertEqual(table.numberOfRows, (NSUInteger)0);
	XCTAssertEqual(table.count, (NSUInteger)0);
	XCTAssertEqual(table.numberOfColumns, (NSUInteger)0);
	XCTAssertEqualObjects(table.allObjects, @[]);
}

- (void)testAddColumnAndAddRow {
	MADDataTableVirtual *table = [self twoColumnTable];

	XCTAssertEqual(table.numberOfColumns, (NSUInteger)2);
	XCTAssertEqualObjects(table.columnKeys, (@[@"a", @"b"]));
	NSArray *row = @[@"alpha", @1];
	XCTAssertTrue([table addRow:row error:NULL]);

	XCTAssertEqual(table.numberOfRows, (NSUInteger)1);
	XCTAssertEqual(table.count, (NSUInteger)1);
	XCTAssertEqualObjects(table[0][@"a"], @"alpha");
	XCTAssertEqualObjects(table[0][@"b"], @1);
	// The indexed row is stamped with its row id.
	XCTAssertEqualObjects(table[0][@"~rowid~"], @0);
	// Column view and row view agree.
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"alpha");
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @1);
}

- (void)testObjectAtIndexAndSubscriptAgree {
	MADDataTableVirtual *table = [self twoColumnTable];
	[table addRow:@[@"alpha", @1] error:NULL];

	XCTAssertEqual([table objectAtIndex:0], [table objectAtIndexedSubscript:0]);
	XCTAssertEqual([table objectAtIndex:0], [table objectAtRow:0]);
}

- (void)testColumnsEnumerator {
	MADDataTableVirtual *table = [self twoColumnTable];

	// Dictionary enumeration order is unspecified, so the set of columns is asserted.
	NSMutableSet<NSString *> *identifiers = [NSMutableSet set];
	for (MADDataColumn *column in [table columnsEnumerator]) {
		[identifiers addObject:column.identifier];
	}

	XCTAssertEqual(identifiers.count, (NSUInteger)2);
	XCTAssertTrue([identifiers containsObject:@"a"]);
	XCTAssertTrue([identifiers containsObject:@"b"]);
}

#pragma mark - Short rows

- (void)testShortRowLeavesTheColumnViewDesynchronized {
	MADDataTableVirtual *table = [self twoColumnTable];

	// Only one value for two columns: the dictionary row is stored as given, the
	// column objects get only what was supplied, and the row counter still advances.
	[table addRow:@[@"alpha"] error:NULL];

	XCTAssertEqual(table.numberOfRows, (NSUInteger)1);
	XCTAssertEqualObjects(table[0][@"a"], @"alpha");
	XCTAssertNil(table[0][@"b"]);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"alpha");
	// -objectAtRow:column: for the missing column asserts inside MADDataColumn,
	// which is the desync surfacing; recorded, not pinned here.
}

#pragma mark - Plist and coding

- (void)testCopyPlistCarriesTheSortIndexKey {
	MADDataTableVirtual *table = [self twoColumnTable];
	[table addRow:@[@"alpha", @1] error:NULL];

	NSDictionary *plist = [table copyPlist];

	// Virtual extends the base plist with the row index under "sortIndex".
	XCTAssertNotNil(plist[@"sortIndex"]);
	XCTAssertEqual([plist[@"sortIndex"] count], (NSUInteger)1);
	XCTAssertEqualObjects(plist[@"columnKeys"], (@[@"a", @"b"]));
}

- (void)testNSCodingRoundTripPreservesRowsAndColumns {
	MADDataTableVirtual *table = [self twoColumnTable];
	[table addRow:@[@"alpha", @1] error:NULL];

	// MADDataTable is NSCoding-only, so the insecure path is the one it satisfies.
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
	[archiver encodeObject:table forKey:NSKeyedArchiveRootObjectKey];
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:archiver.encodedData error:NULL];
	unarchiver.requiresSecureCoding = NO;
	MADDataTableVirtual *decoded = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
	[unarchiver finishDecoding];

	XCTAssertNotNil(decoded);
	XCTAssertEqual(decoded.numberOfRows, (NSUInteger)1);
	XCTAssertEqualObjects(decoded[0][@"a"], @"alpha");
	XCTAssertEqualObjects(decoded.columnKeys, (@[@"a", @"b"]));
	XCTAssertEqualObjects([decoded objectAtRow:0 column:1], @1);
}

#pragma mark - Clearing

- (void)testRemoveAllObjectsClearsRowsColumnsAndMetadata {
	MADDataTableVirtual *table = [self twoColumnTable];
	[table addRow:@[@"alpha", @1] error:NULL];
	[table sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"a" ascending:YES]]];

	[table removeAllObjects];

	XCTAssertEqual(table.numberOfRows, (NSUInteger)0);
	XCTAssertEqual(table.numberOfColumns, (NSUInteger)0);
	XCTAssertEqual(table.rowCounter, (NSUInteger)0);
	XCTAssertEqualObjects(table.allObjects, @[]);
	XCTAssertEqualObjects(table.columnKeys, @[]);
	XCTAssertEqualObjects(table.sortDescriptors, @[]);
}

@end
