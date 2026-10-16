//
//  MADHeadlessDocumentTests.m
//  Linux/Tests
//
//  The data path, end to end, without a UI: MADHeadlessDocument opens a portable
//  .mad, reads its definition out of the store, compiles the query, and the
//  application's own refresh chain (MADOperationRefresh and its two initializers)
//  runs against it and fills the row cache.  This is Phase D's checkpoint in test
//  form (MAD_LINUX.md §9).
//
//  The document is the checked-in portable copy of the London sample
//  (CLI/Fixtures/London.portable.mad, made on the Mac -- a legacy document needs
//  Core Data to convert, which is why the fixture exists at all; see
//  CLI/Fixtures/README.md).  Its source database is chinook.sqlite3, which the app
//  ships as a sample and which this test puts where the Sqlite3 driver looks.
//

#import "MADTestSupport.h"

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADHeadlessDocument.h>
#import <MAD/MADOperationRefresh.h>
#import <MAD/MADOperationRefreshInitialize.h>
#import <MAD/MADOperationRefreshInitalizeMainDataTable.h>
#import <MAD/MADQueryFull.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqStoreContext.h>

#import <MADAPI/MADDatabase.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADURLFactory.h>

// __FILE__ is absolute here (CMake hands the compiler an absolute path), so
// Tests -> Linux -> the repository root.
static NSString *MADHeadlessFixturePath(void) {
	NSString *testFile = [@(__FILE__) stringByDeletingLastPathComponent];
	NSString *linuxDirectory = [testFile stringByDeletingLastPathComponent];
	NSString *repositoryRoot = [linuxDirectory stringByDeletingLastPathComponent];
	return [[repositoryRoot stringByAppendingPathComponent: @"CLI/Fixtures"]
			stringByAppendingPathComponent: @"London.portable.mad"];
}

static NSString *MADHeadlessSampleDatabasePath(void) {
	NSString *testFile = [@(__FILE__) stringByDeletingLastPathComponent];
	NSString *linuxDirectory = [testFile stringByDeletingLastPathComponent];
	NSString *repositoryRoot = [linuxDirectory stringByDeletingLastPathComponent];
	return [[repositoryRoot stringByAppendingPathComponent:
			 @"MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset"]
			stringByAppendingPathComponent: @"chinook.sqlite3"];
}

static BOOL MADHeadlessFixtureIsThere(void) {
	return [[NSFileManager defaultManager] fileExistsAtPath: MADHeadlessFixturePath()];
}

/// Put the sample database where the document's Sqlite3 connection will look for
/// it: the connection stores a bare filename and MADURLFactory resolves it against
/// the app-support directory, so that is where it goes.  It has to happen before
/// anything opens the connection -- Sqlite3 creates an empty file for a missing
/// database, and that empty file is what "no such table" comes from.
static void MADHeadlessInstallSampleDatabase(void) {
	NSString *samplePath = MADHeadlessSampleDatabasePath();
	if (![[NSFileManager defaultManager] fileExistsAtPath: samplePath]) return;

	NSURL *supportDirectory = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID: [MADApplication groupIdentifier]];
	NSURL *target = [supportDirectory URLByAppendingPathComponent: @"chinook.sqlite3"];	// the document's dbname
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager createDirectoryAtURL: supportDirectory withIntermediateDirectories: YES attributes: nil error: NULL];
	[fileManager removeItemAtURL: target error: NULL];
	[fileManager copyItemAtURL: [NSURL fileURLWithPath: samplePath] toURL: target error: NULL];
}

/// The opened fixture, or nil.  One document per process, as the CLI has: opening
/// the same .mad twice would unarchive the second copy over the first one's guts.
/// Retained because the library is ARC and the test's autorelease pool is not the
/// document's keeper (Linux/AGENTS.md).
static MADHeadlessDocument *MADHeadlessDocumentForTests(void) {
	static MADHeadlessDocument *document = nil;
	if (document == nil) {
		MADHeadlessInstallSampleDatabase();
		document = [[MADHeadlessDocument documentWithContentsOfURL: [NSURL fileURLWithPath: MADHeadlessFixturePath()]
															 error: NULL] retain];
	}
	return document;
}

#pragma mark - The definition

static void testOpeningReadsTheDefinition(void) {
	MAD_NEED(MADHeadlessFixtureIsThere(), @"CLI/Fixtures/London.portable.mad is missing (it is checked in)");
	MADHeadlessDocument *document = MADHeadlessDocumentForTests();
	MAD_NEED(document != nil, @"could not open CLI/Fixtures/London.portable.mad");
	if (document == nil) return;

	MAD_PASS(document.storeContext != nil, "the portable store opened");
	MAD_PASS(document.activeDocumentModel != nil, "the document definition was read");

	NSArray *tables = [document.storeContext objectsForEntity: @"RptqDatabaseSchemaTable"];
	MAD_PASS(tables.count == 11, "chinook's eleven tables are in the schema");
}

static void testTheQueryCompilesToSQL(void) {
	MAD_NEED(MADHeadlessFixtureIsThere(), @"CLI/Fixtures/London.portable.mad is missing (it is checked in)");
	MADHeadlessDocument *document = MADHeadlessDocumentForTests();
	MAD_NEED(document != nil, @"could not open CLI/Fixtures/London.portable.mad");
	if (document == nil) return;

	NSError *error = nil;
	NSString *sql = [document.mainQuery copySQLWithManagedObjectContext: document.storeContext error: &error];
	MAD_PASS(sql != nil, "the document's query produced SQL");
	MAD_PASS([sql hasPrefix: @"SELECT\n"], "the statement starts with SELECT");
	MAD_PASS([sql rangeOfString: @"FROM"].location != NSNotFound, "the statement names a source");
	NSString *upper = [sql uppercaseString];
	MAD_PASS([upper rangeOfString: @"CITY"].location != NSNotFound, "the London sample's city field is selected");
	MAD_PASS([sql rangeOfString: @"'London'"].location != NSNotFound, "the London sample's predicate is in the statement");
}

static void testTheDataSourceResolvesWithoutCredentials(void) {
	MAD_NEED(MADHeadlessFixtureIsThere(), @"CLI/Fixtures/London.portable.mad is missing (it is checked in)");
	MADHeadlessDocument *document = MADHeadlessDocumentForTests();
	MAD_NEED(document != nil, @"could not open CLI/Fixtures/London.portable.mad");
	if (document == nil) return;

	// The connection comes from the stored credential row through the driver
	// registry, and a Sqlite3 connection needs no credentials.
	MAD_PASS(document.database != nil, "the driver was constructed");
	MAD_PASS([NSStringFromClass([document.database class]) rangeOfString: @"Sqlite3"].location != NSNotFound,
			 "the Sqlite3 driver answers a Sqlite3 document");
}

#pragma mark - The refresh

static void testTheRefreshChainFillsTheRowCache(void) {
	MAD_NEED(MADHeadlessFixtureIsThere(), @"CLI/Fixtures/London.portable.mad is missing (it is checked in)");
	MADHeadlessDocument *document = MADHeadlessDocumentForTests();
	MAD_NEED(document != nil, @"could not open CLI/Fixtures/London.portable.mad");
	if (document == nil) return;

	MAD_NEED([[NSFileManager defaultManager] fileExistsAtPath: MADHeadlessSampleDatabasePath()],
			 @"the chinook sample database is missing");
	if (![[NSFileManager defaultManager] fileExistsAtPath: MADHeadlessSampleDatabasePath()]) return;

	MADOperationRefreshInitializeMainDataTable *initializeTable =
		[[MADOperationRefreshInitializeMainDataTable alloc] initWithDocument: document];
	MADOperationRefreshInitialize *initialize = [[MADOperationRefreshInitialize alloc] initWithDocument: document];
	[initialize addDependency: initializeTable];
	MADOperationRefresh *refresh = [[MADOperationRefresh alloc] initWithDocument: document];
	[refresh addDependency: initializeTable];
	[refresh addDependency: initialize];

	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: initializeTable];
	[queue addOperation: initialize];
	[queue addOperation: refresh];

	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 60];
	while (queue.operationCount > 0 && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
								 beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.02]];
	}

	MAD_PASS(queue.operationCount == 0, "the refresh chain finished");
	MAD_PASS(refresh.errors.count == 0, "the refresh reported no error: %s",
			 refresh.errors.count > 0 ? [[refresh.errors.firstObject description] UTF8String] : "none");
	MAD_PASS(document.didRefresh, "the document reports itself refreshed");
	MAD_PASS(document.numberOfResults == 76, "the London sample's 76 rows are in the row cache");
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath: document.urlDataTableCache.path],
			 "the cache was written where the document says it is");
}

MAD_TEST_MAIN("MADHeadlessDocumentTests",
	MAD_TEST(testOpeningReadsTheDefinition),
	MAD_TEST(testTheQueryCompilesToSQL),
	MAD_TEST(testTheDataSourceResolvesWithoutCredentials),
	MAD_TEST(testTheRefreshChainFillsTheRowCache));
