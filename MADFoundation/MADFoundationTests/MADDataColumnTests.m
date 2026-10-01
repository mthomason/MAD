//
//  MADDataColumnTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADDataColumn, the column struct used by the SQLite result
//  cache.  This locks down init variants, row storage, plist/coding round trips,
//  and documents a few quirks in the process.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataColumn.h>

@interface MADDataColumnTests : XCTestCase
@end

@implementation MADDataColumnTests

- (NSArray *)plistColumn:(MADDataColumn *)column {
	// The column's backing array is surfaced through copyPlist under key "column".
	return [[column copyPlist] objectForKey:@"column"];
}

#pragma mark - Initializers

- (void)testInitWithIdentifierDefaults {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"col"];
	XCTAssertEqualObjects(column.identifier, @"col");
	XCTAssertEqualObjects(column.caption, @"col");
	XCTAssertEqualObjects(column.fieldName, @"col");
	XCTAssertEqual(column.type, MADDataTypeBit);          // default 0
	XCTAssertEqual(column.nativeType, (int16_t)0);
	XCTAssertEqual(column.dataLength, (int64_t)0);
	XCTAssertEqual(column.dataPercision, (int32_t)0);
	XCTAssertFalse(column.primaryKey);
	XCTAssertFalse(column.notNull);
	XCTAssertFalse(column.autoIncrement);
	XCTAssertTrue([column.defaultValue isEqual:[NSNull null]]);
	XCTAssertEqual([self plistColumn:column].count, (NSUInteger)0);
}

- (void)testNewDataColumnWithIdentifier {
	MADDataColumn *column = [MADDataColumn newDataColumnWithIdentifier:@"pk"];
	XCTAssertEqualObjects(column.identifier, @"pk");
	XCTAssertEqual(column.type, MADDataTypeInteger);
	XCTAssertTrue(column.primaryKey);
	XCTAssertTrue(column.notNull);
	XCTAssertFalse(column.autoIncrement);
}

- (void)testInitWithType {
	MADDataColumn *column = [[MADDataColumn alloc] initWithType:MADDataTypeString
														  name:@"name"
														number:7
													   dataLen:99
												   indexOfType:3
														length:255
													 percision:10
													nativeType:22];
	XCTAssertEqualObjects(column.identifier, @"name");
	XCTAssertEqualObjects(column.caption, @"name");
	XCTAssertEqualObjects(column.fieldName, @"name");
	XCTAssertEqual(column.type, MADDataTypeString);
	// Quirk: the `length` parameter is stored as dataLength; the `dataLen`
	// parameter is ignored.
	XCTAssertEqual(column.dataLength, (int64_t)255);
	XCTAssertEqual(column.dataPercision, (int32_t)10);
	XCTAssertEqual(column.nativeType, (int16_t)22);
}

#pragma mark - Row storage

- (void)testAddObjectAndObjectAtIndex {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addObject:@"a"];
	[column addObject:@"b"];
	XCTAssertEqualObjects([column objectAtIndex:0], @"a");
	XCTAssertEqualObjects([column objectAtIndex:1], @"b");
}

- (void)testAddRowsOffByOne {
	// Known defect: addRows: uses `i <= count`, appending one more row than
	// requested.  addRows:2 produces three default rows.
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addRows:2];
	XCTAssertEqual([self plistColumn:column].count, (NSUInteger)3);
	XCTAssertTrue((id)[column objectAtIndex:2] == [NSNull null]);
}

- (void)testAddRowsZeroAddsOneRow {
	// Corollary of the same off-by-one: addRows:0 still appends one row.
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addRows:0];
	XCTAssertEqual([self plistColumn:column].count, (NSUInteger)1);
}

- (void)testRemoveAllObjects {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addObject:@"a"];
	[column removeAllObjects];
	XCTAssertEqual([self plistColumn:column].count, (NSUInteger)0);
}

#pragma mark - Plist round trip

- (void)testCopyPlistEncodesNullDefaultAsSentinel {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	NSDictionary *plist = [column copyPlist];
	// NSNull is written to the plist as the string sentinel "~MTNull~".
	XCTAssertEqualObjects(plist[@"defaultValue"], @"~MTNull~");
}

- (void)testPlistRoundTripDoesNotRestoreNullDefault {
	// Known defect: copyPlist turns NSNull into "~MTNull~", but initWithPlist:
	// does not decode that sentinel back, so a plist round trip yields a string.
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	MADDataColumn *decoded = [[MADDataColumn alloc] initWithPlist:[column copyPlist]];
	XCTAssertEqualObjects(decoded.defaultValue, @"~MTNull~");
	XCTAssertFalse([decoded.defaultValue isEqual:[NSNull null]]);
}

- (void)testPlistRoundTripPreservesColumnData {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addObject:@"a"];
	[column addObject:@"b"];
	MADDataColumn *decoded = [[MADDataColumn alloc] initWithPlist:[column copyPlist]];
	XCTAssertEqualObjects([decoded objectAtIndex:0], @"a");
	XCTAssertEqualObjects([decoded objectAtIndex:1], @"b");
}

#pragma mark - NSCopying

- (void)testCopy {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	column.type = MADDataTypeString;
	column.primaryKey = YES;
	MADDataColumn *copy = [column copy];
	XCTAssertNotNil(copy);
	XCTAssertTrue(copy != column);
	XCTAssertEqualObjects(copy.identifier, @"c");
	XCTAssertEqual(copy.type, MADDataTypeString);
	XCTAssertTrue(copy.primaryKey);
}

- (void)testCopyHasIndependentColumnStorage {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addObject:@"a"];
	MADDataColumn *copy = [column copy];
	[copy addObject:@"b"];
	XCTAssertEqual([self plistColumn:column].count, (NSUInteger)1);
	XCTAssertEqual([self plistColumn:copy].count, (NSUInteger)2);
}

#pragma mark - NSCoding

- (void)testCodingRoundTripLosesNotNullAndAutoIncrement {
	// Known defect: initWithCoder: decodes primaryKey but never decodes notNull
	// or autoIncrement, so those two flags are dropped on an encode/decode cycle.
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	column.primaryKey = YES;
	column.notNull = YES;
	column.autoIncrement = YES;
	column.type = MADDataTypeInteger;

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:column requiringSecureCoding:NO error:&error];
	XCTAssertNil(error);
	MADDataColumn *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(decoded);

	XCTAssertEqualObjects(decoded.identifier, @"c");
	XCTAssertEqual(decoded.type, MADDataTypeInteger);
	XCTAssertTrue(decoded.primaryKey);
	XCTAssertFalse(decoded.notNull);      // lost in round trip
	XCTAssertFalse(decoded.autoIncrement); // lost in round trip
}

@end
