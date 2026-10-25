//
//  MADDataColumnTests.m
//  Linux/Tests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Ported from MADFoundationTests/MADDataColumnTests.m: coverage for
//  MADDataColumn, the column struct used by the SQLite result cache.  Locks
//  down init variants, row storage, plist/coding round trips.
//
//  The original's coding test used unarchiveTopLevelObjectWithData:error:,
//  which GNUstep does not implement; the classic entry point is used instead
//  (same coder machinery, see the Phase B report in MAD_LINUX.md).
//

#import "MADTestSupport.h"
#import <MADFoundation/MADDataColumn.h>

static NSArray *plistColumn(MADDataColumn *column) {
	// The column's backing array is surfaced through copyPlist under key "column".
	return [[column copyPlist] objectForKey:@"column"];
}

#pragma mark - Initializers

static void testInitWithIdentifierDefaults(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"col"];
	MAD_PASS_EQUAL(column.identifier, @"col", "identifier");
	MAD_PASS_EQUAL(column.caption, @"col", "caption");
	MAD_PASS_EQUAL(column.fieldName, @"col", "fieldName");
	MAD_PASS(column.type == MADDataTypeBit, "type default 0");
	MAD_PASS(column.nativeType == (int16_t)0, "nativeType default");
	MAD_PASS(column.dataLength == (int64_t)0, "dataLength default");
	MAD_PASS(column.dataPercision == (int32_t)0, "dataPercision default");
	MAD_PASS(!column.primaryKey, "not primary key");
	MAD_PASS(!column.notNull, "nullable");
	MAD_PASS(!column.autoIncrement, "not auto increment");
	MAD_PASS([column.defaultValue isEqual:[NSNull null]], "default is NSNull");
	MAD_PASS(plistColumn(column).count == (NSUInteger)0, "no rows");
}

static void testNewDataColumnWithIdentifier(void) {
	MADDataColumn *column = [MADDataColumn newDataColumnWithIdentifier:@"pk"];
	MAD_PASS_EQUAL(column.identifier, @"pk", "identifier");
	MAD_PASS(column.type == MADDataTypeInteger, "integer type");
	MAD_PASS(column.primaryKey, "primary key");
	MAD_PASS(column.notNull, "not null");
	MAD_PASS(!column.autoIncrement, "not auto increment");
}

static void testInitWithType(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithType:MADDataTypeString
														  name:@"name"
														number:7
													   dataLen:99
												   indexOfType:3
														length:255
													 percision:10
													nativeType:22];
	MAD_PASS_EQUAL(column.identifier, @"name", "identifier");
	MAD_PASS_EQUAL(column.caption, @"name", "caption");
	MAD_PASS_EQUAL(column.fieldName, @"name", "fieldName");
	MAD_PASS(column.type == MADDataTypeString, "string type");
	// dataLength comes from the parameter of the matching name.  `number`,
	// `indexOfType` and `length` are still unused.
	MAD_PASS(column.dataLength == (int64_t)99, "dataLength");
	MAD_PASS(column.dataPercision == (int32_t)10, "dataPercision");
	MAD_PASS(column.nativeType == (int16_t)22, "nativeType");
}

#pragma mark - Row storage

static void testAddObjectAndObjectAtIndex(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addObject:@"a"];
	[column addObject:@"b"];
	MAD_PASS_EQUAL([column objectAtIndex:0], @"a", "first row");
	MAD_PASS_EQUAL([column objectAtIndex:1], @"b", "second row");
}

static void testAddRowsAddsExactCount(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addRows:2];
	MAD_PASS(plistColumn(column).count == (NSUInteger)2, "two rows");
	MAD_PASS_EQUAL([column objectAtIndex:0], [NSNull null], "first row is null");
	MAD_PASS_EQUAL([column objectAtIndex:1], [NSNull null], "second row is null");
}

static void testAddRowsZeroAddsNoRows(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addRows:0];
	MAD_PASS(plistColumn(column).count == (NSUInteger)0, "no rows");
}

static void testRemoveAllObjects(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addObject:@"a"];
	[column removeAllObjects];
	MAD_PASS(plistColumn(column).count == (NSUInteger)0, "no rows");
}

#pragma mark - Plist round trip

static void testCopyPlistEncodesNullDefaultAsSentinel(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	NSDictionary *plist = [column copyPlist];
	// NSNull is written to the plist as the string sentinel "~MTNull~".
	MAD_PASS_EQUAL(plist[@"defaultValue"], @"~MTNull~", "null sentinel");
}

static void testPlistRoundTripRestoresNullDefault(void) {
	// initWithPlist: decodes the "~MTNull~" sentinel back to NSNull, so the
	// round trip is symmetric with copyPlist.
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	MADDataColumn *decoded = [[MADDataColumn alloc] initWithPlist:[column copyPlist]];
	MAD_PASS_EQUAL(decoded.defaultValue, [NSNull null], "default restored to NSNull");
}

static void testPlistRoundTripPreservesNonNullDefault(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	column.defaultValue = @"fallback";
	MADDataColumn *decoded = [[MADDataColumn alloc] initWithPlist:[column copyPlist]];
	MAD_PASS_EQUAL(decoded.defaultValue, @"fallback", "default preserved");
}

static void testPlistRoundTripPreservesColumnData(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addObject:@"a"];
	[column addObject:@"b"];
	MADDataColumn *decoded = [[MADDataColumn alloc] initWithPlist:[column copyPlist]];
	MAD_PASS_EQUAL([decoded objectAtIndex:0], @"a", "first row");
	MAD_PASS_EQUAL([decoded objectAtIndex:1], @"b", "second row");
}

#pragma mark - NSCopying

static void testCopy(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	column.type = MADDataTypeString;
	column.primaryKey = YES;
	MADDataColumn *copy = [column copy];
	MAD_PASS(copy != nil, "copy is not nil");
	MAD_PASS(copy != column, "copy is a distinct object");
	MAD_PASS_EQUAL(copy.identifier, @"c", "identifier");
	MAD_PASS(copy.type == MADDataTypeString, "type");
	MAD_PASS(copy.primaryKey, "primary key");
}

static void testCopyHasIndependentColumnStorage(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addObject:@"a"];
	MADDataColumn *copy = [column copy];
	[copy addObject:@"b"];
	MAD_PASS(plistColumn(column).count == (NSUInteger)1, "original keeps one row");
	MAD_PASS(plistColumn(copy).count == (NSUInteger)2, "copy has two rows");
}

#pragma mark - NSCoding

static void testCodingRoundTripPreservesNotNullAndAutoIncrement(void) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	column.primaryKey = YES;
	column.notNull = YES;
	column.autoIncrement = YES;
	column.type = MADDataTypeInteger;

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:column requiringSecureCoding:NO error:&error];
	MAD_PASS(error == nil, "no error archiving");
	MAD_PASS(data != nil, "archive");

	MADDataColumn *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	MAD_PASS(decoded != nil, "decoded");

	MAD_PASS_EQUAL(decoded.identifier, @"c", "identifier");
	MAD_PASS(decoded.type == MADDataTypeInteger, "type");
	MAD_PASS(decoded.primaryKey, "primary key");
	MAD_PASS(decoded.notNull, "not null");
	MAD_PASS(decoded.autoIncrement, "auto increment");
}

MAD_TEST_MAIN("MADDataColumnTests",
	MAD_TEST(testInitWithIdentifierDefaults),
	MAD_TEST(testNewDataColumnWithIdentifier),
	MAD_TEST(testInitWithType),
	MAD_TEST(testAddObjectAndObjectAtIndex),
	MAD_TEST(testAddRowsAddsExactCount),
	MAD_TEST(testAddRowsZeroAddsNoRows),
	MAD_TEST(testRemoveAllObjects),
	MAD_TEST(testCopyPlistEncodesNullDefaultAsSentinel),
	MAD_TEST(testPlistRoundTripRestoresNullDefault),
	MAD_TEST(testPlistRoundTripPreservesNonNullDefault),
	MAD_TEST(testPlistRoundTripPreservesColumnData),
	MAD_TEST(testCopy),
	MAD_TEST(testCopyHasIndependentColumnStorage),
	MAD_TEST(testCodingRoundTripPreservesNotNullAndAutoIncrement));
