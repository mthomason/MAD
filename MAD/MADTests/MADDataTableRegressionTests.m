//
//  MADDataTableRegressionTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization ("lock down the current behaviour") tests for MADDataTable and
//  its derivatives.  These tests intentionally record how the code behaves TODAY,
//  including quirks, so that the pending refactor can be proven behaviour preserving.
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

#import <XCTest/XCTest.h>

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

#import "MADDataTable+Constructor.h"

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
@property (nonatomic, weak) MADDataTable *dataTable;

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

#pragma mark - Tests

@interface MADDataTableRegressionTests : XCTestCase

@property (nonatomic, strong) MADDataTableRegressionCacheDelegate *cacheDelegate;
@property (nonatomic, strong) NSURL *cacheDirectory;

@end

@implementation MADDataTableRegressionTests

#pragma mark - Fixtures

- (void)setUp {
	[super setUp];

	NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory()]
						URLByAppendingPathComponent:[NSString stringWithFormat:@"MADDataTableRegression-%@",
													 [[NSUUID UUID] UUIDString]]
						isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:NULL];
	self.cacheDirectory = directory;

	MADDataTableRegressionCacheDelegate *delegate = [[MADDataTableRegressionCacheDelegate alloc] init];
	delegate.cachedFilesDirectory = directory;
	self.cacheDelegate = delegate;
}

- (void)tearDown {
	if (self.cacheDirectory != nil) {
		[[NSFileManager defaultManager] removeItemAtURL:self.cacheDirectory error:NULL];
	}
	self.cacheDelegate = nil;
	self.cacheDirectory = nil;

	[super tearDown];
}

#pragma mark - Helpers

/// Builds a sqlite backed table with a "name" (string) and an "age" (integer) column.
- (MADDataTableFast *)newFastTableWithTag:(NSUInteger)tag {
	return [self newFastTableWithTag:tag cacheDelegate:self.cacheDelegate];
}

- (MADDataTableFast *)newFastTableWithTag:(NSUInteger)tag
							cacheDelegate:(id <MADCacheProtocol, MADDatabaseResultsProtocol>)cacheDelegate {
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

/// Builds an in-memory table with a "name" (string) and an "age" (integer) column.
- (MADDataTableVirtual *)newVirtualTableWithTag:(NSUInteger)tag {
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
- (void)bulkInsertRows:(NSArray <NSArray *> *)rows intoTable:(MADDataTableFast *)table {
	[table beginBulkInsert];
	NSError *error = nil;
	for (NSArray *row in rows) {
		BOOL success = [table addRow:row error:&error];
		XCTAssertTrue(success, @"Bulk addRow: failed: %@", error);
	}
	[table endBulkInsert];
}

#pragma mark - MADDataTable (base class)

- (void)testBaseTableInitDefaults {
	MADDataTable *table = [[MADDataTable alloc] init];

	XCTAssertEqual(table.tag, (NSUInteger)0);
	XCTAssertEqualObjects(table.name, @"");
	XCTAssertEqual(table.rowCounter, (NSUInteger)0);
	XCTAssertNotNil(table.columnKeys);
	XCTAssertNotNil(table.columns);
	XCTAssertNotNil(table.sortDescriptors);
	XCTAssertEqual(table.columnKeys.count, (NSUInteger)0);
	XCTAssertEqual(table.columns.count, (NSUInteger)0);
	XCTAssertEqual(table.sortDescriptors.count, (NSUInteger)0);
}

- (void)testBaseTableInitWithIdSetsTag {
	MADDataTable *table = [[MADDataTable alloc] initWithId:1234];
	XCTAssertEqual(table.tag, (NSUInteger)1234);
}

/// MADDataTable itself is the inert base of the hierarchy.  The read answers
/// below are truthful for a table with no rows, so they remain plain defaults
/// rather than assertions.
- (void)testBaseTableEmptyReadAnswers {
	MADDataTable *table = [[MADDataTable alloc] initWithId:7];

	XCTAssertEqual([table numberOfRows], (NSUInteger)0);
	XCTAssertEqual([table numberOfColumns], (NSUInteger)0);
	XCTAssertEqual([table count], (NSUInteger)0);
	XCTAssertEqualObjects([table allObjects], @[]);
	XCTAssertEqualObjects([table objectAtRow:0 limit:10], @[]);

	// The bulk-insert hooks are optional and are deliberate no-ops; they must
	// not throw, because a subclass need not implement bulk mode at all.
	[table beginBulkInsert];
	[table endBulkInsert];

	XCTAssertEqual([table numberOfRows], (NSUInteger)0);
}

/// CONTRACT: the abstract row/column operations assert instead of failing
/// silently.  Previously -addRow:error: returned true while discarding the row,
/// so a storage subclass that forgot an override lost data with no sign of
/// trouble.  NSAssert is compiled out of Release, so the throws are only
/// meaningful in a Debug test run.
- (void)testBaseTableAbstractOperationsAssert {
	MADDataTable *table = [[MADDataTable alloc] initWithId:7];
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	NSError *error = nil;

#if defined(DEBUG) && DEBUG
	XCTAssertThrows([table addColumn:column]);
	XCTAssertThrows([table addRow:@[@"a"] error:&error]);
	XCTAssertThrows([table addRowWithDataForFieldKeys:@{@"name": @"a"}]);
	XCTAssertThrows([table sortUsingDescriptors:@[]]);
	XCTAssertThrows([table removeAllObjects]);
	XCTAssertThrows([table objectAtRow:0 column:0]);
	XCTAssertThrows([table objectAtRow:0]);
	XCTAssertThrows([table columnsEnumerator]);
	XCTAssertThrows([table objectEnumerator]);
#else
	// Release: the assertions are gone, so the methods fall through to their
	// defaults.  -addRow:error: reports failure rather than claiming success.
	XCTAssertFalse([table addRow:@[@"a"] error:&error]);
	XCTAssertNil([table objectAtRow:0]);
	XCTAssertNil([table objectAtRow:0 column:0]);
	XCTAssertNil([table columnsEnumerator]);
	XCTAssertNil([table objectEnumerator]);
#endif
}

- (void)testBaseTableNewFilenameMDCacheUsesTag {
	MADDataTable *table = [[MADDataTable alloc] initWithId:42];
	XCTAssertEqualObjects([table newFilenameMDCache], @"42.mdcache");
}

- (void)testBaseTableLoadFromCacheWithMissingFileReturnsError {
	MADDataTable *table = [[MADDataTable alloc] initWithId:1];
	NSURL *missing = [self.cacheDirectory URLByAppendingPathComponent:@"does-not-exist.mdcache"];

	NSError *error = nil;
	BOOL loaded = [table loadFromCacheWithUrl:missing error:&error];

	XCTAssertFalse(loaded);
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, (NSInteger)-215);
}

/// CONTRACT: a nil URL is a programmer error - the implementation @throws rather
/// than returning NO.  It throws an NSError object rather than an NSException,
/// which is unusual but is the current behaviour.
- (void)testBaseTableLoadFromCacheWithNilUrlThrows {
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
		XCTAssertTrue([exception isKindOfClass:[NSError class]],
					  @"Expected a thrown NSError, got %@", [exception class]);
	}
	XCTAssertTrue(threw, @"A nil URL should be rejected.");
}

#pragma mark - MADDataTableVirtual: construction and rows

- (void)testVirtualTableStartsEmpty {
	MADDataTableVirtual *table = [[MADDataTableVirtual alloc] initWithId:9];

	XCTAssertEqual(table.tag, (NSUInteger)9);
	XCTAssertEqual([table numberOfRows], (NSUInteger)0);
	XCTAssertEqual([table numberOfColumns], (NSUInteger)0);
	XCTAssertEqual([table count], (NSUInteger)0);
	XCTAssertEqualObjects([table allObjects], @[]);
}

- (void)testVirtualTableAddColumnRecordsKeyAndMetadata {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];

	XCTAssertEqual([table numberOfColumns], (NSUInteger)2);
	XCTAssertEqualObjects(table.columnKeys, (@[@"name", @"age"]));
	XCTAssertNotNil(table.columns[@"name"]);
	XCTAssertNotNil(table.columns[@"age"]);
	XCTAssertEqual(table.columns[@"name"].type, MADDataTypeString);
	XCTAssertEqual(table.columns[@"age"].type, MADDataTypeInteger);
}

- (void)testVirtualTableAddRowBuildsIndexedDictionary {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];

	NSError *error = nil;
	XCTAssertTrue(([table addRow:@[@"alice", @30] error:&error]));

	XCTAssertEqual([table numberOfRows], (NSUInteger)1);
	XCTAssertEqual([table count], (NSUInteger)1);
	XCTAssertEqual(table.rowCounter, (NSUInteger)1);

	NSArray *all = [table allObjects];
	XCTAssertEqual(all.count, (NSUInteger)1);

	NSDictionary *row = all.firstObject;
	XCTAssertEqualObjects(row[@"name"], @"alice");
	XCTAssertEqualObjects(row[@"age"], @30);
	// Rows are stamped with the row counter under a private key.
	XCTAssertEqualObjects(row[@"~rowid~"], @0);
}

- (void)testVirtualTableAddRowStampsMonotonicRowIds {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];
	[table addRow:@[@"bob", @20] error:&error];
	[table addRow:@[@"carol", @40] error:&error];

	NSArray <NSDictionary *> *all = [table allObjects];
	XCTAssertEqual(all.count, (NSUInteger)3);
	XCTAssertEqualObjects(all[0][@"~rowid~"], @0);
	XCTAssertEqualObjects(all[1][@"~rowid~"], @1);
	XCTAssertEqualObjects(all[2][@"~rowid~"], @2);
	XCTAssertEqualObjects(all[0][@"name"], @"alice");
	XCTAssertEqualObjects(all[1][@"name"], @"bob");
	XCTAssertEqualObjects(all[2][@"name"], @"carol");
}

- (void)testVirtualTableObjectAtRowAndColumn {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];
	[table addRow:@[@"bob", @20] error:&error];

	NSDictionary *first = [table objectAtRow:0];
	XCTAssertEqualObjects(first[@"name"], @"alice");

	// Unsorted lookups map the row straight through to the backing column.
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"alice");
	XCTAssertEqualObjects([table objectAtRow:1 column:0], @"bob");
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @30);
	XCTAssertEqualObjects([table objectAtRow:1 column:1], @20);
}

/// CONTRACT: -objectAtRow: bounds checks and returns nil; it does not throw.
- (void)testVirtualTableObjectAtRowOutOfBoundsReturnsNil {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];

	XCTAssertNil([table objectAtRow:1]);
	XCTAssertNil([table objectAtRow:1000]);
}

/// CONTRACT: -dataForRow:error: addresses rows by position, exactly like
/// -objectAtRow:, so the two access paths agree.  The base class asserts here,
/// which is why this has to be implemented rather than inherited.
- (void)testVirtualTableDataForRowReturnsTheRowAtThatIndex {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];
	[table addRow:@[@"bob", @20] error:&error];

	NSDictionary *first = [table dataForRow:0 error:&error];
	XCTAssertNotNil(first);
	XCTAssertNil(error);
	XCTAssertEqualObjects(first[@"name"], @"alice");
	XCTAssertEqualObjects([table dataForRow:1 error:&error][@"name"], @"bob");
}

/// CONTRACT: an out-of-range row id is reported through the error pointer, since
/// nil alone cannot say whether the row is missing or the lookup failed.
- (void)testVirtualTableDataForRowOutOfBoundsReportsAnError {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];

	error = nil;
	XCTAssertNil([table dataForRow:1000 error:&error]);
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, (NSInteger)8927);
}

/// CONTRACT: -addRow: indexes columnKeys directly, so a row wider than the column
/// list raises NSRangeException instead of returning an error.
- (void)testVirtualTableAddRowWiderThanColumnsRaises {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];
	NSError *error = nil;

	XCTAssertThrowsSpecificNamed(([table addRow:@[@"alice", @30, @"extra"] error:&error]),
								 NSException,
								 NSRangeException);
}

/// CONTRACT: -addRowWithDataForFieldKeys: appends normalized values to the backing
/// columns, but stores the CALLER'S dictionary in the sort index unchanged.  So the
/// row handed back by -allObjects carries no "~rowid~" stamp and aliases the caller's
/// instance, unlike rows added through -addRow:.
- (void)testVirtualTableAddRowWithDataForFieldKeysStoresCallerDictionary {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];

	NSDictionary *source = @{@"name": @"alice", @"age": @30};
	[table addRowWithDataForFieldKeys:source];

	XCTAssertEqual([table numberOfRows], (NSUInteger)1);

	NSDictionary *row = [table allObjects].firstObject;
	XCTAssertEqualObjects(row[@"name"], @"alice");
	XCTAssertEqualObjects(row[@"age"], @30);
	XCTAssertNil(row[@"~rowid~"]);
	XCTAssertTrue(row == source, @"The caller's dictionary is stored by reference.");

	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"alice");
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @30);
}

/// CONTRACT: a missing field is defaulted to an empty string in the backing column,
/// but is simply absent from the row dictionary kept in the sort index.
- (void)testVirtualTableAddRowWithDataForFieldKeysDefaultsMissingColumnOnly {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];

	[table addRowWithDataForFieldKeys:@{@"age": @30}];

	NSDictionary *row = [table allObjects].firstObject;
	XCTAssertNil(row[@"name"]);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"");
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @30);
}

- (void)testVirtualTableObjectEnumerator {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];
	[table addRow:@[@"bob", @20] error:&error];

	NSMutableArray *names = [[NSMutableArray alloc] init];
	NSEnumerator *enumerator = [table objectEnumerator];
	NSDictionary *row;
	while ((row = [enumerator nextObject]) != nil) {
		[names addObject:row[@"name"]];
	}
	XCTAssertEqualObjects(names, (@[@"alice", @"bob"]));
}

- (void)testVirtualTableFastEnumerationYieldsIndexedRows {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];
	[table addRow:@[@"bob", @20] error:&error];

	NSMutableArray *names = [[NSMutableArray alloc] init];
	for (NSDictionary *row in table) {
		[names addObject:row[@"name"]];
	}
	XCTAssertEqualObjects(names, (@[@"alice", @"bob"]));
}

- (void)testVirtualTableSubscriptingReturnsRow {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];

	// -objectAtIndexedSubscript: is declared on MADDataTableVirtual, so this is
	// now reachable through the public API without a cast.
	XCTAssertEqualObjects(table[0][@"name"], @"alice");
}

#pragma mark - MADDataTableVirtual: sorting

/// Sorting permutes the index (sortIndex) but never the backing MADDataColumns.
/// -sortedIndexForIndex: then maps a sorted row position back through the index,
/// so -objectAtRow:column: answers from the columns at that mapped position.  When
/// the sort permutation happens to be its own inverse the two views agree by
/// coincidence; otherwise they disagree.  The rows below use a 3-cycle so the
/// disagreement is deterministic.
- (void)testVirtualTableSortDesynchronizesRowAndColumnViews {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];   // insertion index 0
	[table addRow:@[@"bob", @10] error:&error];     // insertion index 1
	[table addRow:@[@"carol", @20] error:&error];   // insertion index 2

	// Before sorting the two views agree.
	XCTAssertEqualObjects([table objectAtRow:0][@"name"], @"alice");
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"alice");

	[table sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:YES]]];

	// -allObjects reflects the sort: bob(10), carol(20), alice(30).
	NSArray <NSDictionary *> *all = [table allObjects];
	XCTAssertEqualObjects(all[0][@"name"], @"bob");
	XCTAssertEqualObjects(all[1][@"name"], @"carol");
	XCTAssertEqualObjects(all[2][@"name"], @"alice");

	// -objectAtRow: agrees with -allObjects ...
	XCTAssertEqualObjects([table objectAtRow:0][@"name"], @"bob");
	XCTAssertEqualObjects([table objectAtRow:1][@"name"], @"carol");
	XCTAssertEqualObjects([table objectAtRow:2][@"name"], @"alice");

	// ... but -objectAtRow:column: indexes the unsorted columns with the sorted
	// position, producing a different answer for the same row.
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"carol");
	XCTAssertEqualObjects([table objectAtRow:1 column:0], @"alice");
	XCTAssertEqualObjects([table objectAtRow:2 column:0], @"bob");
}

#pragma mark - MADDataTableVirtual: plist / cache round trip

- (void)testVirtualTablePlistRoundTrip {
	MADDataTableVirtual *source = [self newVirtualTableWithTag:5];
	NSError *error = nil;
	[source addRow:@[@"alice", @30] error:&error];
	[source addRow:@[@"bob", @20] error:&error];
	source.name = @"people";

	NSDictionary *plist = [source copyPlist];

	MADDataTableVirtual *restored = [[MADDataTableVirtual alloc] initWithId:5];
	NSError *loadError = nil;
	XCTAssertTrue([restored loadWithPlist:plist error:&loadError], @"loadWithPlist failed: %@", loadError);
	XCTAssertNil(loadError);

	XCTAssertEqualObjects(restored.name, @"people");
	XCTAssertEqual([restored numberOfRows], (NSUInteger)2);
	XCTAssertEqual([restored numberOfColumns], (NSUInteger)2);
	XCTAssertEqualObjects([restored allObjects], [source allObjects]);
}

- (void)testVirtualTableCacheAndReloadFromDisk {
	MADDataTableVirtual *source = [self newVirtualTableWithTag:11];
	NSError *error = nil;
	[source addRow:@[@"alice", @30] error:&error];
	[source addRow:@[@"bob", @20] error:&error];
	source.name = @"people";

	NSURL *url = [self.cacheDirectory URLByAppendingPathComponent:[source newFilenameMDCache]];
	NSError *cacheError = nil;
	XCTAssertTrue([source cacheWithUrl:url error:&cacheError], @"cacheWithUrl failed: %@", cacheError);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:url.path]);

	MADDataTableVirtual *restored = [[MADDataTableVirtual alloc] initWithId:11];
	NSError *loadError = nil;
	XCTAssertTrue([restored loadFromCacheWithUrl:url error:&loadError], @"loadFromCache failed: %@", loadError);
	XCTAssertEqualObjects(restored.name, @"people");
	XCTAssertEqualObjects([restored allObjects], [source allObjects]);

	// MADDataTableVirtual reloads its sort index from the same plist it wrote.
	XCTAssertEqualObjects([restored objectAtRow:0][@"name"], @"alice");
}

- (void)testVirtualTableRemoveAllObjectsClearsColumnsAndRows {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:1];
	NSError *error = nil;
	[table addRow:@[@"alice", @30] error:&error];

	[table removeAllObjects];

	XCTAssertEqual([table numberOfRows], (NSUInteger)0);
	XCTAssertEqual([table numberOfColumns], (NSUInteger)0);
	XCTAssertEqualObjects([table allObjects], @[]);
	XCTAssertEqual(table.columns.count, (NSUInteger)0);
	XCTAssertEqual(table.columnKeys.count, (NSUInteger)0);
}

#pragma mark - MADDataTableVirtual: unimplemented surface

/// MADDataTableVirtual deliberately does not implement the sqlite-oriented API.
/// It asserts rather than returning empty results; this test records that the
/// methods exist so a refactor does not quietly turn them into silent no-ops.
- (void)testVirtualTableDoesNotImplementSortedEnumerators {
	MADDataTableVirtual *table = [[MADDataTableVirtual alloc] initWithId:1];

	XCTAssertTrue([table respondsToSelector:@selector(enumeratorForAllObjectsSorted)]);
	XCTAssertTrue([table respondsToSelector:@selector(enumeratorForAllObjectsSortedRowIdOnly)]);
	XCTAssertTrue([table respondsToSelector:@selector(enumeratorForKeyObjectsSorted)]);
	XCTAssertTrue([table respondsToSelector:@selector(objectsForGroupKeys:)]);

	// The implementations are NSAssert(NO, ...) stubs.  NSAssert is compiled out of
	// Release, so the assertion below is only meaningful in a Debug test run.
#if defined(DEBUG) && DEBUG
	XCTAssertThrows([table enumeratorForAllObjectsSorted]);
	XCTAssertThrows([table enumeratorForKeyObjectsSorted]);
	XCTAssertThrows([table objectsForGroupKeys:@[]]);
#endif
}

#pragma mark - MADDataTable+Constructor

- (void)testConstructorVirtualType {
	MADDataTable *table = [MADDataTable newDataTableOfType:MADDataTableTypeVirtual withObjectID:77];

	XCTAssertTrue([table isKindOfClass:[MADDataTableVirtual class]]);
	XCTAssertFalse([table isKindOfClass:[MADDataTableFast class]]);
	XCTAssertEqual(table.tag, (NSUInteger)77);
}

- (void)testConstructorPhysicalType {
	MADDataTable *table = [MADDataTable newDataTableOfType:MADDataTableTypePhysical withObjectID:77];

	XCTAssertTrue([table isKindOfClass:[MADDataTableFast class]]);
	XCTAssertEqual(table.tag, (NSUInteger)77);
}

- (void)testConstructorFromDefinitionWithTypeAndIdentifier {
	NSDictionary *definition = @{
		@(MADDataTableParametersType): @(MADDataTableTypePhysical),
		@(MADDataTableParametersIdentifier): @(88)
	};

	MADDataTable *table = [MADDataTable newDataTableWithDefinition:definition];

	XCTAssertTrue([table isKindOfClass:[MADDataTableFast class]]);
	XCTAssertEqual(table.tag, (NSUInteger)88);
}

/// CONTRACT: with an identifier but no explicit type the constructor falls back to
/// the virtual (in-memory) table.
- (void)testConstructorFromDefinitionWithoutTypeDefaultsToVirtual {
	NSDictionary *definition = @{
		@(MADDataTableParametersIdentifier): @(99)
	};

	MADDataTable *table = [MADDataTable newDataTableWithDefinition:definition];

	XCTAssertTrue([table isKindOfClass:[MADDataTableVirtual class]]);
	XCTAssertEqual(table.tag, (NSUInteger)99);
}

- (void)testConstructorForIdentifierProducesVirtualTable {
	MADDataTable *table = [MADDataTable newDataTableForIdentifier:@"customers"];

	XCTAssertTrue([table isKindOfClass:[MADDataTableVirtual class]]);
	XCTAssertEqual(table.tag, (NSUInteger)@"customers".hash);
}

#pragma mark - MADDataTableFast: metadata and construction

- (void)testFastTableInitDefaults {
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:321];

	XCTAssertEqual(table.tag, (NSUInteger)321);
	XCTAssertEqual([table numberOfRows], (NSUInteger)0);
	XCTAssertEqual([table numberOfColumns], (NSUInteger)0);
	XCTAssertEqualObjects([table tableName], @"t321");
}

/// A caller with a directory but no cache delegate must still be able to build a
/// working physical table.  This is what -initWithId:cacheDirectory: is for: without
/// it the table reaches for [MADApplication AppDelegate], which a logic test has not
/// got.  No delegate is set here on purpose.
- (void)testFastTableInitWithCacheDirectoryNeedsNoDelegate {
	const NSUInteger tag = 555;
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:tag cacheDirectory:self.cacheDirectory];

	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;
	[table addColumn:name];

	[self bulkInsertRows:@[@[@"alice"], @[@"bob"]] intoTable:table];

	XCTAssertEqual([table numberOfRows], (NSUInteger)2);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"alice");

	// The cache file belongs to the directory we handed over, not to any app default.
	NSArray <NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cacheDirectory.path
																					   error:NULL];
	NSString *stem = [NSString stringWithFormat:@"%lu", (unsigned long)tag];
	BOOL foundCacheFile = NO;
	for (NSString *name in contents) {
		if ([name hasPrefix:stem]) { foundCacheFile = YES; break; }
	}
	XCTAssertTrue(foundCacheFile, @"no cache file for tag %@ in %@", stem, contents);
}

- (void)testFastTableColumnNamesAreHashedIdentifiers {
	MADDataTableFast *table = [self newFastTableWithTag:5];

	XCTAssertEqual([table numberOfColumns], (NSUInteger)2);

	NSString *expectedName = [NSString stringWithFormat:@"c%lu", (unsigned long)@"name".hash];
	NSString *expectedAge  = [NSString stringWithFormat:@"c%lu", (unsigned long)@"age".hash];

	XCTAssertEqualObjects(table.columnKeys, (@[expectedName, expectedAge]));
	XCTAssertEqualObjects([table columnKeyForColumnName:@"name"], expectedName);
	XCTAssertEqualObjects([table columnKeyForColumnName:@"age"], expectedAge);
	XCTAssertNil([table columnKeyForColumnName:@"missing"]);
}

- (void)testFastTableNumberOfColumnsTracksColumnKeys {
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:6];
	self.cacheDelegate.dataTable = table;
	table.cacheDelegate = self.cacheDelegate;
	XCTAssertEqual([table numberOfColumns], (NSUInteger)0);

	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;
	[table addColumn:name];

	XCTAssertEqual([table numberOfColumns], (NSUInteger)1);
	XCTAssertNotNil([table objectEnumerator]);
	XCTAssertNotNil([table enumeratorForAllObjectsSorted]);
	XCTAssertEqual([table objectEnumerator].class,
				   NSClassFromString(MADDataTableObjectEnumeratorClassName));
}

- (void)testFastTableObjectEnumeratorIsNilWithoutColumns {
	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:7];
	table.cacheDelegate = self.cacheDelegate;

	XCTAssertNil([table objectEnumerator]);
}

#pragma mark - MADDataTableFast: bulk insert round trip

- (void)testFastTableBulkInsertRowCount {
	MADDataTableFast *table = [self newFastTableWithTag:100];
	XCTAssertEqual([table numberOfRows], (NSUInteger)0);

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20], @[@"carol", @40]] intoTable:table];

	XCTAssertEqual([table numberOfRows], (NSUInteger)3);
	XCTAssertEqual([table count], (NSUInteger)3);
	XCTAssertEqual([table rowCounter], (NSUInteger)3);
}

/// The plist carries the row counter but not the rows -- those are in the cache
/// file.  A counter that disagrees with the file must not survive a reload.
- (void)testFastTableReloadRecountsRowsFromCacheFile {
	MADDataTableFast *source = [self newFastTableWithTag:1001];
	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20], @[@"carol", @40]] intoTable:source];

	NSMutableDictionary *plist = [[source copyPlist] mutableCopy];
	// "rowCounter" mirrors +[MADDataTable keyRowCounter]; the key methods are private.
	XCTAssertEqualObjects(plist[@"rowCounter"], @3);
	plist[@"rowCounter"] = @99;

	MADDataTableFast *restored = [[MADDataTableFast alloc] initWithId:1001];
	NSError *loadError = nil;
	XCTAssertTrue([restored loadWithPlist:plist error:&loadError], @"loadWithPlist failed: %@", loadError);

	XCTAssertEqual([restored numberOfRows], (NSUInteger)3);
	XCTAssertEqual([restored count], (NSUInteger)3);
	XCTAssertEqual([restored rowCounter], (NSUInteger)3);
}

- (void)testFastTableDropTableZeroesRowCount {
	MADDataTableFast *table = [self newFastTableWithTag:1101];
	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];
	XCTAssertEqual([table count], (NSUInteger)2);

	[table reopenDbConnection];
	[table dropTable];

	// The rows are gone from the file, so the counter must not outlive them: the app
	// reads -count as a page cursor (hasMore = count == limit).
	XCTAssertEqual([table count], (NSUInteger)0);
	XCTAssertEqual([table numberOfRows], (NSUInteger)0);
	XCTAssertEqual([table rowCounter], (NSUInteger)0);
}

- (void)testFastTableDropForeignTableKeepsRowCount {
	MADDataTableFast *table = [self newFastTableWithTag:1102];
	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	// -dropTableName: takes any name, and dropping a table that is not this one
	// must leave this table's rows and count alone.
	[table reopenDbConnection];
	[table dropTableName:@"some_other_table"];

	XCTAssertEqual([table count], (NSUInteger)2);
}

- (void)testFastTableDeleteAllZeroesRowCount {
	MADDataTableFast *table = [self newFastTableWithTag:1103];
	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	[table reopenDbConnection];
	[table deleteAll];

	XCTAssertEqual([table count], (NSUInteger)0);
	XCTAssertEqual([table numberOfRows], (NSUInteger)0);
}

- (void)testFastTableVacuumKeepsRowCount {
	MADDataTableFast *table = [self newFastTableWithTag:1104];
	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	[table reopenDbConnection];
	[table vacuumCacheDb];

	// VACUUM rewrites the file but keeps every row, so it must not zero the counter.
	XCTAssertEqual([table count], (NSUInteger)2);
}

- (void)testFastTableBulkInsertEnumeratesValues {
	MADDataTableFast *table = [self newFastTableWithTag:101];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	NSMutableArray <NSString *> *names = [[NSMutableArray alloc] init];
	for (NSDictionary *row in [table objectEnumerator]) {
		[names addObject:row[@"name"]];
	}
	XCTAssertEqualObjects(names, (@[@"alice", @"bob"]));
}

- (void)testFastTableObjectEnumeratorYieldsRowId {
	MADDataTableFast *table = [self newFastTableWithTag:102];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	NSDictionary *first = [[table objectEnumerator] nextObject];
	XCTAssertEqualObjects(first[@"name"], @"alice");
	XCTAssertEqualObjects(first[@"age"], @30);
	XCTAssertNotNil(first[MADIdentifierROWID]);
}

/// CONTRACT: the non-bulk -addRow: path stores the values it is given.
/// MADDataTableFast builds its INSERT with "?" placeholders and depends on
/// MADQueryCacheAddRow to populate binaryBindings; that query now creates one
/// binding per column, so sqlite3_step runs with every parameter bound.
- (void)testFastTableNonBulkAddRowStoresValues {
	MADDataTableFast *table = [self newFastTableWithTag:120];

	NSError *error = nil;
	XCTAssertTrue(([table addRow:@[@"alice", @30] error:&error]),
				  @"The statement still succeeds.");
	XCTAssertEqual([table numberOfRows], (NSUInteger)1,
				   @"The row is counted.");

	NSDictionary *row = [[table objectEnumerator] nextObject];
	XCTAssertNotNil(row, @"The row is cached and enumerable.");
	XCTAssertEqualObjects(row[@"name"], @"alice");
	XCTAssertEqualObjects(row[@"age"], @30);
}

/// CONTRACT: a non-bulk insert binds NSNull (not a default) for a value the
/// caller passed as NSNull.
- (void)testFastTableNonBulkAddRowStoresNullForNullInput {
	MADDataTableFast *table = [self newFastTableWithTag:122];

	NSError *error = nil;
	XCTAssertTrue(([table addRow:@[[NSNull null], @7] error:&error]));

	NSDictionary *row = [[table objectEnumerator] nextObject];
	XCTAssertEqualObjects(row[@"age"], @7, @"The bound column still lands.");
	XCTAssertEqualObjects(row[@"name"], [NSNull null]);
}

/// CONTRACT: -dataTableForQuery: is @optional on MADDatabaseResultsProtocol, so a
/// delegate that does not implement it must not break the cache write path.
- (void)testFastTableWorksWithDelegateThatOmitsOptionalDataTableForQuery {
	MADDataTableRegressionBareDelegate *bare = [[MADDataTableRegressionBareDelegate alloc] init];
	bare.cachedFilesDirectory = self.cacheDirectory;
	XCTAssertFalse([bare respondsToSelector:@selector(dataTableForQuery:)],
				   @"The double must not implement the optional method.");

	MADDataTableFast *table = [self newFastTableWithTag:123 cacheDelegate:bare];

	XCTAssertNoThrow(([self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table]));
	XCTAssertEqual([table numberOfRows], (NSUInteger)2);
	XCTAssertEqual([[table objectEnumerator] allObjects].count, (NSUInteger)2);
}

/// CONTRACT: -allObjects returns every row as a dictionary, in the table's sort
/// order -- the same shape MADDataTableVirtual already returned.
- (void)testFastTableBulkInsertAllObjectsReturnsEveryRow {
	MADDataTableFast *table = [self newFastTableWithTag:103];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	// The declaration is `nonnull NSArray *`, so this must never be nil.
	NSArray *all = [table allObjects];
	XCTAssertEqual(all.count, (NSUInteger)2);
	XCTAssertEqualObjects(all[0][@"name"], @"alice");
	XCTAssertEqualObjects(all[1][@"name"], @"bob");
}

/// CONTRACT: -allObjects on a table with no rows is an empty array, not nil.
- (void)testFastTableAllObjectsIsEmptyWhenThereAreNoRows {
	MADDataTableFast *table = [self newFastTableWithTag:113];

	XCTAssertNotNil([table allObjects]);
	XCTAssertEqualObjects([table allObjects], @[]);
}

- (void)testFastTableRowIdEnumeratorReturnsRowIds {
	MADDataTableFast *table = [self newFastTableWithTag:104];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20], @[@"carol", @40]] intoTable:table];

	NSMutableArray *rowIds = [[NSMutableArray alloc] init];
	for (id rowId in [table enumeratorForAllObjectsSortedRowIdOnly]) {
		[rowIds addObject:rowId];
	}

	XCTAssertEqual(rowIds.count, (NSUInteger)3);
	for (id rowId in rowIds) {
		XCTAssertTrue([rowId isKindOfClass:[NSNumber class]],
					  @"Expected NSNumber row id, got %@", [rowId class]);
	}
}

- (void)testFastTableDataForRowReturnsValues {
	MADDataTableFast *table = [self newFastTableWithTag:105];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	NSNumber *rowId = nil;
	for (id candidate in [table enumeratorForAllObjectsSortedRowIdOnly]) {
		rowId = candidate;
		break;
	}
	XCTAssertNotNil(rowId);

	NSError *error = nil;
	NSDictionary *row = [table dataForRow:rowId.unsignedIntegerValue error:&error];

	XCTAssertNotNil(row);
	XCTAssertNil(error);
	XCTAssertEqualObjects(row[@"name"], @"alice");
	XCTAssertEqualObjects(row[@"age"], @30);
}

/// CONTRACT: -dataForRow:error: memoizes the last row it fetched and serves the
/// second request for the same row id from that cache.
- (void)testFastTableDataForRowCachesLastRow {
	MADDataTableFast *table = [self newFastTableWithTag:106];

	[self bulkInsertRows:@[@[@"alice", @30]] intoTable:table];

	NSNumber *rowId = nil;
	for (id candidate in [table enumeratorForAllObjectsSortedRowIdOnly]) {
		rowId = candidate;
		break;
	}

	NSError *error = nil;
	NSDictionary *first = [table dataForRow:rowId.unsignedIntegerValue error:&error];
	NSDictionary *second = [table dataForRow:rowId.unsignedIntegerValue error:&error];

	XCTAssertEqualObjects(first, second);
	XCTAssertFalse(first == second, @"The cached path is expected to return a fresh copy.");
}

- (void)testFastTableDataForRowWithUnknownColumnReturnsError {
	MADDataTableFast *table = [self newFastTableWithTag:107];

	[self bulkInsertRows:@[@[@"alice", @30]] intoTable:table];

	NSError *error = nil;
	NSDictionary *row = [table dataForRow:1 column:@"not-a-column" error:&error];

	XCTAssertNil(row);
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, (NSInteger)8927);
}

#pragma mark - MADDataTableFast: row access

/// CONTRACT: -objectAtRow:limit: returns the cached rows and agrees with the
/// enumerator.  It used to store the result of `sqlite3_prepare_v2(...) ==
/// SQLITE_OK` in an int and then re-test it against SQLITE_OK, so the row loop
/// only ran when the prepare had *failed*.
- (void)testFastTableObjectAtRowLimitReturnsCachedRows {
	MADDataTableFast *table = [self newFastTableWithTag:108];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	NSArray *rows = [table objectAtRow:0 limit:2];
	XCTAssertEqual(rows.count, (NSUInteger)2);
	XCTAssertEqualObjects(rows[0][@"name"], @"alice");
	XCTAssertEqualObjects(rows[0][@"age"], @30);
	XCTAssertEqualObjects(rows[1][@"name"], @"bob");
	XCTAssertEqualObjects(rows[1][@"age"], @20);

	// The row accessor and the enumerator must agree.
	XCTAssertEqualObjects([table objectEnumerator].allObjects, rows);
}

- (void)testFastTableObjectAtRowReturnsRow {
	MADDataTableFast *table = [self newFastTableWithTag:109];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	NSDictionary *first = [table objectAtRow:0];
	XCTAssertEqual(first.count, (NSUInteger)3, @"Two columns plus ~rowid~.");
	XCTAssertEqualObjects(first[@"name"], @"alice");
	XCTAssertEqualObjects(first[@"age"], @30);

	NSDictionary *second = [table objectAtRow:1];
	XCTAssertEqualObjects(second[@"name"], @"bob");
	XCTAssertEqualObjects(second[@"age"], @20);
}

- (void)testFastTableObjectAtRowOutOfRangeReturnsEmpty {
	MADDataTableFast *table = [self newFastTableWithTag:110];

	[self bulkInsertRows:@[@[@"alice", @30]] intoTable:table];

	XCTAssertEqual([table objectAtRow:5 limit:1].count, (NSUInteger)0);
	XCTAssertEqual([table objectAtRow:0 limit:0].count, (NSUInteger)0,
				   @"A zero limit short-circuits.");
}

/// CONTRACT: -objectAtRow:column: returns the value stored in the requested
/// column at the requested row.  It used to answer from column 0 for every
/// index.
- (void)testFastTableObjectAtRowColumnReturnsTheRequestedColumn {
	MADDataTableFast *table = [self newFastTableWithTag:112];

	MADDataColumn *role = [[MADDataColumn alloc] initWithIdentifier:@"role"];
	role.type = MADDataTypeString;
	[table addColumn:role];

	[self bulkInsertRows:@[@[@"Alice", @30, @"Engineer"]] intoTable:table];

	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"Alice");
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @30);
	XCTAssertEqualObjects([table objectAtRow:0 column:2], @"Engineer");
}

/// CONTRACT: the column index is bounds checked.
- (void)testFastTableObjectAtRowColumnOutOfBoundsReturnsNil {
	MADDataTableFast *table = [self newFastTableWithTag:113];

	[self bulkInsertRows:@[@[@"Alice", @30], @[@"Bob", @20]] intoTable:table];

	XCTAssertEqual([table numberOfColumns], (NSUInteger)2);

	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"Alice");
	XCTAssertNil([table objectAtRow:0 column:2], @"One past the last column.");
	XCTAssertNil([table objectAtRow:0 column:NSNotFound]);
	XCTAssertNil([table objectAtRow:9 column:0], @"Row out of range.");
}

/// CONTRACT: -objectAtRow:column: agrees with the dictionaries the row accessors
/// return, for every column.
- (void)testFastTableObjectAtRowColumnAgreesWithRowDictionaries {
	MADDataTableFast *table = [self newFastTableWithTag:114];

	[self bulkInsertRows:@[@[@"Alice", @30], @[@"Bob", @20]] intoTable:table];

	NSArray <NSString *> *fieldNames = @[@"name", @"age"];
	for (NSUInteger row = 0; row < 2; row++) {
		NSDictionary *rowDictionary = [table objectAtRow:row];
		for (NSUInteger column = 0; column < fieldNames.count; column++) {
			XCTAssertEqualObjects([table objectAtRow:row column:column],
								  rowDictionary[fieldNames[column]],
								  @"row %lu column %lu", (unsigned long)row, (unsigned long)column);
		}
	}
}

#pragma mark - MADDataTableFast: mutation

- (void)testFastTableRemoveAllObjectsDropsRowsAndColumns {
	MADDataTableFast *table = [self newFastTableWithTag:111];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];
	XCTAssertEqual([table numberOfRows], (NSUInteger)2);

	[table removeAllObjects];

	XCTAssertEqual([table numberOfRows], (NSUInteger)0);
	XCTAssertEqual([table numberOfColumns], (NSUInteger)0);
	XCTAssertEqual(table.columnKeys.count, (NSUInteger)0);
	XCTAssertEqual(table.columns.count, (NSUInteger)0);
}

- (void)testFastTableSortUsingDescriptorsRecordsGroupKeys {
	MADDataTableFast *table = [self newFastTableWithTag:112];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	[table sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:YES]]];

	// The public sortDescriptors are rewritten to use the internal column keys.
	XCTAssertEqual(table.sortDescriptors.count, (NSUInteger)1);
	NSString *expectedAge = [NSString stringWithFormat:@"c%lu", (unsigned long)@"age".hash];
	XCTAssertEqualObjects(table.sortDescriptors.firstObject.key, expectedAge);
}

- (void)testFastTableEnumeratorForAllObjectsSorted {
	MADDataTableFast *table = [self newFastTableWithTag:113];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	NSMutableArray <NSString *> *names = [[NSMutableArray alloc] init];
	for (NSDictionary *row in [table enumeratorForAllObjectsSorted]) {
		[names addObject:row[@"name"]];
	}
	XCTAssertEqual(names.count, (NSUInteger)2);
	XCTAssertTrue([names containsObject:@"alice"]);
	XCTAssertTrue([names containsObject:@"bob"]);
}

#pragma mark - Enumerators used directly

/// CONTRACT: both enumerator classes build their own MADDatabaseSqlite3 connection
/// from the connection they are handed, so an enumerator can outlive the table it
/// came from.  Enumerating twice from the same enumerator replays the result set
/// (the statement is reset when fast enumeration restarts, and -allObjects drains).
- (void)testObjectEnumeratorReplaysResults {
	MADDataTableFast *table = [self newFastTableWithTag:120];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	NSEnumerator *enumerator = [table objectEnumerator];
	XCTAssertEqual(enumerator.class, NSClassFromString(MADDataTableObjectEnumeratorClassName));

	NSUInteger firstPass = 0;
	for (NSDictionary *row in enumerator) {
		XCTAssertNotNil(row[@"name"]);
		firstPass++;
	}
	XCTAssertEqual(firstPass, (NSUInteger)2);

	NSUInteger secondPass = 0;
	for (NSDictionary *row in enumerator) {
		XCTAssertNotNil(row[@"name"]);
		secondPass++;
	}
	XCTAssertEqual(secondPass, (NSUInteger)2);
}

- (void)testSingleColumnEnumeratorIsUsedForRowIds {
	MADDataTableFast *table = [self newFastTableWithTag:121];

	[self bulkInsertRows:@[@[@"alice", @30]] intoTable:table];

	NSEnumerator *enumerator = [table enumeratorForAllObjectsSortedRowIdOnly];
	XCTAssertEqual(enumerator.class, NSClassFromString(MADDataTableSingleColumnEnumeratorClassName));

	NSMutableArray *values = [[NSMutableArray alloc] init];
	for (id value in enumerator) {
		[values addObject:value];
	}
	XCTAssertEqual(values.count, (NSUInteger)1);
	XCTAssertTrue([values.firstObject isKindOfClass:[NSNumber class]]);
}

- (void)testEnumeratorAllObjectsReturnsEveryRow {
	MADDataTableFast *table = [self newFastTableWithTag:122];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20], @[@"carol", @40]] intoTable:table];

	NSEnumerator *enumerator = [table objectEnumerator];
	NSArray *all = [enumerator allObjects];

	XCTAssertEqual(all.count, (NSUInteger)3);
}

#pragma mark - Threading

/// Concurrent readers of a quiescent MADDataTableVirtual are safe: nothing mutates
/// the backing containers while the reads happen.
- (void)testVirtualTableConcurrentReadsAreConsistent {
	MADDataTableVirtual *table = [self newVirtualTableWithTag:200];
	NSError *error = nil;
	for (NSUInteger i = 0; i < 100; i++) {
		[table addRow:@[[NSString stringWithFormat:@"name-%lu", (unsigned long)i], @(i)] error:&error];
	}

	dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
	dispatch_apply(8, queue, ^(size_t iteration) {
		for (NSUInteger row = 0; row < 100; row++) {
			NSDictionary *fetched = [table objectAtRow:row];
			XCTAssertEqualObjects(fetched[@"age"], @(row));
			XCTAssertEqualObjects([table objectAtRow:row column:1], @(row));
		}
		__block NSUInteger counted = 0;
		for (NSDictionary *row in table) {
			XCTAssertNotNil(row[@"name"]);
			counted++;
		}
		XCTAssertEqual(counted, (NSUInteger)100);
	});
}

/// Every enumerator returned by MADDataTableFast opens its own database
/// connection, which is what makes concurrent enumeration safe.
- (void)testFastTableConcurrentEnumeratorsAreIndependent {
	MADDataTableFast *table = [self newFastTableWithTag:201];
	NSMutableArray *rows = [[NSMutableArray alloc] init];
	for (NSUInteger i = 0; i < 50; i++) {
		[rows addObject:@[[NSString stringWithFormat:@"name-%lu", (unsigned long)i], @(i)]];
	}
	[self bulkInsertRows:rows intoTable:table];

	dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
	dispatch_apply(6, queue, ^(size_t iteration) {
		NSUInteger counted = 0;
		for (NSDictionary *row in [table objectEnumerator]) {
			XCTAssertNotNil(row[@"name"]);
			counted++;
		}
		XCTAssertEqual(counted, (NSUInteger)50);
	});
}

/// CONTRACT: MADDataTableFast serializes -addRow: on its own bulk-insert queue, so
/// writers may come from any queue without losing rows.  This test uses the app's
/// serial-queue pattern; -testFastTableConcurrentWritersLoseNoRows covers the
/// concurrent case.
- (void)testFastTableSerializedConcurrentWritesLoseNoRows {
	MADDataTableFast *table = [self newFastTableWithTag:202];

	const NSUInteger writers = 4;
	const NSUInteger rowsPerWriter = 25;

	[table beginBulkInsert];

	dispatch_queue_t serial = dispatch_queue_create("MADDataTableRegression.writes", DISPATCH_QUEUE_SERIAL);
	dispatch_group_t group = dispatch_group_create();
	for (NSUInteger writer = 0; writer < writers; writer++) {
		dispatch_group_async(group, serial, ^{
			for (NSUInteger row = 0; row < rowsPerWriter; row++) {
				NSString *name = [NSString stringWithFormat:@"w%lu-r%lu", (unsigned long)writer, (unsigned long)row];
				NSError *error = nil;
				BOOL success = [table addRow:@[name, @(row)] error:&error];
				XCTAssertTrue(success, @"addRow: failed: %@", error);
			}
		});
	}
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

	[table endBulkInsert];

	XCTAssertEqual([table numberOfRows], writers * rowsPerWriter);

	// Reads after the writers stop must observe every row.
	NSUInteger counted = 0;
	for (NSDictionary *row in [table objectEnumerator]) {
		XCTAssertNotNil(row[@"name"]);
		counted++;
	}
	XCTAssertEqual(counted, writers * rowsPerWriter);
}

/// -addRow: runs under the same serial queue -endBulkInsert uses as a barrier, so
/// writers racing each other still land one at a time and none are dropped.
- (void)testFastTableConcurrentWritersLoseNoRows {
	MADDataTableFast *table = [self newFastTableWithTag:204];

	const NSUInteger writers = 4;
	const NSUInteger rowsPerWriter = 25;

	[table beginBulkInsert];

	dispatch_queue_t concurrent = dispatch_queue_create("MADDataTableRegression.concurrentWrites",
														DISPATCH_QUEUE_CONCURRENT);
	dispatch_group_t group = dispatch_group_create();
	for (NSUInteger writer = 0; writer < writers; writer++) {
		dispatch_group_async(group, concurrent, ^{
			for (NSUInteger row = 0; row < rowsPerWriter; row++) {
				NSString *name = [NSString stringWithFormat:@"w%lu-r%lu", (unsigned long)writer, (unsigned long)row];
				NSError *error = nil;
				BOOL success = [table addRow:@[name, @(row)] error:&error];
				XCTAssertTrue(success, @"addRow: failed: %@", error);
			}
		});
	}
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

	[table endBulkInsert];

	XCTAssertEqual([table numberOfRows], writers * rowsPerWriter);

	NSUInteger counted = 0;
	for (NSDictionary *row in [table objectEnumerator]) {
		XCTAssertNotNil(row[@"name"]);
		counted++;
	}
	XCTAssertEqual(counted, writers * rowsPerWriter);
}

/// CONTRACT: reads and writes must not overlap.  The table opens a separate
/// read-only-handle for selects, but a write transaction in flight is not
/// coordinated with readers by this class.  This test records the supported
/// sequencing: fill, then read.
- (void)testFastTableReadsAfterWritesComplete {
	MADDataTableFast *table = [self newFastTableWithTag:203];

	[self bulkInsertRows:@[@[@"alice", @30], @[@"bob", @20]] intoTable:table];

	dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
	dispatch_apply(4, queue, ^(size_t iteration) {
		NSMutableArray <NSString *> *names = [[NSMutableArray alloc] init];
		for (NSDictionary *row in [table objectEnumerator]) {
			[names addObject:row[@"name"]];
		}
		XCTAssertEqual(names.count, (NSUInteger)2);
		XCTAssertTrue([names containsObject:@"alice"]);
		XCTAssertTrue([names containsObject:@"bob"]);
	});
}

@end
