//
//  MADDataTableVirtualTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADDataTableVirtualTests.m: coverage for
//  MADDataTableVirtual, the in-memory MADDataTable.  The row/sort/cache
//  behaviour is also exercised by MADDataTableRegressionTests in the MAD
//  bundle; this file completes the picture inside MADFoundation and adds the
//  pieces that suite does not reach: the columns enumerator, -objectAtIndex:,
//  the sortIndex key that Virtual adds to the plist, the NSCoding round trip,
//  and the column desync a short row leaves behind.
//
//  The Xcode suite builds its coders with the iOS 11+ instance APIs; GNUstep
//  has neither, so the port uses the portable class pair (the same insecure
//  round trip).  See MADDataTableBaseTests for the same adaptation.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableVirtual.h>

// -objectAtIndex: is implemented on the class but declared in no header; this
// test-only category is the deliberate bridge, as it is in the Xcode suite.
@interface MADDataTableVirtual (TestIndex)
- (id)objectAtIndex:(NSUInteger)index;
@end

#pragma mark - Fixture

static MADDataTableVirtual *twoColumnTable(void) {
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

static void testInitDefaults(void) {
	MADDataTableVirtual *table = [[MADDataTableVirtual alloc] init];

	MAD_PASS_EQUAL(table.name, @"", "the default name");
	MAD_PASS(table.numberOfRows == (NSUInteger)0, "no rows");
	MAD_PASS(table.count == (NSUInteger)0, "count is zero");
	MAD_PASS(table.numberOfColumns == (NSUInteger)0, "no columns");
	MAD_PASS_EQUAL(table.allObjects, @[], "no objects");
}

static void testAddColumnAndAddRow(void) {
	MADDataTableVirtual *table = twoColumnTable();

	MAD_PASS(table.numberOfColumns == (NSUInteger)2, "two columns");
	MAD_PASS_EQUAL(table.columnKeys, (@[@"a", @"b"]), "the column keys in order");
	NSArray *row = @[@"alpha", @1];
	MAD_PASS([table addRow:row error:NULL], "the row is added");

	MAD_PASS(table.numberOfRows == (NSUInteger)1, "one row");
	MAD_PASS(table.count == (NSUInteger)1, "the count agrees");
	MAD_PASS_EQUAL(table[0][@"a"], @"alpha", "the first field");
	MAD_PASS_EQUAL(table[0][@"b"], @1, "the second field");
	// The indexed row is stamped with its row id.
	MAD_PASS_EQUAL(table[0][@"~rowid~"], @0, "the row id");
	// Column view and row view agree.
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"alpha", "the column view of the first field");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @1, "the column view of the second field");
}

static void testObjectAtIndexAndSubscriptAgree(void) {
	MADDataTableVirtual *table = twoColumnTable();
	[table addRow:@[@"alpha", @1] error:NULL];

	MAD_PASS([table objectAtIndex:0] == [table objectAtIndexedSubscript:0], "objectAtIndex: and the subscript agree");
	MAD_PASS([table objectAtIndex:0] == [table objectAtRow:0], "objectAtIndex: and objectAtRow: agree");
}

static void testColumnsEnumerator(void) {
	MADDataTableVirtual *table = twoColumnTable();

	// Dictionary enumeration order is unspecified, so the set of columns is asserted.
	NSMutableSet<NSString *> *identifiers = [NSMutableSet set];
	for (MADDataColumn *column in [table columnsEnumerator]) {
		[identifiers addObject:column.identifier];
	}

	MAD_PASS(identifiers.count == (NSUInteger)2, "two columns enumerated");
	MAD_PASS([identifiers containsObject:@"a"], "column a is enumerated");
	MAD_PASS([identifiers containsObject:@"b"], "column b is enumerated");
}

#pragma mark - Short rows

static void testShortRowLeavesTheColumnViewDesynchronized(void) {
	MADDataTableVirtual *table = twoColumnTable();

	// Only one value for two columns: the dictionary row is stored as given, the
	// column objects get only what was supplied, and the row counter still advances.
	[table addRow:@[@"alpha"] error:NULL];

	MAD_PASS(table.numberOfRows == (NSUInteger)1, "the row counter advanced");
	MAD_PASS_EQUAL(table[0][@"a"], @"alpha", "the supplied field");
	MAD_PASS(table[0][@"b"] == nil, "the missing field is nil");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"alpha", "the column view of the supplied field");
	// -objectAtRow:column: for the missing column asserts inside MADDataColumn,
	// which is the desync surfacing; recorded, not pinned here.
}

#pragma mark - Plist and coding

static void testCopyPlistCarriesTheSortIndexKey(void) {
	MADDataTableVirtual *table = twoColumnTable();
	[table addRow:@[@"alpha", @1] error:NULL];

	NSDictionary *plist = [table copyPlist];

	// Virtual extends the base plist with the row index under "sortIndex".
	MAD_PASS(plist[@"sortIndex"] != nil, "the sortIndex key is present");
	MAD_PASS([plist[@"sortIndex"] count] == (NSUInteger)1, "one indexed row");
	MAD_PASS_EQUAL(plist[@"columnKeys"], (@[@"a", @"b"]), "the column keys");
}

static void testNSCodingRoundTripPreservesRowsAndColumns(void) {
	MADDataTableVirtual *table = twoColumnTable();
	[table addRow:@[@"alpha", @1] error:NULL];

	// MADDataTable is NSCoding-only, so the insecure path is the one it
	// satisfies; GNUstep has no -initForReadingFromData:error:, so the
	// portable class pair is the same round trip.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:table];
	MADDataTableVirtual *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	MAD_PASS(decoded != nil, "the table decodes");

	MAD_PASS(decoded.numberOfRows == (NSUInteger)1, "one row");
	MAD_PASS_EQUAL(decoded[0][@"a"], @"alpha", "the row data");
	MAD_PASS_EQUAL(decoded.columnKeys, (@[@"a", @"b"]), "the column keys");
	MAD_PASS_EQUAL([decoded objectAtRow:0 column:1], @1, "the column view");
}

#pragma mark - Clearing

static void testRemoveAllObjectsClearsRowsColumnsAndMetadata(void) {
	MADDataTableVirtual *table = twoColumnTable();
	[table addRow:@[@"alpha", @1] error:NULL];
	[table sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"a" ascending:YES]]];

	[table removeAllObjects];

	MAD_PASS(table.numberOfRows == (NSUInteger)0, "no rows");
	MAD_PASS(table.numberOfColumns == (NSUInteger)0, "no columns");
	MAD_PASS(table.rowCounter == (NSUInteger)0, "the row counter is reset");
	MAD_PASS_EQUAL(table.allObjects, @[], "no objects");
	MAD_PASS_EQUAL(table.columnKeys, @[], "no column keys");
	MAD_PASS_EQUAL(table.sortDescriptors, @[], "no sort descriptors");
}

MAD_TEST_MAIN("MADDataTableVirtualTests",
	MAD_TEST(testInitDefaults),
	MAD_TEST(testAddColumnAndAddRow),
	MAD_TEST(testObjectAtIndexAndSubscriptAgree),
	MAD_TEST(testColumnsEnumerator),
	MAD_TEST(testShortRowLeavesTheColumnViewDesynchronized),
	MAD_TEST(testCopyPlistCarriesTheSortIndexKey),
	MAD_TEST(testNSCodingRoundTripPreservesRowsAndColumns),
	MAD_TEST(testRemoveAllObjectsClearsRowsColumnsAndMetadata));
