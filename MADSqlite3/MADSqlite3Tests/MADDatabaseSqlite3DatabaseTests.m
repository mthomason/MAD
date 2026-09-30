//
//  MADDatabaseSqlite3DatabaseTests.m
//  MADSqlite3Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Stateful coverage for the MADSqlite3 framework that exercises a real on-disk
//  sqlite3 database:
//    * MADDatabaseSqlite3 open/connection lifecycle (databaseHandle, tableExist:,
//      safe identifiers, identifier).
//    * MADArrayCaching end-to-end (initialize, add, read, remove).
//

#import <XCTest/XCTest.h>

#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADSqlite3/MADArrayCaching.h>
#import <MADSqlite3/MADDataTableFast.h>
#import "MADDataTableObjectEnumerator.h"
#import "MADDataTableSingleColumnEnumerator.h"

#import <MADFoundation/MADCacheProtocol.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADAPI/MADQuery.h>

#import "sqlite3.h"

// Minimal MADCacheProtocol implementation that points MADArrayCaching at a
// caller-supplied directory.
@interface MADArrayCachingDirectoryDouble : NSObject <MADCacheProtocol>
@property (nonatomic, strong) NSURL *directory;
@end

@implementation MADArrayCachingDirectoryDouble
- (NSURL *)cachedFilesDirectory {
	return self.directory;
}
@end

// MADQuery subclass that returns a caller-supplied SQL string.  Lets the
// enumerator tests exercise the enumerators independent of any query builder.
@interface MADFixedSqlQuery : MADQuery
@property (nonatomic, copy) NSString *sql;
@end

@implementation MADFixedSqlQuery
- (NSString *)getSql:(NSError * __autoreleasing *)error {
	return self.sql;
}
@end

@interface MADDatabaseSqlite3DatabaseTests : XCTestCase
@property (nonatomic, strong) NSURL *tempDirectory;
@property (nonatomic, strong) NSURL *databaseURL;
@end

@implementation MADDatabaseSqlite3DatabaseTests

- (void)setUp {
	[super setUp];
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	self.tempDirectory = [NSURL fileURLWithPath:path isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:self.tempDirectory
							  withIntermediateDirectories:YES
											   attributes:nil
													error:nil];
	self.databaseURL = [self.tempDirectory URLByAppendingPathComponent:@"test.sqlite"];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:self.tempDirectory error:nil];
	self.tempDirectory = nil;
	self.databaseURL = nil;
	[super tearDown];
}

- (MADDatabaseSqlite3 *)makeOpenDatabase {
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:self.databaseURL];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	database.databaseConnection = connection;
	[database openDatabase];
	return database;
}

#pragma mark - MADDatabaseSqlite3 connection lifecycle

- (void)testDatabaseHandleNilBeforeOpen {
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	XCTAssertEqual([database databaseHandle], NULL);
}

- (void)testOpenDatabaseCreatesHandleAndFile {
	MADDatabaseSqlite3 *database = [self makeOpenDatabase];
	XCTAssertNotEqual([database databaseHandle], NULL);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:self.databaseURL.path]);
}

- (void)testOpenDatabaseWithFlags {
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:self.databaseURL];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	database.databaseConnection = connection;
	[database openDatabaseWithFlags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_SHAREDCACHE | SQLITE_OPEN_FULLMUTEX];
	XCTAssertNotEqual([database databaseHandle], NULL);
}

- (void)testIdentifier {
	MADDatabaseSqlite3 *database = [self makeOpenDatabase];
	XCTAssertEqualObjects([database identifier], @"Sqlite 3");
}

- (void)testTableExist {
	MADDatabaseSqlite3 *database = [self makeOpenDatabase];
	XCTAssertFalse([database tableExist:@"missing_table"]);

	sqlite3 *handle = (sqlite3 *)database.databaseHandle;
	XCTAssertEqual(sqlite3_exec(handle, "CREATE TABLE present_table (id INTEGER);", NULL, NULL, NULL), SQLITE_OK);
	XCTAssertTrue([database tableExist:@"present_table"]);
}

- (void)testInstanceSafeIdentifiers {
	MADDatabaseSqlite3 *database = [self makeOpenDatabase];
	XCTAssertEqualObjects([database newSafeIdentifier:@"name"], @"\"name\"");
	XCTAssertEqualObjects([database queryKey:@"field" table:@"tbl"], @"\"tbl\".\"field\"");
}

#pragma mark - MADArrayCaching lifecycle

- (MADArrayCaching *)makeArrayCaching {
	MADArrayCachingDirectoryDouble *delegate = [[MADArrayCachingDirectoryDouble alloc] init];
	delegate.directory = self.tempDirectory;
	NSSet *types = [NSSet setWithObject:[NSString class]];
	MADArrayCaching *cache = [[MADArrayCaching alloc] initWithIdentifier:@"testCache"
														cachedDelegate:delegate
																  types:types];
	[cache initializeDatabase];
	return cache;
}

- (void)testArrayCachingLifecycle {
	MADArrayCaching *cache = [self makeArrayCaching];
	XCTAssertEqual(cache.state, MADArrayCachingStateEmpty);

	[cache addObject:@"alpha"];
	[cache addObject:@"bravo"];

	XCTAssertEqual([cache count], 2);
	XCTAssertEqualObjects([cache objectAtIndex:0], @"alpha");
	XCTAssertEqualObjects([cache objectAtIndex:1], @"bravo");

	[cache finalizeDatabase];
}

- (void)testArrayCachingObjectAtIndexedSubscript {
	MADArrayCaching *cache = [self makeArrayCaching];
	[cache addObject:@"gamma"];
	XCTAssertEqualObjects(cache[0], @"gamma");
	[cache finalizeDatabase];
}

- (void)testArrayCachingOutOfRangeReturnsNil {
	MADArrayCaching *cache = [self makeArrayCaching];
	[cache addObject:@"delta"];
	XCTAssertNil([cache objectAtIndex:5]);
	[cache finalizeDatabase];
}

- (void)testArrayCachingRemoveAllObjects {
	MADArrayCaching *cache = [self makeArrayCaching];
	[cache addObject:@"epsilon"];
	[cache addObject:@"zeta"];

	XCTAssertTrue([cache removeAllObjects]);
	XCTAssertNil([cache objectAtIndex:0]);

	[cache finalizeDatabase];
}

#pragma mark - Enumerators

- (MADDataColumn *)makeColumnWithIdentifier:(NSString *)identifier type:(MADDataType)type {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:identifier];
	column.fieldName = identifier;
	column.type = type;
	return column;
}

- (void)createPeopleTable {
	sqlite3 *db = NULL;
	sqlite3_open(self.databaseURL.path.UTF8String, &db);
	sqlite3_exec(db, "CREATE TABLE people (name TEXT, age INTEGER);", NULL, NULL, NULL);
	sqlite3_exec(db, "INSERT INTO people (name, age) VALUES ('alice', 30);", NULL, NULL, NULL);
	sqlite3_exec(db, "INSERT INTO people (name, age) VALUES ('bob', 25);", NULL, NULL, NULL);
	sqlite3_close(db);
}

- (void)testDataTableObjectEnumerator {
	[self createPeopleTable];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:self.databaseURL];

	MADFixedSqlQuery *query = [[MADFixedSqlQuery alloc] init];
	query.sql = @"SELECT name, age, ROWID FROM people ORDER BY rowid";

	NSDictionary *columns = @{
		@"name": [self makeColumnWithIdentifier:@"name" type:MADDataTypeString],
		@"age": [self makeColumnWithIdentifier:@"age" type:MADDataTypeInteger],
	};
	NSArray *columnKeys = @[@"name", @"age"];

	MADDataTableObjectEnumerator *enumerator = [[MADDataTableObjectEnumerator alloc]
		initWithDatabaseConnection:connection columns:columns columnKeys:columnKeys query:query];

	NSArray *all = [enumerator allObjects];
	XCTAssertEqual(all.count, 2);
	XCTAssertEqualObjects(all[0][@"name"], @"alice");
	XCTAssertEqualObjects(all[0][@"age"], @30);
	XCTAssertEqualObjects(all[1][@"name"], @"bob");
	XCTAssertEqualObjects(all[1][@"age"], @25);
}

- (void)testDataTableSingleColumnEnumerator {
	[self createPeopleTable];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:self.databaseURL];

	MADFixedSqlQuery *query = [[MADFixedSqlQuery alloc] init];
	query.sql = @"SELECT name FROM people ORDER BY rowid";

	NSDictionary *columns = @{@"name": [self makeColumnWithIdentifier:@"name" type:MADDataTypeString]};
	NSArray *columnKeys = @[@"name"];

	MADDataTableSingleColumnEnumerator *enumerator = [[MADDataTableSingleColumnEnumerator alloc]
		initWithDatabaseConnection:connection columns:columns columnKeys:columnKeys query:query];

	NSArray *all = [enumerator allObjects];
	XCTAssertEqual(all.count, 2);
	XCTAssertEqualObjects(all[0], @"alice");
	XCTAssertEqualObjects(all[1], @"bob");
}

#pragma mark - MADDataTableFast

- (void)testDataTableFastTableName {
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:123 fromCache:YES];
	XCTAssertEqualObjects([table tableName], @"t123");
}

- (void)testDataTableFastRoundTrip {
	MADArrayCachingDirectoryDouble *delegate = [[MADArrayCachingDirectoryDouble alloc] init];
	delegate.directory = self.tempDirectory;

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	table.cacheDelegate = delegate;

	[table addColumn:[self makeColumnWithIdentifier:@"name" type:MADDataTypeString]];
	[table addColumn:[self makeColumnWithIdentifier:@"age" type:MADDataTypeInteger]];

	[table addRowWithDataForFieldKeys:@{@"name": @"alice", @"age": @30}];
	[table addRowWithDataForFieldKeys:@{@"name": @"bob", @"age": @25}];

	XCTAssertEqual([table numberOfRows], 2);

	NSDictionary *row0 = [table objectAtRow:0];
	XCTAssertEqualObjects(row0[@"name"], @"alice");
	XCTAssertEqualObjects(row0[@"age"], @30);

	NSDictionary *row1 = [table objectAtRow:1];
	XCTAssertEqualObjects(row1[@"name"], @"bob");
	XCTAssertEqualObjects(row1[@"age"], @25);

	XCTAssertNotNil([table columnKeyForColumnName:@"name"]);
}

@end
