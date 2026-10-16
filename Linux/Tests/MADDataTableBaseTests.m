//
//  MADDataTableBaseTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADDataTableBaseTests.m: coverage for the
//  pieces of the MADDataTable base class the MAD-bundle regression suite does
//  not reach -- the plist contract (copyPlist's exact shape, and each of
//  loadWithPlist:'s rejection paths with its error code), the base class's
//  NSCoding round trip, and the two nil-URL crashes in the caching pair.
//
//  MADDataTable is a class cluster; the row storage lives in MADDataTableVirtual /
//  MADDataTableFast, whose behaviour is covered by MADDataTableRegressionTests.
//  What the base owns is metadata, the plist shape and the coding, which is
//  what is pinned here.
//
//  The Xcode suite builds its coders with the iOS 11+ instance APIs
//  (-initRequiringSecureCoding: / -initForReadingFromData:error:); GNUstep has
//  neither, so the port uses the portable class pair, which is the same
//  insecure round trip (the Xcode comments' requiresSecureCoding NO).
//
//  The nil-URL paths are pinned as characterization: both methods @throw an
//  NSError object (not an NSException), so a @catch (NSException *) will not
//  see them.  See BUGS.md.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataTable.h>

// The Xcode suite's -setUp/-tearDown pair, as file-scope statics: a fresh
// scratch file per test, removed when the test ends.  Each test brackets its
// body with these calls the way the XCTest runner bracketed the method.
static NSURL *gBaseScratchFileURL = nil;

static void baseSetUp(void) {
	NSString *name = [[NSString alloc] initWithFormat:@"MADDataTableBaseTests-%@.mdcache", [[NSUUID UUID] UUIDString]];
	gBaseScratchFileURL = [[NSURL alloc] initFileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:name]];
}

static void baseTearDown(void) {
	[[NSFileManager defaultManager] removeItemAtURL:gBaseScratchFileURL error:NULL];
	[gBaseScratchFileURL release];
	gBaseScratchFileURL = nil;
}

static MADDataColumn *columnNamed(NSString *name) {
	MADDataColumn *column = [MADDataColumn newDataColumnWithIdentifier:name];
	column.type = MADDataTypeString;
	[column addObject:@"alpha"];
	[column addObject:@"beta"];
	return column;
}

#pragma mark - Initializers

static void testInitWithNumberOfColumnsDefaults(void) {
	MADDataTable *table = [[MADDataTable alloc] initWithNumberOfColumns:3];

	MAD_PASS_EQUAL(table.name, @"", "the default name");
	MAD_PASS(table.columnKeys != nil, "columnKeys exists");
	MAD_PASS(table.columns != nil, "columns exists");
	MAD_PASS(table.sortDescriptors != nil, "sortDescriptors exists");
	MAD_PASS(table.columnKeys.count == (NSUInteger)0, "no column keys");
	MAD_PASS(table.columns.count == (NSUInteger)0, "no columns");
	MAD_PASS(table.rowCounter == (NSUInteger)0, "row counter is zero");
	MAD_PASS(table.tag == (NSUInteger)0, "tag defaults to zero");
}

#pragma mark - Plist shape

static void testCopyPlistShape(void) {
	MADDataTable *table = [[MADDataTable alloc] initWithId:7];
	table.name = @"MADDataTableBaseTests";
	table.rowCounter = 2;
	MADDataColumn *column = columnNamed(@"title");
	[table.columnKeys addObject:@"title"];
	table.columns[@"title"] = column;

	NSDictionary *plist = [table copyPlist];

	MAD_PASS(plist.count == (NSUInteger)4, "the plist carries four keys");
	MAD_PASS_EQUAL(plist[@"name"], @"MADDataTableBaseTests", "the name");
	MAD_PASS_EQUAL(plist[@"columnKeys"], (@[@"title"]), "the column keys");
	MAD_PASS_EQUAL(plist[@"rowCounter"], @2, "the row counter");
	NSDictionary *columnsPlist = plist[@"columns"];
	MAD_PASS([columnsPlist isKindOfClass:[NSDictionary class]], "columns is a dictionary");
	MAD_PASS([columnsPlist[@"title"] isKindOfClass:[NSDictionary class]], "the column plist is a dictionary");
	MAD_PASS_EQUAL(columnsPlist[@"title"][@"identifier"], @"title", "the column keeps its identifier");
}

static void testLoadWithPlistRejectsNonDictionary(void) {
	MADDataTable *table = [[MADDataTable alloc] initWithId:0];
	NSError *error = nil;

	BOOL success = [table loadWithPlist:(NSDictionary *)@"not a plist" error:&error];

	MAD_PASS(!success, "a non-dictionary plist is rejected");
	MAD_PASS(error.code == -4, "error code -4");
	MAD_PASS_EQUAL(error.domain, MADDataTableErrorDomain, "the MADDataTable error domain");
}

static void testLoadWithPlistRejectsMissingColumnKeys(void) {
	MADDataTable *table = [[MADDataTable alloc] initWithId:0];
	NSError *error = nil;

	BOOL success = [table loadWithPlist:@{ @"name": @"x" } error:&error];

	MAD_PASS(!success, "column keys are required");
	MAD_PASS(error.code == -5, "error code -5");
}

static void testLoadWithPlistRejectsMissingColumnData(void) {
	MADDataTable *table = [[MADDataTable alloc] initWithId:0];
	NSError *error = nil;

	BOOL success = [table loadWithPlist:@{ @"name": @"x", @"columnKeys": @[@"a"] } error:&error];

	MAD_PASS(!success, "column data is required");
	MAD_PASS(error.code == -6, "error code -6");
}

static void testLoadWithPlistBuildsColumnsAndRestoresMetadata(void) {
	MADDataTable *source = [[MADDataTable alloc] initWithId:3];
	source.name = @"MADDataTableBaseTests";
	source.rowCounter = 2;
	MADDataColumn *column = columnNamed(@"title");
	[source.columnKeys addObject:@"title"];
	source.columns[@"title"] = column;

	MADDataTable *restored = [[MADDataTable alloc] initWithId:0];
	NSError *error = nil;
	BOOL success = [restored loadWithPlist:[source copyPlist] error:&error];

	MAD_PASS(success, "the plist loads");
	MAD_PASS(error == nil, "no error");
	MAD_PASS_EQUAL(restored.name, @"MADDataTableBaseTests", "the name");
	MAD_PASS(restored.rowCounter == (NSUInteger)2, "the row counter");
	MAD_PASS_EQUAL(restored.columnKeys, (@[@"title"]), "the column keys");
	MAD_PASS([restored.columns[@"title"] isKindOfClass:[MADDataColumn class]], "the column was rebuilt");
	MAD_PASS_EQUAL([restored.columns[@"title"] objectAtIndex:1], @"beta", "the column data survived");
}

#pragma mark - NSCoding

static void testBaseNSCodingRoundTrip(void) {
	MADDataTable *table = [[MADDataTable alloc] initWithId:9];
	table.name = @"MADDataTableBaseTests";
	table.rowCounter = 4;
	MADDataColumn *column = columnNamed(@"title");
	[table.columnKeys addObject:@"title"];
	table.columns[@"title"] = column;

	// MADDataTable is NSCoding-only, so the insecure path is the only one it can
	// satisfy (the same shape as MADDatabase; see BUGS.md).  GNUstep has neither
	// -initRequiringSecureCoding: nor -initForReadingFromData:error:, so the
	// portable class pair is the same round trip with secure coding off.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:table];
	MADDataTable *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:data];

	MAD_PASS(decoded != nil, "the table decodes");
	MAD_PASS_EQUAL(decoded.name, @"MADDataTableBaseTests", "the name survived");
	MAD_PASS(decoded.rowCounter == (NSUInteger)4, "the row counter survived");
	MAD_PASS(decoded.tag == (NSUInteger)9, "the tag survived");
	MAD_PASS_EQUAL(decoded.columnKeys, (@[@"title"]), "the column keys survived");
	MAD_PASS([decoded.columns[@"title"] isKindOfClass:[MADDataColumn class]], "the column survived");
}

#pragma mark - Caching

static void testCacheAndLoadRoundTripThroughAFile(void) {
	baseSetUp();
	MADDataTable *table = [[MADDataTable alloc] initWithId:5];
	table.name = @"MADDataTableBaseTests";
	table.rowCounter = 1;
	MADDataColumn *column = columnNamed(@"title");
	[table.columnKeys addObject:@"title"];
	table.columns[@"title"] = column;

	NSError *error = nil;
	MAD_PASS([table cacheWithUrl:gBaseScratchFileURL error:&error], "the table cached to a file (%s)",
			 error != nil ? [[error description] UTF8String] : "no error");

	MADDataTable *restored = [[MADDataTable alloc] initWithId:0];
	NSError *loadError = nil;
	MAD_PASS([restored loadFromCacheWithUrl:gBaseScratchFileURL error:&loadError], "the table loads from the cache (%s)",
			 loadError != nil ? [[loadError description] UTF8String] : "no error");

	MAD_PASS_EQUAL(restored.name, @"MADDataTableBaseTests", "the name");
	MAD_PASS(restored.rowCounter == (NSUInteger)1, "the row counter");
	MAD_PASS_EQUAL(restored.columnKeys, (@[@"title"]), "the column keys");
	MAD_PASS([restored.columns[@"title"] isKindOfClass:[MADDataColumn class]], "the column");
	baseTearDown();
}

// Characterization of a defect documented in BUGS.md: these two throw the NSError
// object itself, so `@catch (NSException *)` will not catch them.
static void testCacheWithNilUrlThrowsTheErrorObject(void) {
	MADDataTable *table = [[MADDataTable alloc] initWithId:0];

	@try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
		// The nil is the point of the test: the parameter is declared nonnull.
		[table cacheWithUrl:(NSURL *)nil error:NULL];
#pragma clang diagnostic pop
		MAD_PASS(NO, "a nil URL throws");
	} @catch (id thrown) {
		MAD_PASS([thrown isKindOfClass:[NSError class]], "the thrown object is an NSError");
		MAD_PASS(((NSError *)thrown).code == -22, "the error code is -22");
		MAD_PASS_EQUAL(((NSError *)thrown).domain, @"MADDataTable", "the error domain");
	}
}

static void testLoadFromCacheWithNilUrlThrowsTheErrorObject(void) {
	MADDataTable *table = [[MADDataTable alloc] initWithId:0];

	@try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
		// The nil is the point of the test: the parameter is declared nonnull.
		[table loadFromCacheWithUrl:(NSURL *)nil error:NULL];
#pragma clang diagnostic pop
		MAD_PASS(NO, "a nil URL throws");
	} @catch (id thrown) {
		MAD_PASS([thrown isKindOfClass:[NSError class]], "the thrown object is an NSError");
		MAD_PASS(((NSError *)thrown).code == -213, "the error code is -213");
	}
}

MAD_TEST_MAIN("MADDataTableBaseTests",
	MAD_TEST(testInitWithNumberOfColumnsDefaults),
	MAD_TEST(testCopyPlistShape),
	MAD_TEST(testLoadWithPlistRejectsNonDictionary),
	MAD_TEST(testLoadWithPlistRejectsMissingColumnKeys),
	MAD_TEST(testLoadWithPlistRejectsMissingColumnData),
	MAD_TEST(testLoadWithPlistBuildsColumnsAndRestoresMetadata),
	MAD_TEST(testBaseNSCodingRoundTrip),
	MAD_TEST(testCacheAndLoadRoundTripThroughAFile),
	MAD_TEST(testCacheWithNilUrlThrowsTheErrorObject),
	MAD_TEST(testLoadFromCacheWithNilUrlThrowsTheErrorObject));
