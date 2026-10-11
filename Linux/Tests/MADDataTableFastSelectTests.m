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

#import <MADFoundation/MADDataTable.h>
#import <MADAPI/MADQuery.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>

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

static void testFewerSortDescriptorsThanGroupKeysRaises(void) {
	// BUGS.md: the loop indexes sortDescriptors by the group-key index, so one sort
	// descriptor with two group keys walks off the end of the array.
	NSURL *directory = MADSelectMakeTempDirectory();
	MADDataTableFast *table = MADSelectFastTable(directory);
	table.columnKeys = [@[@"a"] mutableCopy];
	table.sortDescriptors = [@[[NSSortDescriptor sortDescriptorWithKey:@"a" ascending:YES]] mutableCopy];

	NSArray *groupKeys = @[@"A", @"B"];
	MAD_THROWS_NAMED([table whereClauseForGroupKeys:groupKeys], NSRangeException, "the over-index raises");

	MADSelectRemoveTempDirectory(directory);
}

#pragma mark - Read transactions

static void testReadTransactionsWithoutASelectsDatabaseAreNotSafe(void) {
	// BUGS.md: a delegate-less table has no selects database at all.  The pair guards
	// on the *handle* being NULL (self.databaseForSelects->_database), so with a nil
	// database the ivar read crashes before the guard can run -- this was found by a
	// test that made exactly this call.  Only the precondition is pinned here.
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:123 fromCache:YES];
	MAD_PASS(table != nil, "the table exists");

	MAD_PASS(table.databaseForSelects == nil, "a delegate-less table has no selects database");
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

MAD_TEST_MAIN("MADDataTableFastSelectTests",
	MAD_TEST(testGroupKeysProducePositionalColumnValuePairs),
	MAD_TEST(testEmptyGroupKeysProduceAnEmptyClause),
	MAD_TEST(testFewerSortDescriptorsThanGroupKeysRaises),
	MAD_TEST(testReadTransactionsWithoutASelectsDatabaseAreNotSafe),
	MAD_TEST(testReadTransactionsOnADirectoryBackedTable),
	MAD_TEST(testRunSelectQueryReturnsTheFirstColumnsValue));
