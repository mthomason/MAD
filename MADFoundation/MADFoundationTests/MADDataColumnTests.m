//
//  MADDataColumnTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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
	// dataLength comes from the parameter of the matching name.  `number`,
	// `indexOfType` and `length` are still unused.
	XCTAssertEqual(column.dataLength, (int64_t)99);
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

- (void)testAddRowsAddsExactCount {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addRows:2];
	XCTAssertEqual([self plistColumn:column].count, (NSUInteger)2);
	XCTAssertEqualObjects([column objectAtIndex:0], [NSNull null]);
	XCTAssertEqualObjects([column objectAtIndex:1], [NSNull null]);
}

- (void)testAddRowsZeroAddsNoRows {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	[column addRows:0];
	XCTAssertEqual([self plistColumn:column].count, (NSUInteger)0);
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

- (void)testPlistRoundTripRestoresNullDefault {
	// initWithPlist: decodes the "~MTNull~" sentinel back to NSNull, so the
	// round trip is symmetric with copyPlist.
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	MADDataColumn *decoded = [[MADDataColumn alloc] initWithPlist:[column copyPlist]];
	XCTAssertEqualObjects(decoded.defaultValue, [NSNull null]);
}

- (void)testPlistRoundTripPreservesNonNullDefault {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	column.defaultValue = @"fallback";
	MADDataColumn *decoded = [[MADDataColumn alloc] initWithPlist:[column copyPlist]];
	XCTAssertEqualObjects(decoded.defaultValue, @"fallback");
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

- (void)testCodingRoundTripPreservesNotNullAndAutoIncrement {
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
	XCTAssertTrue(decoded.notNull);
	XCTAssertTrue(decoded.autoIncrement);
}

@end
