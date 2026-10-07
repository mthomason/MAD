//
//  MADDataTableFastSelectTests.m
//  MADSqlite3Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the MADDataTableFast surface the existing suites do not reach: the
//  group-key WHERE clause, the read-transaction pair, and -runSelectQuery: (the
//  column-0 select behind the per-page reads).  Everything runs on a real fast table
//  whose cache directory is a per-test temp directory, so the selects connection is a
//  real sqlite3 handle without touching the application's cache.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataTable.h>
#import <MADAPI/MADQuery.h>

#import "MADDataTableFast.h"
#import "MADDatabaseSqlite3.h"

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

- (void)testFewerSortDescriptorsThanGroupKeysRaises {
	// BUGS.md: the loop indexes sortDescriptors by the group-key index, so one sort
	// descriptor with two group keys walks off the end of the array.
	MADDataTableFast *table = [self fastTable];
	table.columnKeys = [@[@"a"] mutableCopy];
	table.sortDescriptors = [@[[NSSortDescriptor sortDescriptorWithKey:@"a" ascending:YES]] mutableCopy];

	XCTAssertThrows(([table whereClauseForGroupKeys:@[@"A", @"B"]]));
}

#pragma mark - Read transactions

- (void)testReadTransactionsWithoutASelectsDatabaseAreNotSafe {
	// BUGS.md: a delegate-less table has no selects database at all.  The pair guards
	// on the *handle* being NULL (self.databaseForSelects->_database), so with a nil
	// database the ivar read crashes before the guard can run -- this was found by a
	// test that made exactly this call.  Only the precondition is pinned here.
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:123 fromCache:YES];

	XCTAssertNil(table.databaseForSelects);
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

@end
