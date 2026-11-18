//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDataTableFastSelectTests.m
//  Linux/Tests
//
//  Ported from MADSqlite3Tests/MADDataTableFastSelectTests.m: the MADDataTableFast
//  surface the existing suites do not reach -- the group-key WHERE clause, the
//  read-transaction pair, and -runSelectQuery: (the column-0 select behind the
//  per-page reads).  Everything runs on a real fast table whose cache directory is
//  a per-test temp directory, so the selects connection is a real sqlite3 handle
//  without touching the application's cache.
//
//  The XCTest setUp/tearDown pair is per-test fixture helpers here.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataTable.h>
#import <MADAPI/MADQuery.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADQueryCacheSelectLimitOffset.h>

#pragma mark - Test query

// The smallest query -runSelectQuery: accepts: fixed SQL, no bindings.
@interface MADFlatSelectQuery : MADQuery <MADQueryDataBindingProtocol>
@property (nonatomic, strong) NSMutableArray *binaryBindings;
@property (nonatomic, copy) NSString *sql;
@end

@implementation MADFlatSelectQuery
@synthesize binaryBindings = _binaryBindings;
@synthesize sql = _sql;

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	(void)error;
	return self.sql;
}
@end

#pragma mark - Fixture

static NSURL *MADSelectMakeTempDirectory(void) {
	NSURL *directory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]
								  isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory
							 withIntermediateDirectories:YES attributes:nil error:NULL];
	return directory;
}

static void MADSelectRemoveTempDirectory(NSURL *directory) {
	[[NSFileManager defaultManager] removeItemAtURL:directory error:NULL];
}

static MADDataTableFast *MADSelectFastTable(NSURL *directory) {
	return [[MADDataTableFast alloc] initWithId:7 cacheDirectory:directory];
}

#pragma mark - Group-key WHERE clause

static void testGroupKeysProducePositionalColumnValuePairs(void) {
	NSURL *directory = MADSelectMakeTempDirectory();
	MADDataTableFast *table = MADSelectFastTable(directory);
	table.columnKeys = [@[@"a", @"b"] mutableCopy];
	table.sortDescriptors = [@[[NSSortDescriptor sortDescriptorWithKey:@"a" ascending:YES],
							   [NSSortDescriptor sortDescriptorWithKey:@"b" ascending:YES]] mutableCopy];

	NSArray *groupKeys = @[@"A", @"B"];
	NSArray<NSDictionary *> *clause = [table whereClauseForGroupKeys:groupKeys];

	MAD_PASS(clause.count == (NSUInteger)2, "one clause entry per group key");
	// Each entry pairs the sort descriptor's key with the group key at the same index.
	MAD_PASS_EQUAL(clause[0][MADQueryKeyPredicateColumn], @"a", "the first column");
	MAD_PASS_EQUAL(clause[0][MADQueryKeyPredicateValue], @"A", "the first value");
	MAD_PASS_EQUAL(clause[1][MADQueryKeyPredicateColumn], @"b", "the second column");
	MAD_PASS_EQUAL(clause[1][MADQueryKeyPredicateValue], @"B", "the second value");

	MADSelectRemoveTempDirectory(directory);
}

static void testEmptyGroupKeysProduceAnEmptyClause(void) {
	NSURL *directory = MADSelectMakeTempDirectory();
	MADDataTableFast *table = MADSelectFastTable(directory);

	MAD_PASS_EQUAL([table whereClauseForGroupKeys:@[]], @[], "an empty group-key list gives an empty clause");

	MADSelectRemoveTempDirectory(directory);
}

static void testFewerSortDescriptorsThanGroupKeysClipsToTheDescriptors(void) {
	// docs/project/BUGS.md: the loop used to index sortDescriptors by the group-key index and walk
	// off the end of the array.  A group key whose position has no descriptor cannot
	// be named, so its pair is left out (and logged) rather than raised.
	NSURL *directory = MADSelectMakeTempDirectory();
	MADDataTableFast *table = MADSelectFastTable(directory);
	table.columnKeys = [@[@"a"] mutableCopy];
	table.sortDescriptors = [@[[NSSortDescriptor sortDescriptorWithKey:@"a" ascending:YES]] mutableCopy];

	NSArray *groupKeys = @[@"A", @"B"];
	NSArray<NSDictionary *> *clause = [table whereClauseForGroupKeys:groupKeys];

	MAD_PASS(clause.count == (NSUInteger)1, "only the pair the descriptor can name is built");
	MAD_PASS_EQUAL(clause[0][MADQueryKeyPredicateColumn], @"a", "the named column");
	MAD_PASS_EQUAL(clause[0][MADQueryKeyPredicateValue], @"A", "the paired value");

	MADSelectRemoveTempDirectory(directory);
}

#pragma mark - Read transactions

static void testReadTransactionsWithoutASelectsDatabaseAreANoOp(void) {
	// docs/project/BUGS.md: a delegate-less table has no selects database at all.  The pair used to
	// read self.databaseForSelects->_database and crash on the nil object before its
	// handle guard could run; with nothing to begin or commit, the calls are no-ops.
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:123 fromCache:YES];
	MAD_PASS(table != nil, "the table exists");

	MAD_PASS(table.databaseForSelects == nil, "a delegate-less table has no selects database");
	MAD_NO_THROW([table beginReadTransaction], "beginning with no selects database is a no-op");
	MAD_NO_THROW([table commitReadTransaction], "committing with no selects database is a no-op");
}

static void testReadTransactionsOnADirectoryBackedTable(void) {
	NSURL *directory = MADSelectMakeTempDirectory();
	MADDataTableFast *table = MADSelectFastTable(directory);

	MAD_NO_THROW([table beginReadTransaction], "the read transaction begins");
	MAD_NO_THROW([table commitReadTransaction], "the read transaction commits");

	MADSelectRemoveTempDirectory(directory);
}

#pragma mark - runSelectQuery:

static void testRunSelectQueryReturnsTheFirstColumnsValue(void) {
	NSURL *directory = MADSelectMakeTempDirectory();
	MADDataTableFast *table = MADSelectFastTable(directory);
	MADFlatSelectQuery *query = [[MADFlatSelectQuery alloc] initWithObject:nil];
	query.sql = @"SELECT 255 AS f1";
	query.binaryBindings = [NSMutableArray array];

	NSObject *result = [table runSelectQuery:query];

	MAD_PASS([result isKindOfClass:[NSNumber class]], "the result is a number");
	MAD_PASS_EQUAL(result, @255, "the first column's value comes back");

	MADSelectRemoveTempDirectory(directory);
}

static void testRunSelectQueryYieldsNilWhenTheQueryHasNoRow(void) {
	// The nullable return the header now admits: a query that steps to no row answers
	// nil, not an error object and not a crash.
	NSURL *directory = MADSelectMakeTempDirectory();
	MADDataTableFast *table = MADSelectFastTable(directory);
	MADFlatSelectQuery *query = [[MADFlatSelectQuery alloc] initWithObject:nil];
	query.sql = @"SELECT 1 FROM (SELECT 1) WHERE 0";
	query.binaryBindings = [NSMutableArray array];

	MAD_PASS([table runSelectQuery:query] == nil, "a query with no row answers nil");

	MADSelectRemoveTempDirectory(directory);
}

#pragma mark - ORDER BY generation

// The report formatter finds group boundaries by comparing adjacent rows, so the
// cache's ORDER BY has to order a key the way the formatter compares it: text keys
// under the LSASC collation (the defined order, NSString+Comparison.h), everything
// else plainly.  See docs/project/BUGS.md, "The cache's ORDER BY ignores column types".

static void testSelectLimitOffsetWithoutColumnsOrdersPlainly(void) {
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
	MAD_PASS([sql containsString:@"ORDER BY c123 ASC"], "a column-less ORDER BY is plain ascending");
	MAD_PASS(![sql containsString:@"COLLATE"], "no collation is guessed");
}

static void testSelectLimitOffsetWithATextColumnOrdersWithLSASC(void) {
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
	MAD_PASS([sql containsString:@"ORDER BY c123 COLLATE LSASC ASC"], "a text column orders under LSASC");
}

static void testSelectLimitOffsetWithANumericColumnOrdersPlainly(void) {
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
	MAD_PASS([sql containsString:@"ORDER BY c123 ASC"], "a numeric column orders plainly");
	MAD_PASS(![sql containsString:@"COLLATE"], "no collation for numbers");
}

#pragma mark - Sorted enumerator

// One column, rows added out of order, read back through the enumerator the
// report formatter walks.  The order the enumerator yields is what group
// boundaries are detected against.

static NSArray *MADSelectEnumeratedValues(MADDataTableFast *table, NSString *key) {
	NSMutableArray *ordered = [[NSMutableArray alloc] init];
	NSEnumerator *enumerator = [table enumeratorForKeyObjectsSorted];
	for (NSDictionary *row in enumerator) {
		[ordered addObject:row[key]];
	}
	return ordered;
}

static NSArray *MADSelectValuesForColumnType(MADDataType type, NSArray *values) {
	NSURL *directory = MADSelectMakeTempDirectory();
	MADDataTableFast *table = MADSelectFastTable(directory);
	MADDataColumn *column = [MADDataColumn newDataColumnWithIdentifier:@"field"];
	column.fieldName = column.identifier;
	column.type = type;
	[table addColumn:column];
	for (id value in values) {
		[table addRowWithDataForFieldKeys:@{@"field": value}];
	}
	[table sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"field" ascending:YES]]];

	NSArray *ordered = MADSelectEnumeratedValues(table, @"field");
	MADSelectRemoveTempDirectory(directory);
	return ordered;
}

static void testEnumeratorOrdersNumericKeysNumerically(void) {
	NSArray *values = MADSelectValuesForColumnType(MADDataTypeInteger, @[@10, @1, @2]);
	MAD_PASS_EQUAL(values, (@[@1, @2, @10]), "numbers order numerically");
}

static void testEnumeratorOrdersTextKeysCaseInsensitively(void) {
	// "Apple" and "apple" are one key under LSASC on both platforms now: the
	// collation folds case (the defined order, NSString+Comparison.h), so the
	// case variants stay adjacent -- insertion order among equal keys -- and
	// the folded-greater key sorts last.
	NSArray *values = MADSelectValuesForColumnType(MADDataTypeString, @[@"Apple", @"Armadillo", @"apple"]);
	MAD_PASS(values.count == (NSUInteger)3, "all three rows come back");
	MAD_PASS_EQUAL(values[2], @"Armadillo", "the case-insensitively greater key sorts last");
	MAD_PASS([values[0] caseInsensitiveCompare:@"apple"] == NSOrderedSame, "a case variant of apple sorts first");
	MAD_PASS([values[1] caseInsensitiveCompare:@"apple"] == NSOrderedSame, "the other case variant is adjacent to it");
}

MAD_TEST_MAIN("MADDataTableFastSelectTests",
	MAD_TEST(testGroupKeysProducePositionalColumnValuePairs),
	MAD_TEST(testEmptyGroupKeysProduceAnEmptyClause),
	MAD_TEST(testFewerSortDescriptorsThanGroupKeysClipsToTheDescriptors),
	MAD_TEST(testReadTransactionsWithoutASelectsDatabaseAreANoOp),
	MAD_TEST(testReadTransactionsOnADirectoryBackedTable),
	MAD_TEST(testRunSelectQueryReturnsTheFirstColumnsValue),
	MAD_TEST(testRunSelectQueryYieldsNilWhenTheQueryHasNoRow),
	MAD_TEST(testSelectLimitOffsetWithoutColumnsOrdersPlainly),
	MAD_TEST(testSelectLimitOffsetWithATextColumnOrdersWithLSASC),
	MAD_TEST(testSelectLimitOffsetWithANumericColumnOrdersPlainly),
	MAD_TEST(testEnumeratorOrdersNumericKeysNumerically),
	MAD_TEST(testEnumeratorOrdersTextKeysCaseInsensitively));
