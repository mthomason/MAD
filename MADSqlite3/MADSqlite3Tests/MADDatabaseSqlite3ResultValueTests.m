//
//  MADDatabaseSqlite3ResultValueTests.m
//  MADSqlite3Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the two result-value factories on MADDatabaseSqlite3, driven against
//  a real in-memory sqlite3 database.  The untyped factory is the hot path every fast
//  table and enumerator read goes through; the cast factory is its declared-type
//  sibling.
//
//  One case is deliberately NOT exercised: the cast factory's text-family branches
//  call free() on the pointer sqlite3_column_text hands back, which belongs to the
//  statement -- calling them would corrupt the heap rather than fail a test.  See
//  BUGS.md.
//
//  MADDatabaseResultValue (MADSqlite3/Source/MADDatabaseResultValue.m) is a dead
//  near-copy of these two methods: the file is in no target's Sources phase, so the
//  class is in no binary and cannot be linked against.  Also recorded in BUGS.md.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>

#import "MADDatabaseSqlite3.h"
#import "sqlite3.h"

@interface MADDatabaseSqlite3ResultValueTests : XCTestCase

@property (nonatomic, assign) sqlite3 *database;
@property (nonatomic, assign) sqlite3_stmt *statement;

@end

@implementation MADDatabaseSqlite3ResultValueTests

- (void)setUp {
	[super setUp];
	XCTAssertEqual(sqlite3_open(":memory:", &_database), SQLITE_OK);
	XCTAssertEqual(sqlite3_exec(self.database,
								"CREATE TABLE t (i INTEGER, r REAL, s TEXT, b BLOB, n TEXT);"
								"INSERT INTO t VALUES (42, 1.5, 'hello', x'0102', NULL);",
								NULL, NULL, NULL), SQLITE_OK);
	XCTAssertEqual(sqlite3_prepare_v2(self.database, "SELECT i, r, s, b, n FROM t", -1, &_statement, NULL), SQLITE_OK);
	XCTAssertEqual(sqlite3_step(self.statement), SQLITE_ROW);
}

- (void)tearDown {
	sqlite3_finalize(_statement);
	_statement = NULL;
	sqlite3_close(_database);
	_database = NULL;
	[super tearDown];
}

#pragma mark - Untyped factory (the hot path)

- (void)testUntypedFactoryMapsEverySqliteColumnType {
	NSObject *integer = [MADDatabaseSqlite3 databaseResultValue:self.statement columnNumber:0];
	XCTAssertTrue([integer isKindOfClass:[NSNumber class]]);
	XCTAssertEqualObjects(integer, @42);

	NSObject *real = [MADDatabaseSqlite3 databaseResultValue:self.statement columnNumber:1];
	XCTAssertTrue([real isKindOfClass:[NSNumber class]]);
	XCTAssertEqualWithAccuracy([(NSNumber *)real doubleValue], 1.5, 0.0001);

	NSObject *text = [MADDatabaseSqlite3 databaseResultValue:self.statement columnNumber:2];
	XCTAssertTrue([text isKindOfClass:[NSString class]]);
	XCTAssertEqualObjects(text, @"hello");

	NSObject *blob = [MADDatabaseSqlite3 databaseResultValue:self.statement columnNumber:3];
	XCTAssertTrue([blob isKindOfClass:[NSData class]]);
	XCTAssertEqual(((NSData *)blob).length, (NSUInteger)2);

	NSObject *null = [MADDatabaseSqlite3 databaseResultValue:self.statement columnNumber:4];
	XCTAssertEqual(null, [NSNull null]);
}

#pragma mark - Declared-type factory, numeric and blob branches

- (void)testCastFactoryMapsTheNumericFamily {
	NSNumber *integer = (NSNumber *)[MADDatabaseSqlite3 databaseResultValueCast:self.statement
																forColumnNumber:0
																	   withType:MADDataTypeInteger];
	XCTAssertEqualObjects(integer, @42);

	NSNumber *asLong = (NSNumber *)[MADDatabaseSqlite3 databaseResultValueCast:self.statement
															   forColumnNumber:0
																	  withType:MADDataTypeLong];
	XCTAssertEqualObjects(asLong, @42);

	NSNumber *asShort = (NSNumber *)[MADDatabaseSqlite3 databaseResultValueCast:self.statement
																forColumnNumber:0
																	   withType:MADDataTypeShort];
	XCTAssertEqual(asShort.intValue, 42);

	NSNumber *real = (NSNumber *)[MADDatabaseSqlite3 databaseResultValueCast:self.statement
															 forColumnNumber:1
																	withType:MADDataTypeDouble];
	XCTAssertEqualWithAccuracy(real.doubleValue, 1.5, 0.0001);

	NSNumber *asDecimal = (NSNumber *)[MADDatabaseSqlite3 databaseResultValueCast:self.statement
																  forColumnNumber:1
																		 withType:MADDataTypeDecimal];
	XCTAssertEqualWithAccuracy(asDecimal.doubleValue, 1.5, 0.0001);
}

- (void)testCastFactoryReadsBlobs {
	NSData *blob = (NSData *)[MADDatabaseSqlite3 databaseResultValueCast:self.statement
														 forColumnNumber:3
																withType:MADDataTypeBlob];
	XCTAssertTrue([blob isKindOfClass:[NSData class]]);
	XCTAssertEqual(blob.length, (NSUInteger)2);

	NSData *asImage = (NSData *)[MADDatabaseSqlite3 databaseResultValueCast:self.statement
															forColumnNumber:3
																   withType:MADDataTypeImage];
	XCTAssertEqual(asImage.length, (NSUInteger)2);
}

- (void)testCastFactoryAnswersNullForUnknownAndNullTypes {
	NSObject *unknown = [MADDatabaseSqlite3 databaseResultValueCast:self.statement
													forColumnNumber:2
														   withType:MADDataTypeUnknown];
	XCTAssertEqual(unknown, [NSNull null]);

	NSObject *nullType = [MADDatabaseSqlite3 databaseResultValueCast:self.statement
													 forColumnNumber:4
															withType:MADDataTypeNull];
	XCTAssertEqual(nullType, [NSNull null]);
}

#pragma mark - Declared-type factory, date/time fall-through

- (void)testCastFactoryDateFamilyOnANonTextColumnAnswersNothing {
	// The date/time family falls to the default branch, which only answers when the
	// column actually holds text; on anything else the strong local stays nil.  The
	// header declares the return nonnull, so this documents the gap.
	NSObject *dateOnInteger = [MADDatabaseSqlite3 databaseResultValueCast:self.statement
														  forColumnNumber:0
																 withType:MADDataTypeDate];
	XCTAssertNil(dateOnInteger);
}

@end
