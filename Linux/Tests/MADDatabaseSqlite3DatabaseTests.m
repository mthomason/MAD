//
//  MADDatabaseSqlite3DatabaseTests.m
//  Linux/Tests
//
//  Ported from MADSqlite3Tests/MADDatabaseSqlite3DatabaseTests.m: stateful
//  coverage for the MADSqlite3 framework that exercises a real on-disk sqlite3
//  database -- MADDatabaseSqlite3 open/connection lifecycle, MADArrayCaching
//  end-to-end, and the write port filled by the driver's row loop.  The Xcode
//  setUp/tearDown pair is a fresh temp directory per test here.
//

#import "MADTestSupport.h"

#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADSqlite3/MADArrayCaching.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDataTableObjectEnumerator.h>
#import <MADSqlite3/MADDataTableSingleColumnEnumerator.h>

#import <MADFoundation/MADCacheProtocol.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADAPI/MADQuery.h>

#import <MADSqlite3/sqlite3.h>

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

#pragma mark - Fixture helpers

static NSURL *makeTempDirectory(void) {
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	NSURL *directory = [NSURL fileURLWithPath:path isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:nil];
	return directory;
}

static void removeTempDirectory(NSURL *directory) {
	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static MADDatabaseSqlite3 *makeOpenDatabase(NSURL *databaseURL) {
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:databaseURL];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	database.databaseConnection = connection;
	[database openDatabase];
	return database;
}

static MADArrayCaching *makeArrayCaching(NSURL *tempDirectory) {
	MADArrayCachingDirectoryDouble *delegate = [[MADArrayCachingDirectoryDouble alloc] init];
	delegate.directory = tempDirectory;
	NSSet *types = [NSSet setWithObject:[NSString class]];
	MADArrayCaching *cache = [[MADArrayCaching alloc] initWithIdentifier:@"testCache"
														   cachedDelegate:delegate
																	 types:types];
	[cache initializeDatabase];
	return cache;
}

static MADDataColumn *makeColumnWithIdentifier(NSString *identifier, MADDataType type) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:identifier];
	column.fieldName = identifier;
	column.type = type;
	return column;
}

static void createPeopleTable(NSURL *databaseURL) {
	sqlite3 *db = NULL;
	sqlite3_open(databaseURL.path.UTF8String, &db);
	sqlite3_exec(db, "CREATE TABLE people (name TEXT, age INTEGER);", NULL, NULL, NULL);
	sqlite3_exec(db, "INSERT INTO people (name, age) VALUES ('alice', 30);", NULL, NULL, NULL);
	sqlite3_exec(db, "INSERT INTO people (name, age) VALUES ('bob', 25);", NULL, NULL, NULL);
	sqlite3_close(db);
}

#pragma mark - MADDatabaseSqlite3 connection lifecycle

static void testDatabaseHandleNilBeforeOpen(void) {
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	MAD_PASS([database databaseHandle] == NULL, "the database handle is null before open");
}

static void testOpenDatabaseCreatesHandleAndFile(void) {
	NSURL *tempDirectory = makeTempDirectory();
	NSURL *databaseURL = [tempDirectory URLByAppendingPathComponent:@"test.sqlite"];
	MADDatabaseSqlite3 *database = makeOpenDatabase(databaseURL);
	MAD_PASS([database databaseHandle] != NULL, "the handle exists after open");
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath:databaseURL.path], "the database file exists");
	removeTempDirectory(tempDirectory);
}

static void testOpenDatabaseWithFlags(void) {
	NSURL *tempDirectory = makeTempDirectory();
	NSURL *databaseURL = [tempDirectory URLByAppendingPathComponent:@"test.sqlite"];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:databaseURL];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	database.databaseConnection = connection;
	[database openDatabaseWithFlags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_SHAREDCACHE | SQLITE_OPEN_FULLMUTEX];
	MAD_PASS([database databaseHandle] != NULL, "the handle exists after opening with flags");
	removeTempDirectory(tempDirectory);
}

static void testIdentifier(void) {
	NSURL *tempDirectory = makeTempDirectory();
	NSURL *databaseURL = [tempDirectory URLByAppendingPathComponent:@"test.sqlite"];
	MADDatabaseSqlite3 *database = makeOpenDatabase(databaseURL);
	MAD_PASS_EQUAL([database identifier], @"Sqlite 3", "the open database carries the driver name");
	removeTempDirectory(tempDirectory);
}

static void testTableExist(void) {
	NSURL *tempDirectory = makeTempDirectory();
	NSURL *databaseURL = [tempDirectory URLByAppendingPathComponent:@"test.sqlite"];
	MADDatabaseSqlite3 *database = makeOpenDatabase(databaseURL);
	MAD_PASS(![database tableExist:@"missing_table"], "a table that was never created does not exist");

	sqlite3 *handle = (sqlite3 *)database.databaseHandle;
	MAD_PASS(sqlite3_exec(handle, "CREATE TABLE present_table (id INTEGER);", NULL, NULL, NULL) == SQLITE_OK, "the table is created");
	MAD_PASS([database tableExist:@"present_table"], "the created table exists");
	removeTempDirectory(tempDirectory);
}

static void testInstanceSafeIdentifiers(void) {
	NSURL *tempDirectory = makeTempDirectory();
	NSURL *databaseURL = [tempDirectory URLByAppendingPathComponent:@"test.sqlite"];
	MADDatabaseSqlite3 *database = makeOpenDatabase(databaseURL);
	MAD_PASS_EQUAL([database newSafeIdentifier:@"name"], @"\"name\"", "the instance safe identifier is quoted");
	MAD_PASS_EQUAL([database queryKey:@"field" table:@"tbl"], @"\"tbl\".\"field\"", "the instance query key is quoted table-dot-field");
	removeTempDirectory(tempDirectory);
}

#pragma mark - MADArrayCaching lifecycle

static void testArrayCachingLifecycle(void) {
	NSURL *tempDirectory = makeTempDirectory();
	MADArrayCaching *cache = makeArrayCaching(tempDirectory);
	MAD_PASS(cache.state == MADArrayCachingStateEmpty, "a fresh cache is empty");

	[cache addObject:@"alpha"];
	[cache addObject:@"bravo"];

	MAD_PASS([cache count] == (NSUInteger)2, "two objects are cached");
	MAD_PASS_EQUAL([cache objectAtIndex:0], @"alpha", "the first object round trips");
	MAD_PASS_EQUAL([cache objectAtIndex:1], @"bravo", "the second object round trips");

	[cache finalizeDatabase];
	removeTempDirectory(tempDirectory);
}

static void testArrayCachingObjectAtIndexedSubscript(void) {
	NSURL *tempDirectory = makeTempDirectory();
	MADArrayCaching *cache = makeArrayCaching(tempDirectory);
	[cache addObject:@"gamma"];
	MAD_PASS_EQUAL(cache[0], @"gamma", "subscripting reads the first object");
	[cache finalizeDatabase];
	removeTempDirectory(tempDirectory);
}

static void testArrayCachingOutOfRangeReturnsNil(void) {
	NSURL *tempDirectory = makeTempDirectory();
	MADArrayCaching *cache = makeArrayCaching(tempDirectory);
	[cache addObject:@"delta"];
	MAD_PASS([cache objectAtIndex:5] == nil, "an out-of-range index reads nil");
	[cache finalizeDatabase];
	removeTempDirectory(tempDirectory);
}

static void testArrayCachingRemoveAllObjects(void) {
	NSURL *tempDirectory = makeTempDirectory();
	MADArrayCaching *cache = makeArrayCaching(tempDirectory);
	[cache addObject:@"epsilon"];
	[cache addObject:@"zeta"];

	MAD_PASS([cache removeAllObjects], "the cache empties");
	MAD_PASS([cache objectAtIndex:0] == nil, "the first object is gone");

	[cache finalizeDatabase];
	removeTempDirectory(tempDirectory);
}

// An empty cache must report zero and empty; -isEmpty was inverted (returned YES
// when there were rows) and -count read a garbage value off a done statement.
static void testArrayCachingIsEmptyAndCountForEmpty(void) {
	NSURL *tempDirectory = makeTempDirectory();
	MADArrayCaching *cache = makeArrayCaching(tempDirectory);

	MAD_PASS([cache isEmpty], "a fresh cache is empty");
	MAD_PASS([cache count] == (NSUInteger)0, "a fresh cache counts zero");

	[cache addObject:@"alpha"];
	MAD_PASS(![cache isEmpty], "a cache with a row is not empty");
	MAD_PASS([cache count] == (NSUInteger)1, "one row counts one");

	[cache addObject:@"bravo"];
	MAD_PASS([cache count] == (NSUInteger)2, "two rows count two");

	MAD_PASS([cache removeAllObjects], "the cache empties");
	MAD_PASS([cache isEmpty], "an emptied cache is empty");
	MAD_PASS([cache count] == (NSUInteger)0, "an emptied cache counts zero");

	[cache finalizeDatabase];
	removeTempDirectory(tempDirectory);
}

// The render cache is read repeatedly; a repeated read must return the cached object
// rather than unarchive a fresh copy each time, and the object must round-trip.
static void testArrayCachingRepeatedReadsReturnTheCachedObject(void) {
	NSURL *tempDirectory = makeTempDirectory();
	MADArrayCaching *cache = makeArrayCaching(tempDirectory);
	[cache addObject:@"alpha"];
	[cache addObject:@"bravo"];

	MAD_PASS_EQUAL([cache objectAtIndex:1], @"bravo", "the first read returns the second object");
	MAD_PASS_EQUAL([cache objectAtIndex:0], @"alpha", "the second read returns the first object");
	MAD_PASS_EQUAL([cache objectAtIndex:1], @"bravo", "a repeated read returns the second object");
	MAD_PASS([cache objectAtIndex:1] == [cache objectAtIndex:1], "a repeated read returns the same cached instance");

	[cache finalizeDatabase];
	removeTempDirectory(tempDirectory);
}

#pragma mark - Enumerators

static void testDataTableObjectEnumerator(void) {
	NSURL *tempDirectory = makeTempDirectory();
	NSURL *databaseURL = [tempDirectory URLByAppendingPathComponent:@"test.sqlite"];
	createPeopleTable(databaseURL);
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:databaseURL];

	MADFixedSqlQuery *query = [[MADFixedSqlQuery alloc] init];
	query.sql = @"SELECT name, age, ROWID FROM people ORDER BY rowid";

	NSDictionary *columns = @{
		@"name": makeColumnWithIdentifier(@"name", MADDataTypeString),
		@"age": makeColumnWithIdentifier(@"age", MADDataTypeInteger),
	};
	NSArray *columnKeys = @[@"name", @"age"];

	MADDataTableObjectEnumerator *enumerator = [[MADDataTableObjectEnumerator alloc]
		initWithDatabaseConnection:connection columns:columns columnKeys:columnKeys query:query];

	NSArray *all = [enumerator allObjects];
	MAD_PASS(all.count == (NSUInteger)2, "both people enumerate");
	MAD_PASS_EQUAL(all[0][@"name"], @"alice", "the first name");
	MAD_PASS_EQUAL(all[0][@"age"], @30, "the first age");
	MAD_PASS_EQUAL(all[1][@"name"], @"bob", "the second name");
	MAD_PASS_EQUAL(all[1][@"age"], @25, "the second age");
	removeTempDirectory(tempDirectory);
}

static void testDataTableSingleColumnEnumerator(void) {
	NSURL *tempDirectory = makeTempDirectory();
	NSURL *databaseURL = [tempDirectory URLByAppendingPathComponent:@"test.sqlite"];
	createPeopleTable(databaseURL);
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:databaseURL];

	MADFixedSqlQuery *query = [[MADFixedSqlQuery alloc] init];
	query.sql = @"SELECT name FROM people ORDER BY rowid";

	NSDictionary *columns = @{@"name": makeColumnWithIdentifier(@"name", MADDataTypeString)};
	NSArray *columnKeys = @[@"name"];

	MADDataTableSingleColumnEnumerator *enumerator = [[MADDataTableSingleColumnEnumerator alloc]
		initWithDatabaseConnection:connection columns:columns columnKeys:columnKeys query:query];

	NSArray *all = [enumerator allObjects];
	MAD_PASS(all.count == (NSUInteger)2, "both names enumerate");
	MAD_PASS_EQUAL(all[0], @"alice", "the first name");
	MAD_PASS_EQUAL(all[1], @"bob", "the second name");
	removeTempDirectory(tempDirectory);
}

#pragma mark - Literal quoting

// A text filter used to be written as "London" -- a double-quoted token, which SQLite reads
// as a *column* name.  That survived only because SQLITE_DQS defaults to on;
// Compressor/sqlite3.xcconfig pins it to 0, and the London sample then failed to refresh
// with "no such column: London".  This puts a value containing a quote through a real query
// in the build that ships, so a literal that is bare or double-quoted fails here instead of
// in the app: either way the statement does not prepare and no row comes back.
static void testNewSafeLiteralProducesAValueSQLiteWillRead(void) {
	NSURL *tempDirectory = makeTempDirectory();
	NSURL *databaseURL = [tempDirectory URLByAppendingPathComponent:@"test.sqlite"];

	sqlite3 *ddl = NULL;
	sqlite3_open(databaseURL.path.UTF8String, &ddl);
	sqlite3_exec(ddl, "CREATE TABLE people (name TEXT, age INTEGER);", NULL, NULL, NULL);
	sqlite3_exec(ddl, "INSERT INTO people (name, age) VALUES ('O''Brien', 41);", NULL, NULL, NULL);
	sqlite3_close(ddl);

	MADDatabaseSqlite3 *database = makeOpenDatabase(databaseURL);
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:databaseURL];

	MADFixedSqlQuery *query = [[MADFixedSqlQuery alloc] init];
	query.sql = [[NSString alloc] initWithFormat:@"SELECT name, age FROM people WHERE name = %@ ORDER BY rowid",
				 [database newSafeLiteral:@"O'Brien"]];

	MADDataTableObjectEnumerator *enumerator = [[MADDataTableObjectEnumerator alloc]
		initWithDatabaseConnection:connection
						   columns:@{@"name": makeColumnWithIdentifier(@"name", MADDataTypeString),
									 @"age": makeColumnWithIdentifier(@"age", MADDataTypeInteger)}
						columnKeys:@[@"name", @"age"]
							 query:query];

	NSArray *all = [enumerator allObjects];
	// pass() carries a printf format attribute, which rejects %@, so the SQL goes in
	// as its C string.
	MAD_PASS(all.count == (NSUInteger)1, "the literal did not select the row it names: %s", query.sql.UTF8String);
	MAD_PASS_EQUAL(all[0][@"name"], @"O'Brien", "the quoted name comes back");
	MAD_PASS_EQUAL(all[0][@"age"], @41, "the age comes back");
	removeTempDirectory(tempDirectory);
}

#pragma mark - MADDataTableFast

static void testDataTableFastTableName(void) {
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:123 fromCache:YES];
	MAD_PASS_EQUAL([table tableName], @"t123", "the table name is t plus the id");
}

static void testDataTableFastRoundTrip(void) {
	NSURL *tempDirectory = makeTempDirectory();
	MADArrayCachingDirectoryDouble *delegate = [[MADArrayCachingDirectoryDouble alloc] init];
	delegate.directory = tempDirectory;

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	table.cacheDelegate = delegate;

	[table addColumn:makeColumnWithIdentifier(@"name", MADDataTypeString)];
	[table addColumn:makeColumnWithIdentifier(@"age", MADDataTypeInteger)];

	[table addRowWithDataForFieldKeys:@{@"name": @"alice", @"age": @30}];
	[table addRowWithDataForFieldKeys:@{@"name": @"bob", @"age": @25}];

	MAD_PASS([table numberOfRows] == (NSUInteger)2, "two rows are stored");

	NSDictionary *row0 = [table objectAtRow:0];
	MAD_PASS_EQUAL(row0[@"name"], @"alice", "the first row's name");
	MAD_PASS_EQUAL(row0[@"age"], @30, "the first row's age");

	NSDictionary *row1 = [table objectAtRow:1];
	MAD_PASS_EQUAL(row1[@"name"], @"bob", "the second row's name");
	MAD_PASS_EQUAL(row1[@"age"], @25, "the second row's age");

	MAD_PASS([table columnKeyForColumnName:@"name"] != nil, "the column key is found by name");
	removeTempDirectory(tempDirectory);
}

// The cache plist stores urls.urlFastCache as an absolute URL, so it names the
// application's data container and not just the file.  A container does not survive a
// reinstall, and the stored path then points into a directory that is gone.  Opening it
// fails -- SQLITE_OPEN_CREATE cannot create a file where the directory does not exist --
// and -openDatabaseWithFlags: asserts, which took the whole app down on the first
// document tap.  A stale URL has to be discarded and recomputed for the container in use.
static void testLoadWithPlistDiscardsACacheUrlWhoseDirectoryIsGone(void) {
	NSURL *tempDirectory = makeTempDirectory();
	MADArrayCachingDirectoryDouble *delegate = [[MADArrayCachingDirectoryDouble alloc] init];
	delegate.directory = tempDirectory;

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	table.cacheDelegate = delegate;

	NSMutableDictionary *plist = [[table copyPlist] mutableCopy];
	// The directory this names is deliberately never created, which is what a container
	// that has been replaced looks like from the file system's side.
	NSString *gone = [tempDirectory.path stringByAppendingPathComponent:@"gone/gone.maddb"];
	plist[@"urlFastCache"] = [[NSURL fileURLWithPath: gone] absoluteString];

	MADDataTableFast *reloaded = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	reloaded.cacheDelegate = delegate;
	NSError *error = nil;
	MAD_PASS([reloaded loadWithPlist: plist error: &error], "the load succeeds (error: %s)", [[error description] UTF8String]);

	// -urlFastCache is private to the implementation, so reach it the way any other
	// reader outside MADDataTableFast would have to.
	NSURL *resolved = [reloaded valueForKey: @"urlFastCache"];
	NSURL *expected = [tempDirectory URLByAppendingPathComponent:@"7.maddb" isDirectory:NO];
	MAD_PASS_EQUAL(resolved.path, expected.path,
				   "the reload kept a cache url whose directory does not exist");
	removeTempDirectory(tempDirectory);
}

static void testLoadWithPlistKeepsACacheUrlWhoseDirectoryIsPresent(void) {
	NSURL *tempDirectory = makeTempDirectory();
	MADArrayCachingDirectoryDouble *delegate = [[MADArrayCachingDirectoryDouble alloc] init];
	delegate.directory = tempDirectory;

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	table.cacheDelegate = delegate;

	NSMutableDictionary *plist = [[table copyPlist] mutableCopy];
	NSURL *live = [tempDirectory URLByAppendingPathComponent:@"7.maddb" isDirectory:NO];
	plist[@"urlFastCache"] = live.absoluteString;

	MADDataTableFast *reloaded = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	reloaded.cacheDelegate = delegate;
	NSError *error = nil;
	MAD_PASS([reloaded loadWithPlist: plist error: &error], "the load succeeds (error: %s)", [[error description] UTF8String]);

	NSURL *resolved = [reloaded valueForKey: @"urlFastCache"];
	MAD_PASS_EQUAL(resolved.path, live.path, "the reload keeps a cache url whose directory is present");
	removeTempDirectory(tempDirectory);
}

// Reading a stale absolute URL is safe now, but writing one is how the staleness got
// in: the path names the data container, and the container does not survive a
// reinstall.  What is written is the file name alone.
static void testCopyPlistStoresTheCacheFileNameNotAnAbsoluteUrl(void) {
	NSURL *tempDirectory = makeTempDirectory();
	MADArrayCachingDirectoryDouble *delegate = [[MADArrayCachingDirectoryDouble alloc] init];
	delegate.directory = tempDirectory;

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	table.cacheDelegate = delegate;

	NSString *stored = [table copyPlist][@"urlFastCache"];
	MAD_PASS_EQUAL(stored, @"7.maddb",
				   "the plist stored a path, which names the container as well as the file");
	MAD_PASS(![stored containsString: @"/"], "a container path was written: %s", stored.UTF8String);
	MAD_PASS([NSURL URLWithString: stored].scheme == nil, "the stored value still parses as an absolute URL");
	removeTempDirectory(tempDirectory);
}

// The format fix in one test: a plist written against one cache directory resolves
// against the directory in use when it is read, so the cache survives the container
// that wrote it -- which is what an absolute URL could not do.
static void testLoadWithPlistResolvesAStoredFileNameInTheDirectoryInUseNow(void) {
	NSURL *tempDirectory = makeTempDirectory();
	NSURL *otherDirectory = [tempDirectory URLByAppendingPathComponent:@"other" isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL: otherDirectory
							 withIntermediateDirectories: YES
											  attributes: nil
												   error: NULL];

	MADArrayCachingDirectoryDouble *wrote = [[MADArrayCachingDirectoryDouble alloc] init];
	wrote.directory = otherDirectory;
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	table.cacheDelegate = wrote;
	NSDictionary *plist = [table copyPlist];
	MAD_PASS_EQUAL(plist[@"urlFastCache"], @"7.maddb", "the written plist stores the file name alone");

	MADArrayCachingDirectoryDouble *reading = [[MADArrayCachingDirectoryDouble alloc] init];
	reading.directory = tempDirectory;
	MADDataTableFast *reloaded = [[MADDataTableFast alloc] initWithId:7 fromCache:YES];
	reloaded.cacheDelegate = reading;
	NSError *error = nil;
	MAD_PASS([reloaded loadWithPlist: plist error: &error], "the load succeeds (error: %s)", [[error description] UTF8String]);

	NSURL *resolved = [reloaded valueForKey: @"urlFastCache"];
	NSURL *expected = [tempDirectory URLByAppendingPathComponent:@"7.maddb" isDirectory:NO];
	MAD_PASS_EQUAL(resolved.path, expected.path,
				   "the file name was not resolved against the cache directory in use");
	removeTempDirectory(tempDirectory);
}

static void testDriverFillsAWritePortWithNoDataTableBehindIt(void) {
	NSURL *tempDirectory = makeTempDirectory();
	NSURL *databaseURL = [tempDirectory URLByAppendingPathComponent:@"test.sqlite"];
	createPeopleTable(databaseURL);
	MADDatabaseSqlite3 *database = makeOpenDatabase(databaseURL);

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

	MAD_PASS(success, "the driver refused a bare write port: %s", [[error description] UTF8String]);

	// The five-call port, in the one order the drivers promise it in.
	MAD_PASS_EQUAL(table.callLog, (@[@"removeAllObjects",
									 @"addColumn:", @"addColumn:",
									 @"beginBulkInsert",
									 @"addRowWithDataForFieldKeys:", @"addRowWithDataForFieldKeys:",
									 @"endBulkInsert"]),
				   "the five-call port, in the one order the drivers promise it in");
	MAD_PASS(table.beginBulkInsertCount == (NSUInteger)1, "one bulk insert begins");
	MAD_PASS(table.endBulkInsertCount == (NSUInteger)1, "one bulk insert ends");

	MAD_PASS_EQUAL(table.columnKeys, (@[@"name", @"age"]), "the column keys arrive in order");
	MAD_PASS(table.rows.count == (NSUInteger)2, "both rows arrive");
	MAD_PASS_EQUAL(table.rows[0][@"name"], @"alice", "the first row's name");
	MAD_PASS_EQUAL(table.rows[0][@"age"], @30, "the first row's age");
	MAD_PASS_EQUAL(table.rows[1][@"name"], @"bob", "the second row's name");
	MAD_PASS_EQUAL(table.rows[1][@"age"], @25, "the second row's age");

	// Nothing on this path could have reached for a cache file.
	NSArray <NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tempDirectory.path
																						   error:NULL];
	for (NSString *name in contents) {
		MAD_PASS(![name.pathExtension isEqualToString:@"maddb"],
				 "a .maddb cache file appeared: %s", name.UTF8String);
	}
	removeTempDirectory(tempDirectory);
}

#pragma mark - Checkpoint

// The document save path folds a store's WAL before archiving so a reader that
// extracts only the main file sees everything.  This pins the helper that does the
// folding: a WAL-mode database with a committed write has a non-empty -wal side file,
// and the checkpoint resets it while the writer's own connection stays open.
static void testCheckpointStoreAtURLFoldsTheWal(void) {
	NSURL *tempDirectory = makeTempDirectory();
	NSURL *databaseURL = [tempDirectory URLByAppendingPathComponent:@"test.sqlite"];

	sqlite3 *database = NULL;
	MAD_PASS(sqlite3_open_v2(databaseURL.fileSystemRepresentation, &database,
							 SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) == SQLITE_OK,
			 "the WAL database opens");
	MAD_PASS(sqlite3_exec(database, "PRAGMA journal_mode=WAL;", NULL, NULL, NULL) == SQLITE_OK, "WAL journaling is set");
	MAD_PASS(sqlite3_exec(database, "CREATE TABLE t (x INTEGER);", NULL, NULL, NULL) == SQLITE_OK, "the table is created");
	MAD_PASS(sqlite3_exec(database, "INSERT INTO t VALUES (1);", NULL, NULL, NULL) == SQLITE_OK, "a row is written");

	NSURL *walURL = [NSURL fileURLWithPath: [databaseURL.path stringByAppendingString: @"-wal"]];
	unsigned long long before = [[[NSFileManager defaultManager] attributesOfItemAtPath: walURL.path
																				   error: NULL][NSFileSize] unsignedLongLongValue];
	MAD_PASS(before > 0ULL, "the write sits in the WAL before the checkpoint");

	BOOL checkpointed = [MADDatabaseSqlite3 checkpointStoreAtURL: databaseURL];
	MAD_PASS(checkpointed, "the checkpoint completes while the writer is still open");

	unsigned long long after = [[[NSFileManager defaultManager] attributesOfItemAtPath: walURL.path
																				  error: NULL][NSFileSize] unsignedLongLongValue];
	MAD_PASS(after == 0ULL, "TRUNCATE resets the WAL to zero bytes");

	sqlite3_close(database);
	removeTempDirectory(tempDirectory);
}

MAD_TEST_MAIN("MADDatabaseSqlite3DatabaseTests",
	MAD_TEST(testDatabaseHandleNilBeforeOpen),
	MAD_TEST(testOpenDatabaseCreatesHandleAndFile),
	MAD_TEST(testOpenDatabaseWithFlags),
	MAD_TEST(testIdentifier),
	MAD_TEST(testTableExist),
	MAD_TEST(testInstanceSafeIdentifiers),
	MAD_TEST(testArrayCachingLifecycle),
	MAD_TEST(testArrayCachingObjectAtIndexedSubscript),
	MAD_TEST(testArrayCachingOutOfRangeReturnsNil),
	MAD_TEST(testArrayCachingRemoveAllObjects),
	MAD_TEST(testArrayCachingIsEmptyAndCountForEmpty),
	MAD_TEST(testArrayCachingRepeatedReadsReturnTheCachedObject),
	MAD_TEST(testDataTableObjectEnumerator),
	MAD_TEST(testDataTableSingleColumnEnumerator),
	MAD_TEST(testNewSafeLiteralProducesAValueSQLiteWillRead),
	MAD_TEST(testDataTableFastTableName),
	MAD_TEST(testDataTableFastRoundTrip),
	MAD_TEST(testLoadWithPlistDiscardsACacheUrlWhoseDirectoryIsGone),
	MAD_TEST(testLoadWithPlistKeepsACacheUrlWhoseDirectoryIsPresent),
	MAD_TEST(testCopyPlistStoresTheCacheFileNameNotAnAbsoluteUrl),
	MAD_TEST(testLoadWithPlistResolvesAStoredFileNameInTheDirectoryInUseNow),
	MAD_TEST(testDriverFillsAWritePortWithNoDataTableBehindIt),
	MAD_TEST(testCheckpointStoreAtURLFoldsTheWal));
