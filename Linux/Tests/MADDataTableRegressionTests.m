//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDataTableRegressionTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADDataTableRegressionTests.m: characterization
//  ("lock down the current behaviour") tests for MADDataTable and its
//  derivatives.  These tests intentionally record how the code behaves TODAY,
//  including quirks, so that the pending refactor can be proven behaviour
//  preserving.
//
//  Covered types:
//    MADFoundation : MADDataTable, MADDataTableType, MADDataTableVirtual
//    MADSqlite3    : MADDataTableFast, MADDataTableSingleColumnEnumerator,
//                    MADDataTableObjectEnumerator
//    MAD           : MADDataTable+Constructor
//
//  Threading contract recorded here (see the "Threading" section at the bottom):
//    * MADDataTable / MADDataTableVirtual keep their state in plain NSMutableArray /
//      NSMutableDictionary instances and take no locks.  Concurrent reads of an
//      otherwise quiescent table are safe; ANY concurrent write is not.
//    * MADDataTableFast keeps two sqlite3 handles (one for inserts, one for selects).
//      The inserts handle is opened SQLITE_OPEN_FULLMUTEX.  Reads go through
//      databaseForSelects, and every enumerator built by the table opens its OWN
//      connection, so concurrent enumeration is safe.
//    * MADDataTableFast has a serial `queueBulkAdd`, but it is only used by
//      -endBulkInsert.  -addRow: is NOT internally serialized, so writes must be
//      serialized by the caller (the serialized-write tests below encode that).
//
//  The Xcode suite's -setUp/-tearDown pair is a fresh cache directory and cache
//  delegate per test here (regressionSetUp/regressionTearDown), which each test
//  brackets its body with.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADDataTableVirtual.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADCacheProtocol.h>

#import <MADAPI/MADQuery.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>

#import <MADSqlite3/MADDataTableFast.h>

// MADDataTableObjectEnumerator.h and MADDataTableSingleColumnEnumerator.h are
// private headers of the MADSqlite3 framework, so the tests reach them through
// the table's factory methods and identify them by name rather than importing
// framework internals.
static NSString * const MADDataTableObjectEnumeratorClassName = @"MADDataTableObjectEnumerator";
static NSString * const MADDataTableSingleColumnEnumeratorClassName = @"MADDataTableSingleColumnEnumerator";

#import <MAD/MADDataTable+Constructor.h>

// QOS_CLASS_USER_INITIATED is Darwin's spelling of this queue's priority; the
// Linux libdispatch names the same band DISPATCH_QUEUE_PRIORITY_HIGH (its header
// maps the two together), so the global queue is asked for that off Apple.
#if __APPLE__
#define MADRegressionQueuePriority QOS_CLASS_USER_INITIATED
#else
#define MADRegressionQueuePriority DISPATCH_QUEUE_PRIORITY_HIGH
#endif

#pragma mark - Test Doubles

/// Minimal MADCacheProtocol implementation.  MADDataTableFast derives its cache
/// file URL from this delegate; without one it reaches for the application
/// delegate, which does not exist inside a logic test bundle.
///
/// MADDataTableFast also installs its cache delegate on the inner
/// MADDatabaseSqlite3 as the MADDatabaseResultsProtocol delegate, which is where
/// cached rows are written back.  -dataTableForQuery: is @optional in that
/// protocol, so MADDatabaseSqlite3 has to test for it before calling; the pair of
/// doubles below covers both the implementing and the non-implementing case.
@interface MADDataTableRegressionCacheDelegate : NSObject <MADCacheProtocol, MADDatabaseResultsProtocol>

@property (nonatomic, strong) NSURL *cachedFilesDirectory;
// The Xcode suite declares this back-pointer weak; GNUstep refuses to synthesize a
// weak property in an MRC translation unit (the tests build -fno-objc-arc), and an
// assign back-pointer is what this double needs.
@property (nonatomic, assign) MADDataTable *dataTable;

@end

@implementation MADDataTableRegressionCacheDelegate

- (MADDataTable *)dataTableForQuery:(MADQuery *)query {
	return self.dataTable;
}

@end

/// A conforming MADDatabaseResultsProtocol delegate that implements none of the
/// protocol's @optional methods - the case that used to raise
/// NSInvalidArgumentException out of MADDatabaseSqlite3.
@interface MADDataTableRegressionBareDelegate : NSObject <MADCacheProtocol, MADDatabaseResultsProtocol>

@property (nonatomic, strong) NSURL *cachedFilesDirectory;

@end

@implementation MADDataTableRegressionBareDelegate
@end

// MADDataTableFast keeps its cache-file mutations private, since -removeAllObjects
// is the only caller.  Declare them so the row-counter tests can drive each one
// directly and pin what it does to -count.
@interface MADDataTableFast (TestCacheMutations)
- (void)dropTable;
- (void)dropTableName:(NSString *)tableName;
- (void)deleteAll;
- (void)vacuumCacheDb;
// -endBulkInsert closes the inserts connection and nulls its handle, so anything that
// sends SQL through it afterwards needs this first.  -removeAllObjects opens with it.
- (void)reopenDbConnection;
@end

#pragma mark - Fixtures

// The Xcode suite's -setUp/-tearDown: a fresh cache directory and delegate per test.
// The file-scope pair stands in for the two XCTestCase ivars; each test brackets its
// body with these calls the way the XCTest runner bracketed the method.
static NSURL *gRegressionCacheDirectory = nil;
static MADDataTableRegressionCacheDelegate *gRegressionCacheDelegate = nil;

static void regressionSetUp(void) {
	NSString *name = [[NSString alloc] initWithFormat:@"MADDataTableRegression-%@", [[NSUUID UUID] UUIDString]];
	NSURL *directory = [[NSURL alloc] initFileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:name]
											  isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:NULL];
	gRegressionCacheDirectory = directory;	// +1 from alloc, held by the static

	MADDataTableRegressionCacheDelegate *delegate = [[MADDataTableRegressionCacheDelegate alloc] init];
	delegate.cachedFilesDirectory = directory;
	gRegressionCacheDelegate = delegate;	// +1 from alloc, held by the static
}

static void regressionTearDown(void) {
	if (gRegressionCacheDirectory != nil) {
		[[NSFileManager defaultManager] removeItemAtURL:gRegressionCacheDirectory error:NULL];
	}
	[gRegressionCacheDelegate release];
	gRegressionCacheDelegate = nil;
	[gRegressionCacheDirectory release];
	gRegressionCacheDirectory = nil;
}

#pragma mark - Helpers

/// Builds a sqlite backed table with a "name" (string) and an "age" (integer) column.
static MADDataTableFast *newFastTableWithTagAndDelegate(NSUInteger tag,
														id <MADCacheProtocol, MADDatabaseResultsProtocol> cacheDelegate) {
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:tag];
	if ([cacheDelegate isKindOfClass:[MADDataTableRegressionCacheDelegate class]]) {
		((MADDataTableRegressionCacheDelegate *)cacheDelegate).dataTable = table;
	}
	table.cacheDelegate = cacheDelegate;

	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;
	[table addColumn:name];

	MADDataColumn *age = [[MADDataColumn alloc] initWithIdentifier:@"age"];
	age.type = MADDataTypeInteger;
	[table addColumn:age];

	return table;
}

static MADDataTableFast *newFastTableWithTag(NSUInteger tag) {
	return newFastTableWithTagAndDelegate(tag, gRegressionCacheDelegate);
}

/// Builds an in-memory table with a "name" (string) and an "age" (integer) column.
static MADDataTableVirtual *newVirtualTableWithTag(NSUInteger tag) {
	MADDataTableVirtual *table = [[MADDataTableVirtual alloc] initWithId:tag];

	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;
	[table addColumn:name];

	MADDataColumn *age = [[MADDataColumn alloc] initWithIdentifier:@"age"];
	age.type = MADDataTypeInteger;
	[table addColumn:age];

	return table;
}

/// Inserts rows through the bulk path, which is the only path that binds values.
static void bulkInsertRows(NSArray <NSArray *> *rows, MADDataTableFast *table) {
	[table beginBulkInsert];
	NSError *error = nil;
	for (NSArray *row in rows) {
		BOOL success = [table addRow:row error:&error];
		MAD_PASS(success, "Bulk addRow: failed: %s", [[error description] UTF8String]);
	}
	[table endBulkInsert];
}

#pragma mark - MADDataTable (base class)

static void testBaseTableInitDefaults(void) {
	regressionSetUp();
	MADDataTable *table = [[MADDataTable alloc] init];

	MAD_PASS(table.tag == (NSUInteger)0, "the tag defaults to zero");
	MAD_PASS_EQUAL(table.name, @"", "the name defaults to the empty string");
	MAD_PASS(table.rowCounter == (NSUInteger)0, "the row counter defaults to zero");
	MAD_PASS(table.columnKeys != nil, "the column keys exist");
	MAD_PASS(table.columns != nil, "the columns exist");
	MAD_PASS(table.sortDescriptors != nil, "the sort descriptors exist");
	MAD_PASS(table.columnKeys.count == (NSUInteger)0, "the column keys start empty");
	MAD_PASS(table.columns.count == (NSUInteger)0, "the columns start empty");
	MAD_PASS(table.sortDescriptors.count == (NSUInteger)0, "the sort descriptors start empty");
	regressionTearDown();
}

static void testBaseTableInitWithIdSetsTag(void) {
	regressionSetUp();
	MADDataTable *table = [[MADDataTable alloc] initWithId:1234];
	MAD_PASS(table.tag == (NSUInteger)1234, "the id becomes the tag");
	regressionTearDown();
}

/// MADDataTable itself is the inert base of the hierarchy.  The read answers
/// below are truthful for a table with no rows, so they remain plain defaults
/// rather than assertions.
static void testBaseTableEmptyReadAnswers(void) {
	regressionSetUp();
	MADDataTable *table = [[MADDataTable alloc] initWithId:7];

	MAD_PASS([table numberOfRows] == (NSUInteger)0, "no rows");
	MAD_PASS([table numberOfColumns] == (NSUInteger)0, "no columns");
	MAD_PASS([table count] == (NSUInteger)0, "no count");
	MAD_PASS_EQUAL([table allObjects], @[], "no objects");
	MAD_PASS_EQUAL([table objectAtRow:0 limit:10], @[], "no limited objects");

	// The bulk-insert hooks are optional and are deliberate no-ops; they must
	// not throw, because a subclass need not implement bulk mode at all.
	[table beginBulkInsert];
	[table endBulkInsert];

	MAD_PASS([table numberOfRows] == (NSUInteger)0, "still no rows");
	regressionTearDown();
}

/// CONTRACT: the abstract row/column operations assert instead of failing
/// silently.  Previously -addRow:error: returned true while discarding the row,
/// so a storage subclass that forgot an override lost data with no sign of
/// trouble.  NSAssert is compiled out of Release, so the throws are only
/// meaningful in a Debug test run.
static void testBaseTableAbstractOperationsAssert(void) {
	regressionSetUp();
	MADDataTable *table = [[MADDataTable alloc] initWithId:7];
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	NSError *error = nil;

#if defined(DEBUG) && DEBUG
	MAD_THROWS_NAMED([table addColumn:column], @"NSInternalInconsistencyException", "addColumn: asserts");
	MAD_THROWS_NAMED([table addRow:@[@"a"] error:&error], @"NSInternalInconsistencyException", "addRow:error: asserts");
	MAD_THROWS_NAMED([table addRowWithDataForFieldKeys:@{@"name": @"a"}], @"NSInternalInconsistencyException", "addRowWithDataForFieldKeys: asserts");
	MAD_THROWS_NAMED([table sortUsingDescriptors:@[]], @"NSInternalInconsistencyException", "sortUsingDescriptors: asserts");
	MAD_THROWS_NAMED([table removeAllObjects], @"NSInternalInconsistencyException", "removeAllObjects asserts");
	MAD_THROWS_NAMED([table objectAtRow:0 column:0], @"NSInternalInconsistencyException", "objectAtRow:column: asserts");
	MAD_THROWS_NAMED([table objectAtRow:0], @"NSInternalInconsistencyException", "objectAtRow: asserts");
	MAD_THROWS_NAMED([table columnsEnumerator], @"NSInternalInconsistencyException", "columnsEnumerator asserts");
	MAD_THROWS_NAMED([table objectEnumerator], @"NSInternalInconsistencyException", "objectEnumerator asserts");
#else
	// Release: the assertions are gone, so the methods fall through to their
	// defaults.  -addRow:error: reports failure rather than claiming success.
	MAD_PASS([table addRow:@[@"a"] error:&error] == false, "addRow:error: reports failure");
	MAD_PASS([table objectAtRow:0] == nil, "objectAtRow: is nil");
	MAD_PASS([table objectAtRow:0 column:0] == nil, "objectAtRow:column: is nil");
	MAD_PASS([table columnsEnumerator] == nil, "columnsEnumerator is nil");
	MAD_PASS([table objectEnumerator] == nil, "objectEnumerator is nil");
#endif
	regressionTearDown();
}

static void testBaseTableNewFilenameMDCacheUsesTag(void) {
	regressionSetUp();
	MADDataTable *table = [[MADDataTable alloc] initWithId:42];
	MAD_PASS_EQUAL([table newFilenameMDCache], @"42.mdcache", "the cache file name is the tag");
	regressionTearDown();
}

static void testBaseTableLoadFromCacheWithMissingFileReturnsError(void) {
	regressionSetUp();
	MADDataTable *table = [[MADDataTable alloc] initWithId:1];
	NSURL *missing = [gRegressionCacheDirectory URLByAppendingPathComponent:@"does-not-exist.mdcache"];

	NSError *error = nil;
	BOOL loaded = [table loadFromCacheWithUrl:missing error:&error];

	MAD_PASS(!loaded, "the load reports failure");
	MAD_PASS(error != nil, "an error comes back");
	MAD_PASS(error.code == (NSInteger)-215, "the error code is -215");
	regressionTearDown();
}

/// CONTRACT: the error parameter is optional.  The method's other failure paths
/// already guard `if (outError)`, so a caller that passes NULL must get NO back
/// for a missing file rather than a dereference of the null pointer.
static void testBaseTableLoadFromCacheWithMissingFileAndNullErrorReturnsNo(void) {
	regressionSetUp();
	MADDataTable *table = [[MADDataTable alloc] initWithId:1];
	NSURL *missing = [gRegressionCacheDirectory URLByAppendingPathComponent:@"does-not-exist.mdcache"];

	BOOL loaded = [table loadFromCacheWithUrl:missing error:NULL];

	MAD_PASS(!loaded, "the load reports failure with no error pointer");
	regressionTearDown();
}

/// CONTRACT: same for the payload-failure path.  A file that parses as a property
/// list but is not a table payload makes loadWithPlist: fail, and that failure
/// must survive a NULL error parameter too.
static void testBaseTableLoadFromCacheWithInvalidPlistAndNullErrorReturnsNo(void) {
	regressionSetUp();
	NSURL *url = [gRegressionCacheDirectory URLByAppendingPathComponent:@"not-a-table.mdcache"];
	NSDictionary *plist = @{@"not": @"a table payload"};
	MAD_PASS([plist writeToURL:url atomically:YES], "the plist fixture writes");

	MADDataTable *table = [[MADDataTable alloc] initWithId:1];

	BOOL loaded = [table loadFromCacheWithUrl:url error:NULL];

	MAD_PASS(!loaded, "the invalid payload reports failure with no error pointer");
	regressionTearDown();
}

/// CONTRACT: a nil URL is a programmer error - the implementation @throws rather
/// than returning NO.  It throws an NSError object rather than an NSException,
/// which is unusual but is the current behaviour.
static void testBaseTableLoadFromCacheWithNilUrlThrows(void) {
	regressionSetUp();
	MADDataTable *table = [[MADDataTable alloc] initWithId:1];

	BOOL threw = NO;
	@try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
		// The nil is the point of the test: the parameter is declared nonnull, so
		// this deliberately breaks that contract to record what the guard does.
		[table loadFromCacheWithUrl:(NSURL *)nil error:NULL];
#pragma clang diagnostic pop
	} @catch (id exception) {
		threw = YES;
		MAD_PASS([exception isKindOfClass:[NSError class]],
				 "Expected a thrown NSError, got %s", NSStringFromClass([exception class]).UTF8String);
	}
	MAD_PASS(threw, "A nil URL should be rejected.");
	regressionTearDown();
}

#pragma mark - MADDataTableVirtual: construction and rows

static void testVirtualTableStartsEmpty(void) {
	regressionSetUp();
	MADDataTableVirtual *table = [[MADDataTableVirtual alloc] initWithId:9];

	MAD_PASS(table.tag == (NSUInteger)9, "the id becomes the tag");
	MAD_PASS([table numberOfRows] == (NSUInteger)0, "no rows");
	MAD_PASS([table numberOfColumns] == (NSUInteger)0, "no columns");
	MAD_PASS([table count] == (NSUInteger)0, "no count");
	MAD_PASS_EQUAL([table allObjects], @[], "no objects");
	regressionTearDown();
}

static void testVirtualTableAddColumnRecordsKeyAndMetadata(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);

	MAD_PASS([table numberOfColumns] == (NSUInteger)2, "two columns");
	MAD_PASS_EQUAL(table.columnKeys, (@[@"name", @"age"]), "the column keys in order");
	MAD_PASS(table.columns[@"name"] != nil, "the name column exists");
	MAD_PASS(table.columns[@"age"] != nil, "the age column exists");
	MAD_PASS(table.columns[@"name"].type == MADDataTypeString, "the name column is a string");
	MAD_PASS(table.columns[@"age"].type == MADDataTypeInteger, "the age column is an integer");
	regressionTearDown();
}

static void testVirtualTableAddRowBuildsIndexedDictionary(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);

	NSError *error = nil;
	MAD_PASS(([table addRow:@[@"alice", @30] error:&error]), "the row is added");

	MAD_PASS([table numberOfRows] == (NSUInteger)1, "one row");
	MAD_PASS([table count] == (NSUInteger)1, "one counted row");
	MAD_PASS(table.rowCounter == (NSUInteger)1, "the row counter advanced");

	NSArray *all = [table allObjects];
	MAD_PASS(all.count == (NSUInteger)1, "one object");

	NSDictionary *row = all.firstObject;
	MAD_PASS_EQUAL(row[@"name"], @"alice", "the name value");
	MAD_PASS_EQUAL(row[@"age"], @30, "the age value");
	// Rows are stamped with the row counter under a private key.
	MAD_PASS_EQUAL(row[@"~rowid~"], @0, "the row id stamp");
	regressionTearDown();
}

static void testVirtualTableAddRowStampsMonotonicRowIds(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];
	[table addRow:@[@"bob", @20] error:&error];
	[table addRow:@[@"carol", @40] error:&error];

	NSArray <NSDictionary *> *all = [table allObjects];
	MAD_PASS(all.count == (NSUInteger)3, "three rows");
	MAD_PASS_EQUAL(all[0][@"~rowid~"], @0, "the first row id");
	MAD_PASS_EQUAL(all[1][@"~rowid~"], @1, "the second row id");
	MAD_PASS_EQUAL(all[2][@"~rowid~"], @2, "the third row id");
	MAD_PASS_EQUAL(all[0][@"name"], @"alice", "the first name");
	MAD_PASS_EQUAL(all[1][@"name"], @"bob", "the second name");
	MAD_PASS_EQUAL(all[2][@"name"], @"carol", "the third name");
	regressionTearDown();
}

static void testVirtualTableObjectAtRowAndColumn(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];
	[table addRow:@[@"bob", @20] error:&error];

	NSDictionary *first = [table objectAtRow:0];
	MAD_PASS_EQUAL(first[@"name"], @"alice", "the first row by position");

	// Unsorted lookups map the row straight through to the backing column.
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"alice", "row 0 column 0");
	MAD_PASS_EQUAL([table objectAtRow:1 column:0], @"bob", "row 1 column 0");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @30, "row 0 column 1");
	MAD_PASS_EQUAL([table objectAtRow:1 column:1], @20, "row 1 column 1");
	regressionTearDown();
}

/// CONTRACT: -objectAtRow: bounds checks and returns nil; it does not throw.
static void testVirtualTableObjectAtRowOutOfBoundsReturnsNil(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];

	MAD_PASS([table objectAtRow:1] == nil, "one past the last row is nil");
	MAD_PASS([table objectAtRow:1000] == nil, "far out of range is nil");
	regressionTearDown();
}

/// CONTRACT: -dataForRow:error: addresses rows by position, exactly like
/// -objectAtRow:, so the two access paths agree.  The base class asserts here,
/// which is why this has to be implemented rather than inherited.
static void testVirtualTableDataForRowReturnsTheRowAtThatIndex(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];
	[table addRow:@[@"bob", @20] error:&error];

	NSDictionary *first = [table dataForRow:0 error:&error];
	MAD_PASS(first != nil, "the first row comes back");
	MAD_PASS(error == nil, "no error for a valid row");
	MAD_PASS_EQUAL(first[@"name"], @"alice", "the first name");
	MAD_PASS_EQUAL([table dataForRow:1 error:&error][@"name"], @"bob", "the second name");
	regressionTearDown();
}

/// CONTRACT: an out-of-range row id is reported through the error pointer, since
/// nil alone cannot say whether the row is missing or the lookup failed.
static void testVirtualTableDataForRowOutOfBoundsReportsAnError(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];

	error = nil;
	MAD_PASS([table dataForRow:1000 error:&error] == nil, "the missing row is nil");
	MAD_PASS(error != nil, "an error is reported");
	MAD_PASS(error.code == (NSInteger)8927, "the error code is 8927");
	regressionTearDown();
}

/// CONTRACT: -addRow: indexes columnKeys directly, so a row wider than the column
/// list raises NSRangeException instead of returning an error.
static void testVirtualTableAddRowWiderThanColumnsRaises(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);
	NSError *error = nil;

	MAD_THROWS_NAMED(([table addRow:@[@"alice", @30, @"extra"] error:&error]),
					 NSRangeException,
					 "a row wider than the columns raises NSRangeException");
	regressionTearDown();
}

/// CONTRACT: -addRowWithDataForFieldKeys: appends normalized values to the backing
/// columns, but stores the CALLER'S dictionary in the sort index unchanged.  So the
/// row handed back by -allObjects carries no "~rowid~" stamp and aliases the caller's
/// instance, unlike rows added through -addRow:.
static void testVirtualTableAddRowWithDataForFieldKeysStoresCallerDictionary(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);

	NSDictionary *source = @{@"name": @"alice", @"age": @30};
	[table addRowWithDataForFieldKeys:source];

	MAD_PASS([table numberOfRows] == (NSUInteger)1, "one row");

	NSDictionary *row = [table allObjects].firstObject;
	MAD_PASS_EQUAL(row[@"name"], @"alice", "the name value");
	MAD_PASS_EQUAL(row[@"age"], @30, "the age value");
	MAD_PASS(row[@"~rowid~"] == nil, "no row id stamp");
	MAD_PASS(row == source, "The caller's dictionary is stored by reference.");

	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"alice", "the normalized first column");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @30, "the normalized second column");
	regressionTearDown();
}

/// CONTRACT: a missing field is defaulted to an empty string in the backing column,
/// but is simply absent from the row dictionary kept in the sort index.
static void testVirtualTableAddRowWithDataForFieldKeysDefaultsMissingColumnOnly(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);

	[table addRowWithDataForFieldKeys:@{@"age": @30}];

	NSDictionary *row = [table allObjects].firstObject;
	MAD_PASS(row[@"name"] == nil, "the missing key stays absent from the dictionary");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"", "the missing column defaults to the empty string");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @30, "the present column carries its value");
	regressionTearDown();
}

static void testVirtualTableObjectEnumerator(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];
	[table addRow:@[@"bob", @20] error:&error];

	NSMutableArray *names = [[NSMutableArray alloc] init];
	NSEnumerator *enumerator = [table objectEnumerator];
	NSDictionary *row;
	while ((row = [enumerator nextObject]) != nil) {
		[names addObject:row[@"name"]];
	}
	MAD_PASS_EQUAL(names, (@[@"alice", @"bob"]), "the enumerated names, in order");
	regressionTearDown();
}

static void testVirtualTableFastEnumerationYieldsIndexedRows(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];
	[table addRow:@[@"bob", @20] error:&error];

	NSMutableArray *names = [[NSMutableArray alloc] init];
	for (NSDictionary *row in table) {
		[names addObject:row[@"name"]];
	}
	MAD_PASS_EQUAL(names, (@[@"alice", @"bob"]), "the fast-enumerated names, in order");
	regressionTearDown();
}

static void testVirtualTableSubscriptingReturnsRow(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];

	// -objectAtIndexedSubscript: is declared on MADDataTableVirtual, so this is
	// now reachable through the public API without a cast.
	MAD_PASS_EQUAL(table[0][@"name"], @"alice", "the subscripted row");
	regressionTearDown();
}

#pragma mark - MADDataTableVirtual: sorting

/// Sorting permutes the index (sortIndex) but never the backing MADDataColumns.
/// -sortedIndexForIndex: then maps a sorted row position back through the index,
/// so -objectAtRow:column: answers from the columns at that mapped position.  When
/// the sort permutation happens to be its own inverse the two views agree by
/// coincidence; otherwise they disagree.  The rows below use a 3-cycle so the
/// disagreement is deterministic.
static void testVirtualTableSortDesynchronizesRowAndColumnViews(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];	// insertion index 0
	[table addRow:@[@"bob", @10] error:&error];	// insertion index 1
	[table addRow:@[@"carol", @20] error:&error];	// insertion index 2

	// Before sorting the two views agree.
	MAD_PASS_EQUAL([table objectAtRow:0][@"name"], @"alice", "the unsorted row view");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"alice", "the unsorted column view");

	[table sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:YES]]];

	// -allObjects reflects the sort: bob(10), carol(20), alice(30).
	NSArray <NSDictionary *> *all = [table allObjects];
	MAD_PASS_EQUAL(all[0][@"name"], @"bob", "the sorted first row");
	MAD_PASS_EQUAL(all[1][@"name"], @"carol", "the sorted second row");
	MAD_PASS_EQUAL(all[2][@"name"], @"alice", "the sorted third row");

	// -objectAtRow: agrees with -allObjects ...
	MAD_PASS_EQUAL([table objectAtRow:0][@"name"], @"bob", "row 0 agrees with allObjects");
	MAD_PASS_EQUAL([table objectAtRow:1][@"name"], @"carol", "row 1 agrees with allObjects");
	MAD_PASS_EQUAL([table objectAtRow:2][@"name"], @"alice", "row 2 agrees with allObjects");

	// ... but -objectAtRow:column: indexes the unsorted columns with the sorted
	// position, producing a different answer for the same row.
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"carol", "the column view desynchronizes at row 0");
	MAD_PASS_EQUAL([table objectAtRow:1 column:0], @"alice", "the column view desynchronizes at row 1");
	MAD_PASS_EQUAL([table objectAtRow:2 column:0], @"bob", "the column view desynchronizes at row 2");
	regressionTearDown();
}

#pragma mark - MADDataTableVirtual: plist / cache round trip

static void testVirtualTablePlistRoundTrip(void) {
	regressionSetUp();
	MADDataTableVirtual *source = newVirtualTableWithTag(5);
	NSError *error = nil;
	[source addRow:@[@"alice", @30] error:&error];
	[source addRow:@[@"bob", @20] error:&error];
	source.name = @"people";

	NSDictionary *plist = [source copyPlist];

	MADDataTableVirtual *restored = [[MADDataTableVirtual alloc] initWithId:5];
	NSError *loadError = nil;
	MAD_PASS([restored loadWithPlist:plist error:&loadError], "loadWithPlist failed: %s", [[loadError description] UTF8String]);
	MAD_PASS(loadError == nil, "the load reports no error");

	MAD_PASS_EQUAL(restored.name, @"people", "the name survives the plist");
	MAD_PASS([restored numberOfRows] == (NSUInteger)2, "two rows survive the plist");
	MAD_PASS([restored numberOfColumns] == (NSUInteger)2, "two columns survive the plist");
	MAD_PASS_EQUAL([restored allObjects], [source allObjects], "the rows survive the plist");
	regressionTearDown();
}

static void testVirtualTableCacheAndReloadFromDisk(void) {
	regressionSetUp();
	MADDataTableVirtual *source = newVirtualTableWithTag(11);
	NSError *error = nil;
	[source addRow:@[@"alice", @30] error:&error];
	[source addRow:@[@"bob", @20] error:&error];
	source.name = @"people";

	NSURL *url = [gRegressionCacheDirectory URLByAppendingPathComponent:[source newFilenameMDCache]];
	NSError *cacheError = nil;
	MAD_PASS([source cacheWithUrl:url error:&cacheError], "cacheWithUrl failed: %s", [[cacheError description] UTF8String]);
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath:url.path], "the cache file is written");

	// -loadFromCacheWithUrl: reads through +propertyListWithStream:, which
	// GNUstep implements as a stub; the shim in Linux/Compat reads the stream
	// and defers to +propertyListWithData:, so the path runs on both platforms
	// and is asserted on both.
	MADDataTableVirtual *restored = [[MADDataTableVirtual alloc] initWithId:11];
	NSError *loadError = nil;
	MAD_PASS([restored loadFromCacheWithUrl:url error:&loadError], "loadFromCache failed: %s", [[loadError description] UTF8String]);
	MAD_PASS_EQUAL(restored.name, @"people", "the name survives the cache");
	MAD_PASS_EQUAL([restored allObjects], [source allObjects], "the rows survive the cache");

	// MADDataTableVirtual reloads its sort index from the same plist it wrote.
	MAD_PASS_EQUAL([restored objectAtRow:0][@"name"], @"alice", "the first row survives the cache");
	regressionTearDown();
}

static void testVirtualTableRemoveAllObjectsClearsColumnsAndRows(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(1);
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];

	[table removeAllObjects];

	MAD_PASS([table numberOfRows] == (NSUInteger)0, "no rows are left");
	MAD_PASS([table numberOfColumns] == (NSUInteger)0, "no columns are left");
	MAD_PASS_EQUAL([table allObjects], @[], "no objects are left");
	MAD_PASS(table.columns.count == (NSUInteger)0, "the columns dictionary is cleared");
	MAD_PASS(table.columnKeys.count == (NSUInteger)0, "the column keys are cleared");
	regressionTearDown();
}

#pragma mark - MADDataTableVirtual: unimplemented surface

/// MADDataTableVirtual deliberately does not implement the sqlite-oriented API.
/// It asserts rather than returning empty results; this test records that the
/// methods exist so a refactor does not quietly turn them into silent no-ops.
static void testVirtualTableDoesNotImplementSortedEnumerators(void) {
	regressionSetUp();
	MADDataTableVirtual *table = [[MADDataTableVirtual alloc] initWithId:1];

	MAD_PASS([table respondsToSelector:@selector(enumeratorForAllObjectsSorted)], "the sorted enumerator exists");
	MAD_PASS([table respondsToSelector:@selector(enumeratorForAllObjectsSortedRowIdOnly)], "the row-id enumerator exists");
	MAD_PASS([table respondsToSelector:@selector(enumeratorForKeyObjectsSorted)], "the key enumerator exists");
	MAD_PASS([table respondsToSelector:@selector(objectsForGroupKeys:)], "the group-key lookup exists");

	// The implementations are NSAssert(NO, ...) stubs.  NSAssert is compiled out of
	// Release, so the assertions below are only meaningful in a Debug test run.
#if defined(DEBUG) && DEBUG
	MAD_THROWS_NAMED([table enumeratorForAllObjectsSorted], @"NSInternalInconsistencyException", "the sorted enumerator asserts");
	MAD_THROWS_NAMED([table enumeratorForKeyObjectsSorted], @"NSInternalInconsistencyException", "the key enumerator asserts");
	MAD_THROWS_NAMED([table objectsForGroupKeys:@[]], @"NSInternalInconsistencyException", "the group-key lookup asserts");
#endif
	regressionTearDown();
}

#pragma mark - MADDataTable+Constructor

static void testConstructorVirtualType(void) {
	regressionSetUp();
	MADDataTable *table = [MADDataTable newDataTableOfType:MADDataTableTypeVirtual withObjectID:77];

	MAD_PASS([table isKindOfClass:[MADDataTableVirtual class]], "the virtual type builds a virtual table");
	MAD_PASS(![table isKindOfClass:[MADDataTableFast class]], "the virtual type is not a fast table");
	MAD_PASS(table.tag == (NSUInteger)77, "the object id becomes the tag");
	regressionTearDown();
}

static void testConstructorPhysicalType(void) {
	regressionSetUp();
	MADDataTable *table = [MADDataTable newDataTableOfType:MADDataTableTypePhysical withObjectID:77];

	MAD_PASS([table isKindOfClass:[MADDataTableFast class]], "the physical type builds a fast table");
	MAD_PASS(table.tag == (NSUInteger)77, "the object id becomes the tag");
	regressionTearDown();
}

static void testConstructorFromDefinitionWithTypeAndIdentifier(void) {
	regressionSetUp();
	NSDictionary *definition = @{
		@(MADDataTableParametersType): @(MADDataTableTypePhysical),
		@(MADDataTableParametersIdentifier): @(88)
	};

	MADDataTable *table = [MADDataTable newDataTableWithDefinition:definition];

	MAD_PASS([table isKindOfClass:[MADDataTableFast class]], "the definition's type is honoured");
	MAD_PASS(table.tag == (NSUInteger)88, "the definition's identifier becomes the tag");
	regressionTearDown();
}

/// CONTRACT: with an identifier but no explicit type the constructor falls back to
/// the virtual (in-memory) table.
static void testConstructorFromDefinitionWithoutTypeDefaultsToVirtual(void) {
	regressionSetUp();
	NSDictionary *definition = @{
		@(MADDataTableParametersIdentifier): @(99)
	};

	MADDataTable *table = [MADDataTable newDataTableWithDefinition:definition];

	MAD_PASS([table isKindOfClass:[MADDataTableVirtual class]], "the default type is virtual");
	MAD_PASS(table.tag == (NSUInteger)99, "the definition's identifier becomes the tag");
	regressionTearDown();
}

static void testConstructorForIdentifierProducesVirtualTable(void) {
	regressionSetUp();
	MADDataTable *table = [MADDataTable newDataTableForIdentifier:@"customers"];

	MAD_PASS([table isKindOfClass:[MADDataTableVirtual class]], "an identifier builds a virtual table");
	MAD_PASS(table.tag == (NSUInteger)@"customers".hash, "the identifier's hash becomes the tag");
	regressionTearDown();
}

#pragma mark - MADDataTableFast: metadata and construction

static void testFastTableInitDefaults(void) {
	regressionSetUp();
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:321];

	MAD_PASS(table.tag == (NSUInteger)321, "the id becomes the tag");
	MAD_PASS([table numberOfRows] == (NSUInteger)0, "no rows");
	MAD_PASS([table numberOfColumns] == (NSUInteger)0, "no columns");
	MAD_PASS_EQUAL([table tableName], @"t321", "the table name is t plus the id");
	regressionTearDown();
}

/// A caller with a directory but no cache delegate must still be able to build a
/// working physical table.  This is what -initWithId:cacheDirectory: is for: without
/// it the table reaches for [MADApplication AppDelegate], which a logic test has not
/// got.  No delegate is set here on purpose.
static void testFastTableInitWithCacheDirectoryNeedsNoDelegate(void) {
	regressionSetUp();
	const NSUInteger tag = 555;
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:tag cacheDirectory:gRegressionCacheDirectory];

	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;
	[table addColumn:name];

	bulkInsertRows(@[@[@"alice"], @[@"bob"]], table);

	MAD_PASS([table numberOfRows] == (NSUInteger)2, "both rows land");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"alice", "the first value reads back");

	// The cache file belongs to the directory we handed over, not to any app default.
	NSArray <NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:gRegressionCacheDirectory.path
																						   error:NULL];
	NSString *stem = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)tag];
	BOOL foundCacheFile = NO;
	for (NSString *name in contents) {
		if ([name hasPrefix:stem]) { foundCacheFile = YES; break; }
	}
	MAD_PASS(foundCacheFile, "no cache file for tag %s in %s", stem.UTF8String, contents.description.UTF8String);
	regressionTearDown();
}

static void testFastTableColumnNamesAreHashedIdentifiers(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(5);

	MAD_PASS([table numberOfColumns] == (NSUInteger)2, "two columns");

	NSString *expectedName = [[NSString alloc] initWithFormat:@"c%lu", (unsigned long)@"name".hash];
	NSString *expectedAge  = [[NSString alloc] initWithFormat:@"c%lu", (unsigned long)@"age".hash];

	MAD_PASS_EQUAL(table.columnKeys, (@[expectedName, expectedAge]), "the hashed column keys");
	MAD_PASS_EQUAL([table columnKeyForColumnName:@"name"], expectedName, "the name column key");
	MAD_PASS_EQUAL([table columnKeyForColumnName:@"age"], expectedAge, "the age column key");
	MAD_PASS([table columnKeyForColumnName:@"missing"] == nil, "an unknown column has no key");
	regressionTearDown();
}

static void testFastTableNumberOfColumnsTracksColumnKeys(void) {
	regressionSetUp();
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:6];
	gRegressionCacheDelegate.dataTable = table;
	table.cacheDelegate = gRegressionCacheDelegate;
	MAD_PASS([table numberOfColumns] == (NSUInteger)0, "no columns to start");

	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;
	[table addColumn:name];

	MAD_PASS([table numberOfColumns] == (NSUInteger)1, "the column is counted");
	MAD_PASS([table objectEnumerator] != nil, "the object enumerator exists");
	MAD_PASS([table enumeratorForAllObjectsSorted] != nil, "the sorted enumerator exists");
	MAD_PASS([table objectEnumerator].class == NSClassFromString(MADDataTableObjectEnumeratorClassName),
			 "the object enumerator is the object-enumerator class");
	regressionTearDown();
}

static void testFastTableObjectEnumeratorIsNilWithoutColumns(void) {
	regressionSetUp();
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7];
	table.cacheDelegate = gRegressionCacheDelegate;

	MAD_PASS([table objectEnumerator] == nil, "no columns means no enumerator");
	regressionTearDown();
}

#pragma mark - MADDataTableFast: bulk insert round trip

static void testFastTableBulkInsertRowCount(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(100);
	MAD_PASS([table numberOfRows] == (NSUInteger)0, "no rows to start");

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20], @[@"carol", @40]], table);

	MAD_PASS([table numberOfRows] == (NSUInteger)3, "three rows");
	MAD_PASS([table count] == (NSUInteger)3, "three counted rows");
	MAD_PASS([table rowCounter] == (NSUInteger)3, "the row counter advanced three times");
	regressionTearDown();
}

/// The plist carries the row counter but not the rows -- those are in the cache
/// file.  A counter that disagrees with the file must not survive a reload.
static void testFastTableReloadRecountsRowsFromCacheFile(void) {
	regressionSetUp();
	MADDataTableFast *source = newFastTableWithTag(1001);
	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20], @[@"carol", @40]], source);

	NSMutableDictionary *plist = [[source copyPlist] mutableCopy];
	// "rowCounter" mirrors +[MADDataTable keyRowCounter]; the key methods are private.
	MAD_PASS_EQUAL(plist[@"rowCounter"], @3, "the plist carries the row counter");
	plist[@"rowCounter"] = @99;

	// The plist names the cache file but not its directory -- that is the format fix --
	// so the reloaded table is told where its cache lives, as a caller loading from
	// disk would be.
	MADDataTableFast *restored = [[MADDataTableFast alloc] initWithId:1001 cacheDirectory:gRegressionCacheDirectory];
	NSError *loadError = nil;
	MAD_PASS([restored loadWithPlist:plist error:&loadError], "loadWithPlist failed: %s", [[loadError description] UTF8String]);

	MAD_PASS([restored numberOfRows] == (NSUInteger)3, "the rows are recounted from the file");
	MAD_PASS([restored count] == (NSUInteger)3, "the count is recounted from the file");
	MAD_PASS([restored rowCounter] == (NSUInteger)3, "the stale plist counter is replaced");
	regressionTearDown();
}

static void testFastTableDropTableZeroesRowCount(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(1101);
	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);
	MAD_PASS([table count] == (NSUInteger)2, "two rows before the drop");

	[table reopenDbConnection];
	[table dropTable];

	// The rows are gone from the file, so the counter must not outlive them: the app
	// reads -count as a page cursor (hasMore = count == limit).
	MAD_PASS([table count] == (NSUInteger)0, "the count is zeroed");
	MAD_PASS([table numberOfRows] == (NSUInteger)0, "the row count is zeroed");
	MAD_PASS([table rowCounter] == (NSUInteger)0, "the row counter is zeroed");
	regressionTearDown();
}

static void testFastTableDropForeignTableKeepsRowCount(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(1102);
	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	// -dropTableName: takes any name, and dropping a table that is not this one
	// must leave this table's rows and count alone.
	[table reopenDbConnection];
	[table dropTableName:@"some_other_table"];

	MAD_PASS([table count] == (NSUInteger)2, "the count is untouched");
	regressionTearDown();
}

static void testFastTableDeleteAllZeroesRowCount(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(1103);
	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	[table reopenDbConnection];
	[table deleteAll];

	MAD_PASS([table count] == (NSUInteger)0, "the count is zeroed");
	MAD_PASS([table numberOfRows] == (NSUInteger)0, "the row count is zeroed");
	regressionTearDown();
}

static void testFastTableVacuumKeepsRowCount(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(1104);
	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	[table reopenDbConnection];
	[table vacuumCacheDb];

	// VACUUM rewrites the file but keeps every row, so it must not zero the counter.
	MAD_PASS([table count] == (NSUInteger)2, "the count survives the vacuum");
	regressionTearDown();
}

static void testFastTableBulkInsertEnumeratesValues(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(101);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	NSMutableArray <NSString *> *names = [[NSMutableArray alloc] init];
	for (NSDictionary *row in [table objectEnumerator]) {
		[names addObject:row[@"name"]];
	}
	MAD_PASS_EQUAL(names, (@[@"alice", @"bob"]), "the enumerated names, in order");
	regressionTearDown();
}

static void testFastTableObjectEnumeratorYieldsRowId(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(102);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	NSDictionary *first = [[table objectEnumerator] nextObject];
	MAD_PASS_EQUAL(first[@"name"], @"alice", "the first name");
	MAD_PASS_EQUAL(first[@"age"], @30, "the first age");
	MAD_PASS(first[MADIdentifierROWID] != nil, "the row id is present");
	regressionTearDown();
}

/// CONTRACT: the non-bulk -addRow: path stores the values it is given.
/// MADDataTableFast builds its INSERT with "?" placeholders and depends on
/// MADQueryCacheAddRow to populate binaryBindings; that query now creates one
/// binding per column, so sqlite3_step runs with every parameter bound.
static void testFastTableNonBulkAddRowStoresValues(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(120);

	NSError *error = nil;
	MAD_PASS(([table addRow:@[@"alice", @30] error:&error]), "The statement still succeeds.");
	MAD_PASS([table numberOfRows] == (NSUInteger)1, "The row is counted.");

	NSDictionary *row = [[table objectEnumerator] nextObject];
	MAD_PASS(row != nil, "The row is cached and enumerable.");
	MAD_PASS_EQUAL(row[@"name"], @"alice", "the name value");
	MAD_PASS_EQUAL(row[@"age"], @30, "the age value");
	regressionTearDown();
}

/// CONTRACT: a non-bulk insert binds NSNull (not a default) for a value the
/// caller passed as NSNull.
static void testFastTableNonBulkAddRowStoresNullForNullInput(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(122);

	NSError *error = nil;
	MAD_PASS(([table addRow:@[[NSNull null], @7] error:&error]), "the row is added");

	NSDictionary *row = [[table objectEnumerator] nextObject];
	MAD_PASS_EQUAL(row[@"age"], @7, "The bound column still lands.");
	MAD_PASS_EQUAL(row[@"name"], [NSNull null], "a null input stays null");
	regressionTearDown();
}

/// CONTRACT: -dataTableForQuery: is @optional on MADDatabaseResultsProtocol, so a
/// delegate that does not implement it must not break the cache write path.
static void testFastTableWorksWithDelegateThatOmitsOptionalDataTableForQuery(void) {
	regressionSetUp();
	MADDataTableRegressionBareDelegate *bare = [[MADDataTableRegressionBareDelegate alloc] init];
	bare.cachedFilesDirectory = gRegressionCacheDirectory;
	MAD_PASS(![bare respondsToSelector:@selector(dataTableForQuery:)],
			 "The double must not implement the optional method.");

	MADDataTableFast *table = newFastTableWithTagAndDelegate(123, bare);

	MAD_NO_THROW((bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table)), "the bulk insert does not throw");
	MAD_PASS([table numberOfRows] == (NSUInteger)2, "both rows land");
	MAD_PASS([[table objectEnumerator] allObjects].count == (NSUInteger)2, "both rows enumerate");
	regressionTearDown();
}

/// CONTRACT: -allObjects returns every row as a dictionary, in the table's sort
/// order -- the same shape MADDataTableVirtual already returned.
static void testFastTableBulkInsertAllObjectsReturnsEveryRow(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(103);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	// The declaration is `nonnull NSArray *`, so this must never be nil.
	NSArray *all = [table allObjects];
	MAD_PASS(all.count == (NSUInteger)2, "both rows come back");
	MAD_PASS_EQUAL(all[0][@"name"], @"alice", "the first name");
	MAD_PASS_EQUAL(all[1][@"name"], @"bob", "the second name");
	regressionTearDown();
}

/// CONTRACT: -allObjects on a table with no rows is an empty array, not nil.
static void testFastTableAllObjectsIsEmptyWhenThereAreNoRows(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(113);

	MAD_PASS([table allObjects] != nil, "allObjects is never nil");
	MAD_PASS_EQUAL([table allObjects], @[], "allObjects is empty with no rows");
	regressionTearDown();
}

static void testFastTableRowIdEnumeratorReturnsRowIds(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(104);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20], @[@"carol", @40]], table);

	NSMutableArray *rowIds = [[NSMutableArray alloc] init];
	for (id rowId in [table enumeratorForAllObjectsSortedRowIdOnly]) {
		[rowIds addObject:rowId];
	}

	MAD_PASS(rowIds.count == (NSUInteger)3, "three row ids");
	for (id rowId in rowIds) {
		MAD_PASS([rowId isKindOfClass:[NSNumber class]],
				 "Expected NSNumber row id, got %s", NSStringFromClass([rowId class]).UTF8String);
	}
	regressionTearDown();
}

static void testFastTableDataForRowReturnsValues(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(105);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	NSNumber *rowId = nil;
	for (id candidate in [table enumeratorForAllObjectsSortedRowIdOnly]) {
		rowId = candidate;
		break;
	}
	MAD_PASS(rowId != nil, "a row id is found");

	NSError *error = nil;
	NSDictionary *row = [table dataForRow:rowId.unsignedIntegerValue error:&error];

	MAD_PASS(row != nil, "the row comes back");
	MAD_PASS(error == nil, "no error for a valid row id");
	MAD_PASS_EQUAL(row[@"name"], @"alice", "the name value");
	MAD_PASS_EQUAL(row[@"age"], @30, "the age value");
	regressionTearDown();
}

/// CONTRACT: -dataForRow:error: memoizes the last row it fetched and serves the
/// second request for the same row id from that cache.
static void testFastTableDataForRowCachesLastRow(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(106);

	bulkInsertRows(@[@[@"alice", @30]], table);

	NSNumber *rowId = nil;
	for (id candidate in [table enumeratorForAllObjectsSortedRowIdOnly]) {
		rowId = candidate;
		break;
	}

	NSError *error = nil;
	NSDictionary *first = [table dataForRow:rowId.unsignedIntegerValue error:&error];
	NSDictionary *second = [table dataForRow:rowId.unsignedIntegerValue error:&error];

	MAD_PASS_EQUAL(first, second, "the cached row is equal");
	MAD_PASS(!(first == second), "The cached path is expected to return a fresh copy.");
	regressionTearDown();
}

static void testFastTableDataForRowWithUnknownColumnReturnsError(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(107);

	bulkInsertRows(@[@[@"alice", @30]], table);

	NSError *error = nil;
	NSDictionary *row = [table dataForRow:1 column:@"not-a-column" error:&error];

	MAD_PASS(row == nil, "the unknown column yields no row");
	MAD_PASS(error != nil, "an error is reported");
	MAD_PASS(error.code == (NSInteger)8927, "the error code is 8927");
	regressionTearDown();
}

/// CONTRACT: repeated -dataForRow:column:error: reads return identical results.
/// The per-column select is prepared once and rebound per call; the cached
/// statement must serve exactly what a fresh prepare would have.
static void testFastTableDataForRowColumnRepeatedReadsReturnIdenticalResults(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(1140);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	NSError *error = nil;
	NSDictionary *first = [table dataForRow:1 column:@"name" error:&error];
	MAD_PASS(error == nil, "no error on the first read");
	MAD_PASS(first != nil, "the first read returns a row");
	MAD_PASS_EQUAL(first[@"name"], @"alice", "the first name");

	for (NSUInteger index = 0; index < 5; index++) {
		NSDictionary *again = [table dataForRow:1 column:@"name" error:&error];
		MAD_PASS(error == nil, "no error on a repeated read");
		MAD_PASS_EQUAL(again, first, "the repeated read is identical");
	}
	regressionTearDown();
}

/// CONTRACT: a column read after an intervening write returns the new value.  The
/// bulk path reopens both connections and deletes all rows first, so the new row
/// is rowid 1 again -- and the rebuilt table must be read correctly through the
/// column cache, nothing stale.
static void testFastTableDataForRowColumnReflectsInterveningWrite(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(1141);

	bulkInsertRows(@[@[@"alice", @30]], table);

	NSError *error = nil;
	NSDictionary *before = [table dataForRow:1 column:@"name" error:&error];
	MAD_PASS(error == nil, "no error before the write");
	MAD_PASS_EQUAL(before[@"name"], @"alice", "the value before the write");

	bulkInsertRows(@[@[@"zoe", @99]], table);

	NSDictionary *after = [table dataForRow:1 column:@"name" error:&error];
	MAD_PASS(error == nil, "no error after the write");
	MAD_PASS_EQUAL(after[@"name"], @"zoe", "the value after the write");
	regressionTearDown();
}

/// CONTRACT: a cached column statement serves data written by another connection
/// to the same cache file.  A second table on the same cache URL replaces the
/// rows while the first table's prepared select is untouched; the first table's
/// next read must see the replacement, not a stale row.
static void testFastTableDataForRowColumnSeesWritesFromSiblingTable(void) {
	regressionSetUp();
	MADDataTableFast *reader = newFastTableWithTag(1143);

	bulkInsertRows(@[@[@"alice", @30]], reader);

	NSError *error = nil;
	NSDictionary *before = [reader dataForRow:1 column:@"name" error:&error];
	MAD_PASS(error == nil, "no error before the sibling write");
	MAD_PASS_EQUAL(before[@"name"], @"alice", "the value before the sibling write");

	MADDataTableFast *writer = newFastTableWithTag(1143);
	bulkInsertRows(@[@[@"zoe", @99]], writer);

	NSDictionary *after = [reader dataForRow:1 column:@"name" error:&error];
	MAD_PASS(error == nil, "no error after the sibling write");
	MAD_PASS_EQUAL(after[@"name"], @"zoe", "the value after the sibling write");
	regressionTearDown();
}

/// CONTRACT: a rebuilt table is still read correctly through the column cache.
/// Dropping and recreating the table (a refresh replaces the rows) must not leave
/// the cached select serving a stale schema.
static void testFastTableDataForRowColumnSurvivesTableRebuild(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(1142);

	bulkInsertRows(@[@[@"alice", @30]], table);

	NSError *error = nil;
	NSDictionary *before = [table dataForRow:1 column:@"name" error:&error];
	MAD_PASS(error == nil, "no error before the rebuild");
	MAD_PASS_EQUAL(before[@"name"], @"alice", "the value before the rebuild");

	[table removeAllObjects];

	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;
	[table addColumn:name];

	MADDataColumn *age = [[MADDataColumn alloc] initWithIdentifier:@"age"];
	age.type = MADDataTypeInteger;
	[table addColumn:age];

	bulkInsertRows(@[@[@"zoe", @99]], table);

	NSDictionary *after = [table dataForRow:1 column:@"name" error:&error];
	MAD_PASS(error == nil, "no error after the rebuild");
	MAD_PASS_EQUAL(after[@"name"], @"zoe", "the value after the rebuild");
	regressionTearDown();
}

#pragma mark - MADDataTableFast: row access

/// CONTRACT: -objectAtRow:limit: returns the cached rows and agrees with the
/// enumerator.  It used to store the result of `sqlite3_prepare_v2(...) ==
/// SQLITE_OK` in an int and then re-test it against SQLITE_OK, so the row loop
/// only ran when the prepare had *failed*.
static void testFastTableObjectAtRowLimitReturnsCachedRows(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(108);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	NSArray *rows = [table objectAtRow:0 limit:2];
	MAD_PASS(rows.count == (NSUInteger)2, "both rows come back");
	MAD_PASS_EQUAL(rows[0][@"name"], @"alice", "the first name");
	MAD_PASS_EQUAL(rows[0][@"age"], @30, "the first age");
	MAD_PASS_EQUAL(rows[1][@"name"], @"bob", "the second name");
	MAD_PASS_EQUAL(rows[1][@"age"], @20, "the second age");

	// The row accessor and the enumerator must agree.
	MAD_PASS_EQUAL([table objectEnumerator].allObjects, rows, "the row accessor agrees with the enumerator");
	regressionTearDown();
}

static void testFastTableObjectAtRowReturnsRow(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(109);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	NSDictionary *first = [table objectAtRow:0];
	MAD_PASS(first.count == (NSUInteger)3, "Two columns plus ~rowid~.");
	MAD_PASS_EQUAL(first[@"name"], @"alice", "the first name");
	MAD_PASS_EQUAL(first[@"age"], @30, "the first age");

	NSDictionary *second = [table objectAtRow:1];
	MAD_PASS_EQUAL(second[@"name"], @"bob", "the second name");
	MAD_PASS_EQUAL(second[@"age"], @20, "the second age");
	regressionTearDown();
}

static void testFastTableObjectAtRowOutOfRangeReturnsEmpty(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(110);

	bulkInsertRows(@[@[@"alice", @30]], table);

	MAD_PASS([table objectAtRow:5 limit:1].count == (NSUInteger)0, "a row past the end is empty");
	MAD_PASS([table objectAtRow:0 limit:0].count == (NSUInteger)0, "A zero limit short-circuits.");
	regressionTearDown();
}

/// CONTRACT: -objectAtRow:column: returns the value stored in the requested
/// column at the requested row.  It used to answer from column 0 for every
/// index.
static void testFastTableObjectAtRowColumnReturnsTheRequestedColumn(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(112);

	MADDataColumn *role = [[MADDataColumn alloc] initWithIdentifier:@"role"];
	role.type = MADDataTypeString;
	[table addColumn:role];

	bulkInsertRows(@[@[@"Alice", @30, @"Engineer"]], table);

	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"Alice", "the first column");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @30, "the second column");
	MAD_PASS_EQUAL([table objectAtRow:0 column:2], @"Engineer", "the third column");
	regressionTearDown();
}

/// CONTRACT: the column index is bounds checked.
static void testFastTableObjectAtRowColumnOutOfBoundsReturnsNil(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(113);

	bulkInsertRows(@[@[@"Alice", @30], @[@"Bob", @20]], table);

	MAD_PASS([table numberOfColumns] == (NSUInteger)2, "two columns");

	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"Alice", "the valid column read");
	MAD_PASS([table objectAtRow:0 column:2] == nil, "One past the last column.");
	MAD_PASS([table objectAtRow:0 column:NSNotFound] == nil, "NSNotFound column is nil");
	MAD_PASS([table objectAtRow:9 column:0] == nil, "Row out of range.");
	regressionTearDown();
}

/// CONTRACT: -objectAtRow:column: agrees with the dictionaries the row accessors
/// return, for every column.
static void testFastTableObjectAtRowColumnAgreesWithRowDictionaries(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(114);

	bulkInsertRows(@[@[@"Alice", @30], @[@"Bob", @20]], table);

	NSArray <NSString *> *fieldNames = @[@"name", @"age"];
	for (NSUInteger row = 0; row < 2; row++) {
		NSDictionary *rowDictionary = [table objectAtRow:row];
		for (NSUInteger column = 0; column < fieldNames.count; column++) {
			MAD_PASS_EQUAL([table objectAtRow:row column:column],
						   rowDictionary[fieldNames[column]],
						   "row %lu column %lu", (unsigned long)row, (unsigned long)column);
		}
	}
	regressionTearDown();
}

#pragma mark - MADDataTableFast: mutation

static void testFastTableRemoveAllObjectsDropsRowsAndColumns(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(111);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);
	MAD_PASS([table numberOfRows] == (NSUInteger)2, "two rows before the clear");

	[table removeAllObjects];

	MAD_PASS([table numberOfRows] == (NSUInteger)0, "no rows after the clear");
	MAD_PASS([table numberOfColumns] == (NSUInteger)0, "no columns after the clear");
	MAD_PASS(table.columnKeys.count == (NSUInteger)0, "the column keys are cleared");
	MAD_PASS(table.columns.count == (NSUInteger)0, "the columns are cleared");
	regressionTearDown();
}

static void testFastTableSortUsingDescriptorsRecordsGroupKeys(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(112);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	[table sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:YES]]];

	// The public sortDescriptors are rewritten to use the internal column keys.
	MAD_PASS(table.sortDescriptors.count == (NSUInteger)1, "one sort descriptor is recorded");
	NSString *expectedAge = [[NSString alloc] initWithFormat:@"c%lu", (unsigned long)@"age".hash];
	MAD_PASS_EQUAL(table.sortDescriptors.firstObject.key, expectedAge, "the sort descriptor uses the internal column key");
	regressionTearDown();
}

static void testFastTableEnumeratorForAllObjectsSorted(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(113);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	NSMutableArray <NSString *> *names = [[NSMutableArray alloc] init];
	for (NSDictionary *row in [table enumeratorForAllObjectsSorted]) {
		[names addObject:row[@"name"]];
	}
	MAD_PASS(names.count == (NSUInteger)2, "two rows are enumerated");
	MAD_PASS([names containsObject:@"alice"], "alice is enumerated");
	MAD_PASS([names containsObject:@"bob"], "bob is enumerated");
	regressionTearDown();
}

#pragma mark - Enumerators used directly

/// CONTRACT: both enumerator classes build their own MADDatabaseSqlite3 connection
/// from the connection they are handed, so an enumerator can outlive the table it
/// came from.  Enumerating twice from the same enumerator replays the result set
/// (the statement is reset when fast enumeration restarts, and -allObjects drains).
static void testObjectEnumeratorReplaysResults(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(120);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	NSEnumerator *enumerator = [table objectEnumerator];
	MAD_PASS(enumerator.class == NSClassFromString(MADDataTableObjectEnumeratorClassName),
			 "the enumerator is the object-enumerator class");

	NSUInteger firstPass = 0;
	for (NSDictionary *row in enumerator) {
		MAD_PASS(row[@"name"] != nil, "the first pass yields a name");
		firstPass++;
	}
	MAD_PASS(firstPass == (NSUInteger)2, "the first pass yields two rows");

	NSUInteger secondPass = 0;
	for (NSDictionary *row in enumerator) {
		MAD_PASS(row[@"name"] != nil, "the second pass yields a name");
		secondPass++;
	}
	MAD_PASS(secondPass == (NSUInteger)2, "the second pass replays two rows");
	regressionTearDown();
}

static void testSingleColumnEnumeratorIsUsedForRowIds(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(121);

	bulkInsertRows(@[@[@"alice", @30]], table);

	NSEnumerator *enumerator = [table enumeratorForAllObjectsSortedRowIdOnly];
	MAD_PASS(enumerator.class == NSClassFromString(MADDataTableSingleColumnEnumeratorClassName),
			 "the enumerator is the single-column class");

	NSMutableArray *values = [[NSMutableArray alloc] init];
	for (id value in enumerator) {
		[values addObject:value];
	}
	MAD_PASS(values.count == (NSUInteger)1, "one value is enumerated");
	MAD_PASS([values.firstObject isKindOfClass:[NSNumber class]], "the value is a number");
	regressionTearDown();
}

static void testEnumeratorAllObjectsReturnsEveryRow(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(122);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20], @[@"carol", @40]], table);

	NSEnumerator *enumerator = [table objectEnumerator];
	NSArray *all = [enumerator allObjects];

	MAD_PASS(all.count == (NSUInteger)3, "all three rows are drained");
	regressionTearDown();
}

#pragma mark - Threading

/// Concurrent readers of a quiescent MADDataTableVirtual are safe: nothing mutates
/// the backing containers while the reads happen.
static void testVirtualTableConcurrentReadsAreConsistent(void) {
	regressionSetUp();
	MADDataTableVirtual *table = newVirtualTableWithTag(200);
	NSError *error = nil;
	for (NSUInteger i = 0; i < 100; i++) {
		[table addRow:@[[[NSString alloc] initWithFormat:@"name-%lu", (unsigned long)i], @(i)] error:&error];
	}

	dispatch_queue_t queue = dispatch_get_global_queue(MADRegressionQueuePriority, 0);
	dispatch_apply(8, queue, ^(size_t iteration) {
		for (NSUInteger row = 0; row < 100; row++) {
			NSDictionary *fetched = [table objectAtRow:row];
			MAD_PASS_EQUAL(fetched[@"age"], @(row), "the row view is consistent across readers");
			MAD_PASS_EQUAL([table objectAtRow:row column:1], @(row), "the column view is consistent across readers");
		}
		__block NSUInteger counted = 0;
		for (NSDictionary *row in table) {
			MAD_PASS(row[@"name"] != nil, "a concurrent read sees a name");
			counted++;
		}
		MAD_PASS(counted == (NSUInteger)100, "a concurrent read sees every row");
	});
	regressionTearDown();
}

/// Every enumerator returned by MADDataTableFast opens its own database
/// connection, which is what makes concurrent enumeration safe.
static void testFastTableConcurrentEnumeratorsAreIndependent(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(201);
	NSMutableArray *rows = [[NSMutableArray alloc] init];
	for (NSUInteger i = 0; i < 50; i++) {
		[rows addObject:@[[[NSString alloc] initWithFormat:@"name-%lu", (unsigned long)i], @(i)]];
	}
	bulkInsertRows(rows, table);

	dispatch_queue_t queue = dispatch_get_global_queue(MADRegressionQueuePriority, 0);
	dispatch_apply(6, queue, ^(size_t iteration) {
		NSUInteger counted = 0;
		for (NSDictionary *row in [table objectEnumerator]) {
			MAD_PASS(row[@"name"] != nil, "a concurrent enumerator sees a name");
			counted++;
		}
		MAD_PASS(counted == (NSUInteger)50, "a concurrent enumerator sees every row");
	});
	regressionTearDown();
}

/// CONTRACT: MADDataTableFast serializes -addRow: on its own bulk-insert queue, so
/// writers may come from any queue without losing rows.  This test uses the app's
/// serial-queue pattern; -testFastTableConcurrentWritersLoseNoRows covers the
/// concurrent case.
static void testFastTableSerializedConcurrentWritesLoseNoRows(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(202);

	const NSUInteger writers = 4;
	const NSUInteger rowsPerWriter = 25;

	[table beginBulkInsert];

	dispatch_queue_t serial = dispatch_queue_create("MADDataTableRegression.writes", DISPATCH_QUEUE_SERIAL);
	dispatch_group_t group = dispatch_group_create();
	for (NSUInteger writer = 0; writer < writers; writer++) {
		dispatch_group_async(group, serial, ^{
			for (NSUInteger row = 0; row < rowsPerWriter; row++) {
				NSString *name = [[NSString alloc] initWithFormat:@"w%lu-r%lu", (unsigned long)writer, (unsigned long)row];
				NSError *error = nil;
				BOOL success = [table addRow:@[name, @(row)] error:&error];
				MAD_PASS(success, "addRow: failed: %s", [[error description] UTF8String]);
			}
		});
	}
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

	[table endBulkInsert];

	MAD_PASS([table numberOfRows] == writers * rowsPerWriter, "every serialized write lands");

	// Reads after the writers stop must observe every row.
	NSUInteger counted = 0;
	for (NSDictionary *row in [table objectEnumerator]) {
		MAD_PASS(row[@"name"] != nil, "a read after the writers sees a name");
		counted++;
	}
	MAD_PASS(counted == writers * rowsPerWriter, "a read after the writers sees every row");
	regressionTearDown();
}

/// -addRow: runs under the same serial queue -endBulkInsert uses as a barrier, so
/// writers racing each other still land one at a time and none are dropped.
static void testFastTableConcurrentWritersLoseNoRows(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(204);

	const NSUInteger writers = 4;
	const NSUInteger rowsPerWriter = 25;

	[table beginBulkInsert];

	dispatch_queue_t concurrent = dispatch_queue_create("MADDataTableRegression.concurrentWrites",
														DISPATCH_QUEUE_CONCURRENT);
	dispatch_group_t group = dispatch_group_create();
	for (NSUInteger writer = 0; writer < writers; writer++) {
		dispatch_group_async(group, concurrent, ^{
			for (NSUInteger row = 0; row < rowsPerWriter; row++) {
				NSString *name = [[NSString alloc] initWithFormat:@"w%lu-r%lu", (unsigned long)writer, (unsigned long)row];
				NSError *error = nil;
				BOOL success = [table addRow:@[name, @(row)] error:&error];
				MAD_PASS(success, "addRow: failed: %s", [[error description] UTF8String]);
			}
		});
	}
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

	[table endBulkInsert];

	MAD_PASS([table numberOfRows] == writers * rowsPerWriter, "every racing write lands");

	NSUInteger counted = 0;
	for (NSDictionary *row in [table objectEnumerator]) {
		MAD_PASS(row[@"name"] != nil, "a read after the racing writers sees a name");
		counted++;
	}
	MAD_PASS(counted == writers * rowsPerWriter, "a read after the racing writers sees every row");
	regressionTearDown();
}

/// CONTRACT: reads and writes must not overlap.  The table opens a separate
/// read-only-handle for selects, but a write transaction in flight is not
/// coordinated with readers by this class.  This test records the supported
/// sequencing: fill, then read.
static void testFastTableReadsAfterWritesComplete(void) {
	regressionSetUp();
	MADDataTableFast *table = newFastTableWithTag(203);

	bulkInsertRows(@[@[@"alice", @30], @[@"bob", @20]], table);

	dispatch_queue_t queue = dispatch_get_global_queue(MADRegressionQueuePriority, 0);
	dispatch_apply(4, queue, ^(size_t iteration) {
		NSMutableArray <NSString *> *names = [[NSMutableArray alloc] init];
		for (NSDictionary *row in [table objectEnumerator]) {
			[names addObject:row[@"name"]];
		}
		MAD_PASS(names.count == (NSUInteger)2, "a reader sees both rows");
		MAD_PASS([names containsObject:@"alice"], "a reader sees alice");
		MAD_PASS([names containsObject:@"bob"], "a reader sees bob");
	});
	regressionTearDown();
}

MAD_TEST_MAIN("MADDataTableRegressionTests",
	MAD_TEST(testBaseTableInitDefaults),
	MAD_TEST(testBaseTableInitWithIdSetsTag),
	MAD_TEST(testBaseTableEmptyReadAnswers),
	MAD_TEST(testBaseTableAbstractOperationsAssert),
	MAD_TEST(testBaseTableNewFilenameMDCacheUsesTag),
	MAD_TEST(testBaseTableLoadFromCacheWithMissingFileReturnsError),
	MAD_TEST(testBaseTableLoadFromCacheWithMissingFileAndNullErrorReturnsNo),
	MAD_TEST(testBaseTableLoadFromCacheWithInvalidPlistAndNullErrorReturnsNo),
	MAD_TEST(testBaseTableLoadFromCacheWithNilUrlThrows),
	MAD_TEST(testVirtualTableStartsEmpty),
	MAD_TEST(testVirtualTableAddColumnRecordsKeyAndMetadata),
	MAD_TEST(testVirtualTableAddRowBuildsIndexedDictionary),
	MAD_TEST(testVirtualTableAddRowStampsMonotonicRowIds),
	MAD_TEST(testVirtualTableObjectAtRowAndColumn),
	MAD_TEST(testVirtualTableObjectAtRowOutOfBoundsReturnsNil),
	MAD_TEST(testVirtualTableDataForRowReturnsTheRowAtThatIndex),
	MAD_TEST(testVirtualTableDataForRowOutOfBoundsReportsAnError),
	MAD_TEST(testVirtualTableAddRowWiderThanColumnsRaises),
	MAD_TEST(testVirtualTableAddRowWithDataForFieldKeysStoresCallerDictionary),
	MAD_TEST(testVirtualTableAddRowWithDataForFieldKeysDefaultsMissingColumnOnly),
	MAD_TEST(testVirtualTableObjectEnumerator),
	MAD_TEST(testVirtualTableFastEnumerationYieldsIndexedRows),
	MAD_TEST(testVirtualTableSubscriptingReturnsRow),
	MAD_TEST(testVirtualTableSortDesynchronizesRowAndColumnViews),
	MAD_TEST(testVirtualTablePlistRoundTrip),
	MAD_TEST(testVirtualTableCacheAndReloadFromDisk),
	MAD_TEST(testVirtualTableRemoveAllObjectsClearsColumnsAndRows),
	MAD_TEST(testVirtualTableDoesNotImplementSortedEnumerators),
	MAD_TEST(testConstructorVirtualType),
	MAD_TEST(testConstructorPhysicalType),
	MAD_TEST(testConstructorFromDefinitionWithTypeAndIdentifier),
	MAD_TEST(testConstructorFromDefinitionWithoutTypeDefaultsToVirtual),
	MAD_TEST(testConstructorForIdentifierProducesVirtualTable),
	MAD_TEST(testFastTableInitDefaults),
	MAD_TEST(testFastTableInitWithCacheDirectoryNeedsNoDelegate),
	MAD_TEST(testFastTableColumnNamesAreHashedIdentifiers),
	MAD_TEST(testFastTableNumberOfColumnsTracksColumnKeys),
	MAD_TEST(testFastTableObjectEnumeratorIsNilWithoutColumns),
	MAD_TEST(testFastTableBulkInsertRowCount),
	MAD_TEST(testFastTableReloadRecountsRowsFromCacheFile),
	MAD_TEST(testFastTableDropTableZeroesRowCount),
	MAD_TEST(testFastTableDropForeignTableKeepsRowCount),
	MAD_TEST(testFastTableDeleteAllZeroesRowCount),
	MAD_TEST(testFastTableVacuumKeepsRowCount),
	MAD_TEST(testFastTableBulkInsertEnumeratesValues),
	MAD_TEST(testFastTableObjectEnumeratorYieldsRowId),
	MAD_TEST(testFastTableNonBulkAddRowStoresValues),
	MAD_TEST(testFastTableNonBulkAddRowStoresNullForNullInput),
	MAD_TEST(testFastTableWorksWithDelegateThatOmitsOptionalDataTableForQuery),
	MAD_TEST(testFastTableBulkInsertAllObjectsReturnsEveryRow),
	MAD_TEST(testFastTableAllObjectsIsEmptyWhenThereAreNoRows),
	MAD_TEST(testFastTableRowIdEnumeratorReturnsRowIds),
	MAD_TEST(testFastTableDataForRowReturnsValues),
	MAD_TEST(testFastTableDataForRowCachesLastRow),
	MAD_TEST(testFastTableDataForRowWithUnknownColumnReturnsError),
	MAD_TEST(testFastTableDataForRowColumnRepeatedReadsReturnIdenticalResults),
	MAD_TEST(testFastTableDataForRowColumnReflectsInterveningWrite),
	MAD_TEST(testFastTableDataForRowColumnSeesWritesFromSiblingTable),
	MAD_TEST(testFastTableDataForRowColumnSurvivesTableRebuild),
	MAD_TEST(testFastTableObjectAtRowLimitReturnsCachedRows),
	MAD_TEST(testFastTableObjectAtRowReturnsRow),
	MAD_TEST(testFastTableObjectAtRowOutOfRangeReturnsEmpty),
	MAD_TEST(testFastTableObjectAtRowColumnReturnsTheRequestedColumn),
	MAD_TEST(testFastTableObjectAtRowColumnOutOfBoundsReturnsNil),
	MAD_TEST(testFastTableObjectAtRowColumnAgreesWithRowDictionaries),
	MAD_TEST(testFastTableRemoveAllObjectsDropsRowsAndColumns),
	MAD_TEST(testFastTableSortUsingDescriptorsRecordsGroupKeys),
	MAD_TEST(testFastTableEnumeratorForAllObjectsSorted),
	MAD_TEST(testObjectEnumeratorReplaysResults),
	MAD_TEST(testSingleColumnEnumeratorIsUsedForRowIds),
	MAD_TEST(testEnumeratorAllObjectsReturnsEveryRow),
	MAD_TEST(testVirtualTableConcurrentReadsAreConsistent),
	MAD_TEST(testFastTableConcurrentEnumeratorsAreIndependent),
	MAD_TEST(testFastTableSerializedConcurrentWritesLoseNoRows),
	MAD_TEST(testFastTableConcurrentWritersLoseNoRows),
	MAD_TEST(testFastTableReadsAfterWritesComplete));
