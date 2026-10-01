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
//    * The write port: a bare <MADDataTableWriting> conformer with no MADDataTable
//      behind it, filled by the driver's row loop.
//

#import <XCTest/XCTest.h>

#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADSqlite3/MADArrayCaching.h>
#import <MADSqlite3/MADDataTableFast.h>
#import "MADDataTableObjectEnumerator.h"
#import "MADDataTableSingleColumnEnumerator.h"

#import <MADFoundation/MADCacheProtocol.h>
#import <MADFoundation/MADDataTable.h>
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

#pragma mark - The write port alone

// Conforms to <MADDataTableWriting> and to nothing else: not a MADDataTable, so no
// concrete MADDataTableFast behind it, and no cache delegate, so no .maddb file and
// no [MADApplication AppDelegate].  Handing one of these to the driver is what proves
// the driver is decoupled from the table class -- before Phase 1 it asked for a
// MADDataTable, and with it everything above.
@interface MADWritePortRecorder : NSObject <MADDataTableWriting>

@property (nonatomic, strong) NSMutableArray <NSString *> *columnKeys;
@property (nonatomic, strong) NSMutableDictionary <NSString *, MADDataColumn *> *columns;
/// The rows the driver handed over, in the order it handed them over.
@property (nonatomic, strong) NSMutableArray <NSDictionary <NSString *, id> *> *rows;
/// Every port call, in order, so the call sequence itself can be asserted.
@property (nonatomic, strong) NSMutableArray <NSString *> *callLog;
@property (nonatomic, assign) NSUInteger beginBulkInsertCount;
@property (nonatomic, assign) NSUInteger endBulkInsertCount;

@end

@implementation MADWritePortRecorder

- (instancetype)init {
	if (self = [super init]) {
		_columnKeys = [[NSMutableArray alloc] init];
		_columns = [[NSMutableDictionary alloc] init];
		_rows = [[NSMutableArray alloc] init];
		_callLog = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)removeAllObjects {
	[self.callLog addObject:@"removeAllObjects"];
	[self.columnKeys removeAllObjects];
	[self.columns removeAllObjects];
	[self.rows removeAllObjects];
}

- (void)addColumn:(MADDataColumn *)column {
	[self.callLog addObject:@"addColumn:"];
	self.columns[column.fieldName] = column;
	[self.columnKeys addObject:column.fieldName];
}

- (bool)addRow:(NSArray *)row error:(NSError * __autoreleasing *)error {
	[self.callLog addObject:@"addRow:error:"];
	return true;
}

- (void)addRowWithDataForFieldKeys:(NSDictionary<NSString *, id> *)row {
	[self.callLog addObject:@"addRowWithDataForFieldKeys:"];
	[self.rows addObject:row];
}

- (void)sortUsingDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors {
	[self.callLog addObject:@"sortUsingDescriptors:"];
}

- (void)beginBulkInsert {
	self.beginBulkInsertCount++;
	[self.callLog addObject:@"beginBulkInsert"];
}

- (void)endBulkInsert {
	self.endBulkInsertCount++;
	[self.callLog addObject:@"endBulkInsert"];
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

// An empty cache must report zero and empty; -isEmpty was inverted (returned YES
// when there were rows) and -count read a garbage value off a done statement.
- (void)testArrayCachingIsEmptyAndCountForEmpty {
	MADArrayCaching *cache = [self makeArrayCaching];

	XCTAssertTrue([cache isEmpty], @"a fresh cache is empty");
	XCTAssertEqual([cache count], (NSUInteger)0);

	[cache addObject:@"alpha"];
	XCTAssertFalse([cache isEmpty], @"a cache with a row is not empty");
	XCTAssertEqual([cache count], (NSUInteger)1);

	[cache addObject:@"bravo"];
	XCTAssertEqual([cache count], (NSUInteger)2);

	XCTAssertTrue([cache removeAllObjects]);
	XCTAssertTrue([cache isEmpty]);
	XCTAssertEqual([cache count], (NSUInteger)0);

	[cache finalizeDatabase];
}

// The render cache is read repeatedly; a repeated read must return the cached object
// rather than unarchive a fresh copy each time, and the object must round-trip.
- (void)testArrayCachingRepeatedReadsReturnTheCachedObject {
	MADArrayCaching *cache = [self makeArrayCaching];
	[cache addObject:@"alpha"];
	[cache addObject:@"bravo"];

	XCTAssertEqualObjects([cache objectAtIndex:1], @"bravo");
	XCTAssertEqualObjects([cache objectAtIndex:0], @"alpha");
	XCTAssertEqualObjects([cache objectAtIndex:1], @"bravo");
	XCTAssertEqual([cache objectAtIndex:1], [cache objectAtIndex:1],
				   @"a repeated read returns the same cached instance");

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

#pragma mark - Literal quoting

// A text filter used to be written as "London" -- a double-quoted token, which SQLite reads
// as a *column* name.  That survived only because SQLITE_DQS defaults to on;
// Compressor/sqlite3.xcconfig pins it to 0, and the London sample then failed to refresh
// with "no such column: London".  This puts a value containing a quote through a real query
// in the build that ships, so a literal that is bare or double-quoted fails here instead of
// in the app: either way the statement does not prepare and no row comes back.
- (void)testNewSafeLiteralProducesAValueSQLiteWillRead {
	sqlite3 *ddl = NULL;
	sqlite3_open(self.databaseURL.path.UTF8String, &ddl);
	sqlite3_exec(ddl, "CREATE TABLE people (name TEXT, age INTEGER);", NULL, NULL, NULL);
	sqlite3_exec(ddl, "INSERT INTO people (name, age) VALUES ('O''Brien', 41);", NULL, NULL, NULL);
	sqlite3_close(ddl);

	MADDatabaseSqlite3 *database = [self makeOpenDatabase];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:self.databaseURL];

	MADFixedSqlQuery *query = [[MADFixedSqlQuery alloc] init];
	query.sql = [NSString stringWithFormat:@"SELECT name, age FROM people WHERE name = %@ ORDER BY rowid",
				 [database newSafeLiteral:@"O'Brien"]];

	MADDataTableObjectEnumerator *enumerator = [[MADDataTableObjectEnumerator alloc]
		initWithDatabaseConnection:connection
						   columns:@{@"name": [self makeColumnWithIdentifier:@"name" type:MADDataTypeString],
									 @"age": [self makeColumnWithIdentifier:@"age" type:MADDataTypeInteger]}
						columnKeys:@[@"name", @"age"]
							 query:query];

	NSArray *all = [enumerator allObjects];
	XCTAssertEqual(all.count, (NSUInteger)1, @"the literal did not select the row it names: %@", query.sql);
	XCTAssertEqualObjects(all[0][@"name"], @"O'Brien");
	XCTAssertEqualObjects(all[0][@"age"], @41);
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

// The cache plist stores urls.urlFastCache as an absolute URL, so it names the
// application's data container and not just the file.  A container does not survive a
// reinstall, and the stored path then points into a directory that is gone.  Opening it
// fails -- SQLITE_OPEN_CREATE cannot create a file where the directory does not exist --
// and -openDatabaseWithFlags: asserts, which took the whole app down on the first
// document tap.  A stale URL has to be discarded and recomputed for the container in use.
- (void)testLoadWithPlistDiscardsACacheUrlWhoseDirectoryIsGone {
	MADArrayCachingDirectoryDouble *delegate = [[MADArrayCachingDirectoryDouble alloc] init];
	delegate.directory = self.tempDirectory;

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	table.cacheDelegate = delegate;

	NSMutableDictionary *plist = [[table copyPlist] mutableCopy];
	// The directory this names is deliberately never created, which is what a container
	// that has been replaced looks like from the file system's side.
	NSString *gone = [self.tempDirectory.path stringByAppendingPathComponent:@"gone/gone.maddb"];
	plist[@"urlFastCache"] = [[NSURL fileURLWithPath: gone] absoluteString];

	MADDataTableFast *reloaded = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	reloaded.cacheDelegate = delegate;
	NSError *error = nil;
	XCTAssertTrue([reloaded loadWithPlist: plist error: &error], @"load failed: %@", error);

	// -urlFastCache is private to the implementation, so reach it the way any other
	// reader outside MADDataTableFast would have to.
	NSURL *resolved = [reloaded valueForKey: @"urlFastCache"];
	NSURL *expected = [self.tempDirectory URLByAppendingPathComponent:@"7.maddb" isDirectory:NO];
	XCTAssertEqualObjects(resolved.path, expected.path,
						  @"the reload kept a cache url whose directory does not exist");
}

- (void)testLoadWithPlistKeepsACacheUrlWhoseDirectoryIsPresent {
	MADArrayCachingDirectoryDouble *delegate = [[MADArrayCachingDirectoryDouble alloc] init];
	delegate.directory = self.tempDirectory;

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	table.cacheDelegate = delegate;

	NSMutableDictionary *plist = [[table copyPlist] mutableCopy];
	NSURL *live = [self.tempDirectory URLByAppendingPathComponent:@"7.maddb" isDirectory:NO];
	plist[@"urlFastCache"] = live.absoluteString;

	MADDataTableFast *reloaded = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	reloaded.cacheDelegate = delegate;
	NSError *error = nil;
	XCTAssertTrue([reloaded loadWithPlist: plist error: &error], @"load failed: %@", error);

	NSURL *resolved = [reloaded valueForKey: @"urlFastCache"];
	XCTAssertEqualObjects(resolved.path, live.path);
}

// Reading a stale absolute URL is safe now, but writing one is how the staleness got
// in: the path names the data container, and the container does not survive a
// reinstall.  What is written is the file name alone.
- (void)testCopyPlistStoresTheCacheFileNameNotAnAbsoluteUrl {
	MADArrayCachingDirectoryDouble *delegate = [[MADArrayCachingDirectoryDouble alloc] init];
	delegate.directory = self.tempDirectory;

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	table.cacheDelegate = delegate;

	NSString *stored = [table copyPlist][@"urlFastCache"];
	XCTAssertEqualObjects(stored, @"7.maddb",
						  @"the plist stored a path, which names the container as well as the file");
	XCTAssertFalse([stored containsString: @"/"], @"a container path was written: %@", stored);
	XCTAssertNil([NSURL URLWithString: stored].scheme, @"the stored value still parses as an absolute URL");
}

// The format fix in one test: a plist written against one cache directory resolves
// against the directory in use when it is read, so the cache survives the container
// that wrote it -- which is what an absolute URL could not do.
- (void)testLoadWithPlistResolvesAStoredFileNameInTheDirectoryInUseNow {
	NSURL *otherDirectory = [self.tempDirectory URLByAppendingPathComponent:@"other" isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL: otherDirectory
							 withIntermediateDirectories: YES
											  attributes: nil
												   error: NULL];

	MADArrayCachingDirectoryDouble *wrote = [[MADArrayCachingDirectoryDouble alloc] init];
	wrote.directory = otherDirectory;
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	table.cacheDelegate = wrote;
	NSDictionary *plist = [table copyPlist];
	XCTAssertEqualObjects(plist[@"urlFastCache"], @"7.maddb");

	MADArrayCachingDirectoryDouble *reading = [[MADArrayCachingDirectoryDouble alloc] init];
	reading.directory = self.tempDirectory;
	MADDataTableFast *reloaded = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	reloaded.cacheDelegate = reading;
	NSError *error = nil;
	XCTAssertTrue([reloaded loadWithPlist: plist error: &error], @"load failed: %@", error);

	NSURL *resolved = [reloaded valueForKey: @"urlFastCache"];
	NSURL *expected = [self.tempDirectory URLByAppendingPathComponent:@"7.maddb" isDirectory:NO];
	XCTAssertEqualObjects(resolved.path, expected.path,
						  @"the file name was not resolved against the cache directory in use");
}

- (void)testDriverFillsAWritePortWithNoDataTableBehindIt {
	[self createPeopleTable];
	MADDatabaseSqlite3 *database = [self makeOpenDatabase];

	MADWritePortRecorder *table = [[MADWritePortRecorder alloc] init];
	NSError *error = nil;
	BOOL success = [database executeSQL:@"SELECT name, age FROM people ORDER BY rowid"
							  fieldKeys:@[@"name", @"age"]
						   onConnection:nil
						intoResultTable:table
						 transactionSet:NO
						 returnsResults:YES
						 binaryBindings:nil
							  withError:&error];

	XCTAssertTrue(success, @"the driver refused a bare write port: %@", error);

	// The five-call port, in the one order the drivers promise it in.
	XCTAssertEqualObjects(table.callLog, (@[@"removeAllObjects",
										   @"addColumn:", @"addColumn:",
										   @"beginBulkInsert",
										   @"addRowWithDataForFieldKeys:", @"addRowWithDataForFieldKeys:",
										   @"endBulkInsert"]));
	XCTAssertEqual(table.beginBulkInsertCount, (NSUInteger)1);
	XCTAssertEqual(table.endBulkInsertCount, (NSUInteger)1);

	XCTAssertEqualObjects(table.columnKeys, (@[@"name", @"age"]));
	XCTAssertEqual(table.rows.count, (NSUInteger)2);
	XCTAssertEqualObjects(table.rows[0][@"name"], @"alice");
	XCTAssertEqualObjects(table.rows[0][@"age"], @30);
	XCTAssertEqualObjects(table.rows[1][@"name"], @"bob");
	XCTAssertEqualObjects(table.rows[1][@"age"], @25);

	// Nothing on this path could have reached for a cache file.
	NSArray <NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.tempDirectory.path
																					   error:NULL];
	for (NSString *name in contents) {
		XCTAssertFalse([name.pathExtension isEqualToString:@"maddb"],
					   @"a .maddb cache file appeared: %@", name);
	}
}

#pragma mark - Checkpoint

// The document save path folds a store's WAL before archiving so a reader that
// extracts only the main file sees everything.  This pins the helper that does the
// folding: a WAL-mode database with a committed write has a non-empty -wal side file,
// and the checkpoint resets it while the writer's own connection stays open.
- (void)testCheckpointStoreAtURLFoldsTheWal {

	sqlite3 *database = NULL;
	XCTAssertEqual(sqlite3_open_v2(self.databaseURL.fileSystemRepresentation, &database,
								   SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL), SQLITE_OK);
	XCTAssertEqual(sqlite3_exec(database, "PRAGMA journal_mode=WAL;", NULL, NULL, NULL), SQLITE_OK);
	XCTAssertEqual(sqlite3_exec(database, "CREATE TABLE t (x INTEGER);", NULL, NULL, NULL), SQLITE_OK);
	XCTAssertEqual(sqlite3_exec(database, "INSERT INTO t VALUES (1);", NULL, NULL, NULL), SQLITE_OK);

	NSURL *walURL = [NSURL fileURLWithPath: [self.databaseURL.path stringByAppendingString: @"-wal"]];
	unsigned long long before = [[[NSFileManager defaultManager] attributesOfItemAtPath: walURL.path
																			   error: NULL][NSFileSize] unsignedLongLongValue];
	XCTAssertGreaterThan(before, 0ULL, @"the write sits in the WAL before the checkpoint");

	BOOL checkpointed = [MADDatabaseSqlite3 checkpointStoreAtURL: self.databaseURL];
	XCTAssertTrue(checkpointed, @"the checkpoint completes while the writer is still open");

	unsigned long long after = [[[NSFileManager defaultManager] attributesOfItemAtPath: walURL.path
																			  error: NULL][NSFileSize] unsignedLongLongValue];
	XCTAssertEqual(after, 0ULL, @"TRUNCATE resets the WAL to zero bytes");

	sqlite3_close(database);
}

@end
