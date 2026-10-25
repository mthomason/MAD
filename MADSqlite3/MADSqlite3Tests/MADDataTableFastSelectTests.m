//
//  MADDataTableFastSelectTests.m
//  MADSqlite3Tests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the MADDataTableFast surface the existing suites do not reach: the
//  group-key WHERE clause, the read-transaction pair, and -runSelectQuery: (the
//  column-0 select behind the per-page reads).  Everything runs on a real fast table
//  whose cache directory is a per-test temp directory, so the selects connection is a
//  real sqlite3 handle without touching the application's cache.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataTable.h>
#import <MADAPI/MADQuery.h>

#import "MADDataTableFast.h"
#import "MADDatabaseSqlite3.h"
#import "MADQueryCacheSelectLimitOffset.h"

#pragma mark - Test query

// The smallest query -runSelectQuery: accepts: fixed SQL, no bindings.
@interface MADFlatSelectQuery : MADQuery <MADQueryDataBindingProtocol>
@property (nonatomic, strong) NSMutableArray *binaryBindings;
@property (nonatomic, copy) NSString *sql;
@end

@implementation MADFlatSelectQuery
- (NSString *)getSql:(NSError * __autoreleasing *)error { return self.sql; }
@end

@interface MADDataTableFastSelectTests : XCTestCase

@property (nonatomic, strong) NSURL *directory;

@end

@implementation MADDataTableFastSelectTests

- (void)setUp {
	[super setUp];
	self.directory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString]
								isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:self.directory
							 withIntermediateDirectories:YES attributes:nil error:NULL];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:self.directory error:NULL];
	[super tearDown];
}

- (MADDataTableFast *)fastTable {
	return [[MADDataTableFast alloc] initWithId:7 cacheDirectory:self.directory];
}

#pragma mark - Group-key WHERE clause

- (void)testGroupKeysProducePositionalColumnValuePairs {
	MADDataTableFast *table = [self fastTable];
	table.columnKeys = [@[@"a", @"b"] mutableCopy];
	table.sortDescriptors = [@[[NSSortDescriptor sortDescriptorWithKey:@"a" ascending:YES],
							   [NSSortDescriptor sortDescriptorWithKey:@"b" ascending:YES]] mutableCopy];

	NSArray<NSDictionary *> *clause = [table whereClauseForGroupKeys:@[@"A", @"B"]];

	XCTAssertEqual(clause.count, (NSUInteger)2);
	// Each entry pairs the sort descriptor's key with the group key at the same index.
	XCTAssertEqualObjects(clause[0][MADQueryKeyPredicateColumn], @"a");
	XCTAssertEqualObjects(clause[0][MADQueryKeyPredicateValue], @"A");
	XCTAssertEqualObjects(clause[1][MADQueryKeyPredicateColumn], @"b");
	XCTAssertEqualObjects(clause[1][MADQueryKeyPredicateValue], @"B");
}

- (void)testEmptyGroupKeysProduceAnEmptyClause {
	MADDataTableFast *table = [self fastTable];

	XCTAssertEqualObjects([table whereClauseForGroupKeys:@[]], @[]);
}

- (void)testFewerSortDescriptorsThanGroupKeysClipsToTheDescriptors {
	// docs/project/BUGS.md: the loop used to index sortDescriptors by the group-key index and walk
	// off the end of the array.  A group key whose position has no descriptor cannot
	// be named, so its pair is left out (and logged) rather than raised.
	MADDataTableFast *table = [self fastTable];
	table.columnKeys = [@[@"a"] mutableCopy];
	table.sortDescriptors = [@[[NSSortDescriptor sortDescriptorWithKey:@"a" ascending:YES]] mutableCopy];

	NSArray<NSDictionary *> *clause = [table whereClauseForGroupKeys:@[@"A", @"B"]];

	XCTAssertEqual(clause.count, (NSUInteger)1);
	XCTAssertEqualObjects(clause[0][MADQueryKeyPredicateColumn], @"a");
	XCTAssertEqualObjects(clause[0][MADQueryKeyPredicateValue], @"A");
}

#pragma mark - Read transactions

- (void)testReadTransactionsWithoutASelectsDatabaseAreANoOp {
	// docs/project/BUGS.md: a delegate-less table has no selects database at all.  The pair used to
	// read self.databaseForSelects->_database and crash on the nil object before its
	// handle guard could run; with nothing to begin or commit, the calls are no-ops.
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:123 fromCache:YES];

	XCTAssertNil(table.databaseForSelects);
	XCTAssertNoThrow([table beginReadTransaction]);
	XCTAssertNoThrow([table commitReadTransaction]);
}

- (void)testReadTransactionsOnADirectoryBackedTable {
	MADDataTableFast *table = [self fastTable];

	XCTAssertNoThrow([table beginReadTransaction]);
	XCTAssertNoThrow([table commitReadTransaction]);
}

#pragma mark - runSelectQuery:

- (void)testRunSelectQueryReturnsTheFirstColumnsValue {
	MADDataTableFast *table = [self fastTable];
	MADFlatSelectQuery *query = [[MADFlatSelectQuery alloc] initWithObject:nil];
	query.sql = @"SELECT 255 AS f1";
	query.binaryBindings = [NSMutableArray array];

	NSObject *result = [table runSelectQuery:query];

	XCTAssertTrue([result isKindOfClass:[NSNumber class]]);
	XCTAssertEqualObjects(result, @255);
}

- (void)testRunSelectQueryYieldsNilWhenTheQueryHasNoRow {
	// The nullable return the header now admits: a query that steps to no row answers
	// nil, not an error object and not a crash.
	MADDataTableFast *table = [self fastTable];
	MADFlatSelectQuery *query = [[MADFlatSelectQuery alloc] initWithObject:nil];
	query.sql = @"SELECT 1 FROM (SELECT 1) WHERE 0";
	query.binaryBindings = [NSMutableArray array];

	XCTAssertNil([table runSelectQuery:query]);
}

#pragma mark - ORDER BY generation

// The report formatter finds group boundaries by comparing adjacent rows, so the
// cache's ORDER BY has to order a key the way the formatter compares it: text keys
// under the LSASC collation (the defined order, NSString+Comparison.h), everything
// else plainly.  See docs/project/BUGS.md, "The cache's ORDER BY ignores column types".

- (void)testSelectLimitOffsetWithoutColumnsOrdersPlainly {
	// The constructor cannot consult a column it was not handed; it must fall
	// back to a plain order rather than guess a collation.
	NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"c123" ascending:YES];
	MADQueryCacheSelectLimitOffset *query = [[MADQueryCacheSelectLimitOffset alloc] initWithColumnKeys:@[@"c123"]
																							   tableName:@"t"
																						 sortDescriptors:@[descriptor]
																								   limit:NSNotFound
																								  offset:NSNotFound
																							  dropRowID:NO
																								columns:nil];
	NSString *sql = [query getSql:nil];
	XCTAssertTrue([sql containsString:@"ORDER BY c123 ASC"], @"%@", sql);
	XCTAssertFalse([sql containsString:@"COLLATE"], @"%@", sql);
}

- (void)testSelectLimitOffsetWithATextColumnOrdersWithLSASC {
	MADDataColumn *column = [MADDataColumn newDataColumnWithIdentifier:@"c123"];
	column.type = MADDataTypeString;
	NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"c123" ascending:YES];
	MADQueryCacheSelectLimitOffset *query = [[MADQueryCacheSelectLimitOffset alloc] initWithColumnKeys:@[@"c123"]
																							   tableName:@"t"
																						 sortDescriptors:@[descriptor]
																								   limit:NSNotFound
																								  offset:NSNotFound
																							  dropRowID:NO
																								columns:@{@"c123": column}];
	NSString *sql = [query getSql:nil];
	XCTAssertTrue([sql containsString:@"ORDER BY c123 COLLATE LSASC ASC"], @"%@", sql);
}

- (void)testSelectLimitOffsetWithANumericColumnOrdersPlainly {
	MADDataColumn *column = [MADDataColumn newDataColumnWithIdentifier:@"c123"];
	column.type = MADDataTypeInteger;
	NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"c123" ascending:YES];
	MADQueryCacheSelectLimitOffset *query = [[MADQueryCacheSelectLimitOffset alloc] initWithColumnKeys:@[@"c123"]
																							   tableName:@"t"
																						 sortDescriptors:@[descriptor]
																								   limit:NSNotFound
																								  offset:NSNotFound
																							  dropRowID:NO
																								columns:@{@"c123": column}];
	NSString *sql = [query getSql:nil];
	XCTAssertTrue([sql containsString:@"ORDER BY c123 ASC"], @"%@", sql);
	XCTAssertFalse([sql containsString:@"COLLATE"], @"%@", sql);
}

#pragma mark - Sorted enumerator

// One column, rows added out of order, read back through the enumerator the
// report formatter walks.  The order the enumerator yields is what group
// boundaries are detected against.

- (NSArray <NSString *> *)enumeratedValuesForColumnType:(MADDataType)type values:(NSArray <id> *)values {
	MADDataTableFast *table = [self fastTable];
	MADDataColumn *column = [MADDataColumn newDataColumnWithIdentifier:@"field"];
	column.fieldName = column.identifier;
	column.type = type;
	[table addColumn:column];
	for (id value in values) {
		[table addRowWithDataForFieldKeys:@{@"field": value}];
	}
	[table sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"field" ascending:YES]]];

	NSMutableArray *ordered = [[NSMutableArray alloc] init];
	for (NSDictionary *row in [table enumeratorForKeyObjectsSorted]) {
		[ordered addObject:row[@"field"]];
	}
	return ordered;
}

- (void)testEnumeratorOrdersNumericKeysNumerically {
	NSArray *values = [self enumeratedValuesForColumnType:MADDataTypeInteger values:@[@10, @1, @2]];
	XCTAssertEqualObjects(values, (@[@1, @2, @10]));
}

- (void)testEnumeratorOrdersTextKeysCaseInsensitively {
	// "Apple" and "apple" are one key under LSASC, so the two case variants must
	// be adjacent and "Armadillo" last; their relative order is unspecified.
	NSArray *values = [self enumeratedValuesForColumnType:MADDataTypeString values:@[@"Apple", @"Armadillo", @"apple"]];
	XCTAssertEqual(values.count, (NSUInteger)3);
	XCTAssertEqualObjects(values[2], @"Armadillo");
	XCTAssertEqual([values[0] caseInsensitiveCompare:@"apple"], NSOrderedSame, @"%@", values[0]);
	XCTAssertEqual([values[1] caseInsensitiveCompare:@"apple"], NSOrderedSame, @"%@", values[1]);
}

@end
