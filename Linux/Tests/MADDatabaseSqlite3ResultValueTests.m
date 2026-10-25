//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDatabaseSqlite3ResultValueTests.m
//  Linux/Tests
//
//  Ported from MADSqlite3Tests/MADDatabaseSqlite3ResultValueTests.m: coverage for
//  the two result-value factories on MADDatabaseSqlite3, driven against a real
//  in-memory sqlite3 database.  The untyped factory is the hot path every fast
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
//  The XCTest setUp/tearDown pair is per-test fixture helpers here.  A fixture that
//  cannot be built fails its test and stops it there, rather than letting every
//  assertion below dereference a NULL statement.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/sqlite3.h>

#import <math.h>

#pragma mark - Fixture

// The Xcode suite's -setUp: an in-memory database with one row of every column
// type the factories branch on, already stepped to that row.
typedef struct {
	sqlite3 *database;
	sqlite3_stmt *statement;
} MADResultValueFixture;

static BOOL MADResultValueFixtureOpen(MADResultValueFixture *fixture) {
	fixture->database = NULL;
	fixture->statement = NULL;
	if (sqlite3_open(":memory:", &fixture->database) != SQLITE_OK) {
		return NO;
	}
	if (sqlite3_exec(fixture->database,
					 "CREATE TABLE t (i INTEGER, r REAL, s TEXT, b BLOB, n TEXT);"
					 "INSERT INTO t VALUES (42, 1.5, 'hello', x'0102', NULL);",
					 NULL, NULL, NULL) != SQLITE_OK) {
		return NO;
	}
	if (sqlite3_prepare_v2(fixture->database, "SELECT i, r, s, b, n FROM t", -1, &fixture->statement, NULL) != SQLITE_OK) {
		return NO;
	}
	return sqlite3_step(fixture->statement) == SQLITE_ROW;
}

static void MADResultValueFixtureClose(MADResultValueFixture *fixture) {
	sqlite3_finalize(fixture->statement);
	fixture->statement = NULL;
	sqlite3_close(fixture->database);
	fixture->database = NULL;
}

#pragma mark - Untyped factory (the hot path)

static void testUntypedFactoryMapsEverySqliteColumnType(void) {
	MADResultValueFixture fixture;
	MAD_PASS(MADResultValueFixtureOpen(&fixture), "the in-memory database with one mixed row is available");
	if (fixture.statement == NULL) {
		return;
	}

	NSObject *integer = [MADDatabaseSqlite3 databaseResultValue:fixture.statement columnNumber:0];
	MAD_PASS([integer isKindOfClass:[NSNumber class]], "the integer column is a number");
	MAD_PASS_EQUAL(integer, @42, "the integer column's value");

	NSObject *real = [MADDatabaseSqlite3 databaseResultValue:fixture.statement columnNumber:1];
	MAD_PASS([real isKindOfClass:[NSNumber class]], "the real column is a number");
	MAD_PASS(fabs([(NSNumber *)real doubleValue] - 1.5) < 0.0001, "the real column's value");

	NSObject *text = [MADDatabaseSqlite3 databaseResultValue:fixture.statement columnNumber:2];
	MAD_PASS([text isKindOfClass:[NSString class]], "the text column is a string");
	MAD_PASS_EQUAL(text, @"hello", "the text column's value");

	NSObject *blob = [MADDatabaseSqlite3 databaseResultValue:fixture.statement columnNumber:3];
	MAD_PASS([blob isKindOfClass:[NSData class]], "the blob column is data");
	MAD_PASS(((NSData *)blob).length == (NSUInteger)2, "the blob column's length");

	NSObject *null = [MADDatabaseSqlite3 databaseResultValue:fixture.statement columnNumber:4];
	MAD_PASS_EQUAL(null, [NSNull null], "the null column is NSNull");

	MADResultValueFixtureClose(&fixture);
}

#pragma mark - Declared-type factory, numeric and blob branches

static void testCastFactoryMapsTheNumericFamily(void) {
	MADResultValueFixture fixture;
	MAD_PASS(MADResultValueFixtureOpen(&fixture), "the in-memory database with one mixed row is available");
	if (fixture.statement == NULL) {
		return;
	}

	NSNumber *integer = (NSNumber *)[MADDatabaseSqlite3 databaseResultValueCast:fixture.statement
																forColumnNumber:0
																	   withType:MADDataTypeInteger];
	MAD_PASS_EQUAL(integer, @42, "the declared integer's value");

	NSNumber *asLong = (NSNumber *)[MADDatabaseSqlite3 databaseResultValueCast:fixture.statement
															   forColumnNumber:0
																	  withType:MADDataTypeLong];
	MAD_PASS_EQUAL(asLong, @42, "the declared long's value");

	NSNumber *asShort = (NSNumber *)[MADDatabaseSqlite3 databaseResultValueCast:fixture.statement
																forColumnNumber:0
																	   withType:MADDataTypeShort];
	MAD_PASS(asShort.intValue == 42, "the declared short's value");

	NSNumber *real = (NSNumber *)[MADDatabaseSqlite3 databaseResultValueCast:fixture.statement
															 forColumnNumber:1
																	withType:MADDataTypeDouble];
	MAD_PASS(fabs(real.doubleValue - 1.5) < 0.0001, "the declared double's value");

	NSNumber *asDecimal = (NSNumber *)[MADDatabaseSqlite3 databaseResultValueCast:fixture.statement
																  forColumnNumber:1
																		 withType:MADDataTypeDecimal];
	MAD_PASS(fabs(asDecimal.doubleValue - 1.5) < 0.0001, "the declared decimal's value");

	MADResultValueFixtureClose(&fixture);
}

static void testCastFactoryReadsBlobs(void) {
	MADResultValueFixture fixture;
	MAD_PASS(MADResultValueFixtureOpen(&fixture), "the in-memory database with one mixed row is available");
	if (fixture.statement == NULL) {
		return;
	}

	NSData *blob = (NSData *)[MADDatabaseSqlite3 databaseResultValueCast:fixture.statement
														 forColumnNumber:3
																withType:MADDataTypeBlob];
	MAD_PASS([blob isKindOfClass:[NSData class]], "the declared blob is data");
	MAD_PASS(blob.length == (NSUInteger)2, "the declared blob's length");

	NSData *asImage = (NSData *)[MADDatabaseSqlite3 databaseResultValueCast:fixture.statement
															forColumnNumber:3
																   withType:MADDataTypeImage];
	MAD_PASS(asImage.length == (NSUInteger)2, "the declared image's length");

	MADResultValueFixtureClose(&fixture);
}

static void testCastFactoryAnswersNullForUnknownAndNullTypes(void) {
	MADResultValueFixture fixture;
	MAD_PASS(MADResultValueFixtureOpen(&fixture), "the in-memory database with one mixed row is available");
	if (fixture.statement == NULL) {
		return;
	}

	NSObject *unknown = [MADDatabaseSqlite3 databaseResultValueCast:fixture.statement
													forColumnNumber:2
														   withType:MADDataTypeUnknown];
	MAD_PASS_EQUAL(unknown, [NSNull null], "an unknown declared type is NSNull");

	NSObject *nullType = [MADDatabaseSqlite3 databaseResultValueCast:fixture.statement
													 forColumnNumber:4
															withType:MADDataTypeNull];
	MAD_PASS_EQUAL(nullType, [NSNull null], "a null declared type is NSNull");

	MADResultValueFixtureClose(&fixture);
}

#pragma mark - Declared-type factory, date/time fall-through

static void testCastFactoryDateFamilyOnANonTextColumnAnswersNothing(void) {
	MADResultValueFixture fixture;
	MAD_PASS(MADResultValueFixtureOpen(&fixture), "the in-memory database with one mixed row is available");
	if (fixture.statement == NULL) {
		return;
	}

	// The date/time family falls to the default branch, which only answers when the
	// column actually holds text; on anything else the strong local stays nil.  The
	// header declares the return nonnull, so this documents the gap.
	NSObject *dateOnInteger = [MADDatabaseSqlite3 databaseResultValueCast:fixture.statement
														  forColumnNumber:0
																 withType:MADDataTypeDate];
	MAD_PASS(dateOnInteger == nil, "the date family on a non-text column answers nothing");

	MADResultValueFixtureClose(&fixture);
}

MAD_TEST_MAIN("MADDatabaseSqlite3ResultValueTests",
	MAD_TEST(testUntypedFactoryMapsEverySqliteColumnType),
	MAD_TEST(testCastFactoryMapsTheNumericFamily),
	MAD_TEST(testCastFactoryReadsBlobs),
	MAD_TEST(testCastFactoryAnswersNullForUnknownAndNullTypes),
	MAD_TEST(testCastFactoryDateFamilyOnANonTextColumnAnswersNothing));
