//
//  MADReportExporterTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the export seam: MADReportExporterRegistry (the lookup the CLI
//  reaches a format through) and the value spellings every Foundation format shares
//  (MADReportExportSource).  The formats themselves are exercised end to end on a
//  real document by the Linux suite (Linux/Tests/MADReportExporterTests.m), which
//  opens the London fixture, refreshes it and reads the exports back.
//

#import <XCTest/XCTest.h>

#import <MAD/MADHeadlessDocument.h>
#import <MAD/MADOperationRefresh.h>
#import <MAD/MADOperationRefreshInitialize.h>
#import <MAD/MADOperationRefreshInitalizeMainDataTable.h>
#import <MAD/MADReportExporting.h>
#import <MAD/MADReportFormatter.h>
#import <MAD/MADReportExporterCSV.h>
#import <MAD/MADReportExporterHTML.h>
#import <MAD/MADReportExporterHTMLFlow.h>
#import <MAD/MADReportExporterJSON.h>
#import <MAD/MADReportExporterJSONReport.h>
#import <MAD/MADReportExporterPDF.h>
#import <MAD/MADReportExporterRegistry.h>
#import <MAD/MADReportExporterText.h>
#import <MAD/MADReportExportSource.h>
#import <MAD/MADReportPageBuilder.h>
#import <MAD/MADDatabaseConnection+Constructor.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseCredentals.h>
#import <MADFoundation/MADCredential.h>

#import <MAD/MADPredicateOperator.h>
#import <MAD/MADQueryFull.h>
#import <MAD/MADQueryLinkType.h>
#import <MAD/MADArchiveManager.h>
#import <MAD/MADDocumentStore.h>
#import <MAD/RptqDocument+Extras.h>
#import <MADFoundation/MADDataColumn.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryPredicate.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDocumentElementLabel.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqObject.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqQueryGroup.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqQueryPredicate.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/MADPredicateOperator.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/MADocumentSectionType.h>
#import <MAD/MADSortOrder.h>
#import <MAD/MADSectionRepresentation.h>
#import <MAD/MADSectionsLayout.h>
#import <MAD/MADSectionLayout.h>

#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADSqlite3/MADArrayCaching.h>

#import "sqlite3.h"

#import <math.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADFoundation/NSString+Comparison.h>

#import <CommonCrypto/CommonDigest.h>

// A stub format: the protocol's required methods and nothing else, registered under a
// name no exporter claims so registering one cannot disturb another test.
@interface MADTestReportExporter : NSObject <MADReportExporting>
@end

@implementation MADTestReportExporter

+ (NSString *)formatName { return @"test-format"; }
+ (NSString *)formatDescription { return @"nothing"; }
+ (NSString *)fileExtension { return @"txt"; }
+ (BOOL)requiresOutputPath { return NO; }
+ (BOOL)isAvailable { return YES; }
+ (NSString *)unavailableReason { return nil; }
- (BOOL)exportDocument:(id <MADDocumentDataProtocol>)document
				 toURL:(NSURL *)url
			   options:(MADReportExportOptions)options
				 error:(NSError **)error { return YES; }

@end

// A second class claiming the same name, to make the duplicate claim raise.
@interface MADTestUsurperReportExporter : MADTestReportExporter
@end

@implementation MADTestUsurperReportExporter
@end

// A document whose publication commit can be failed after the rows are staged.
@interface MADFailingPublicationDocument : MADHeadlessDocument
@property (nonatomic) BOOL failPublication;
@end

@implementation MADFailingPublicationDocument
- (BOOL)writePublishedColumnMapData:(NSData *)data
							  toURL:(NSURL *)url
							  error:(NSError * __autoreleasing *)error {
	if (self.failPublication) {
		if (error != NULL) {
			*error = [NSError errorWithDomain: @"MADFailingPublication"
										  code: 1
									  userInfo: @{ NSLocalizedDescriptionKey: @"forced publication failure" }];
		}
		return NO;
	}
	return [super writePublishedColumnMapData: data toURL: url error: error];
}
@end

// Forward declarations for the two helpers defined inside the test implementation
// below; the publishing document's -format override uses them.
static BOOL MADReportExporterRefreshDocument(MADHeadlessDocument *document, NSError **outError);
static RptqQueryPredicate *MADReportExporterAddImpossiblePredicate(MADHeadlessDocument *document);

// A document that publishes a zero-row result the first time it is asked to format,
// so a test can place a publish between an export source's capture and the page walk
// that renders the report.
@interface MADPublishingExportDocument : MADHeadlessDocument
@property (nonatomic) BOOL publishOnNextFormat;
@end

@implementation MADPublishingExportDocument
- (void)format {
	if (self.publishOnNextFormat) {
		self.publishOnNextFormat = NO;
		RptqQueryPredicate *predicate = MADReportExporterAddImpossiblePredicate(self);
		NSError *error = nil;
		MADReportExporterRefreshDocument(self, &error);
	}
	[super format];
}
@end

@interface MADReportExporterTests : XCTestCase
@end

@implementation MADReportExporterTests

#pragma mark - The registry

- (void)testTheBuiltInFormatsAreRegisteredByLinking {
	// +load is what registers them, so this is the "a framework that links its
	// exporters has them" check, the way the driver registry's suite is.
	NSArray <NSString *> *names = [MADReportExporterRegistry registeredFormatNames];
	XCTAssertTrue([names containsObject: @"csv"]);
	XCTAssertTrue([names containsObject: @"json"]);
	XCTAssertTrue([names containsObject: @"text"]);

	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"csv"], [MADReportExporterCSV class]);
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"json"], [MADReportExporterJSON class]);
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"text"], [MADReportExporterText class]);
}

- (void)testTheFormatNamesAreSorted {
	NSArray <NSString *> *names = [MADReportExporterRegistry registeredFormatNames];
	XCTAssertEqualObjects(names, [names sortedArrayUsingSelector: @selector(compare:)],
						  @"the names are handed out in one order, so a usage line reads the same twice");
}

- (void)testLookupIsCaseInsensitiveAndAnUnknownNameIsNil {
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"JSON"], [MADReportExporterJSON class]);
	XCTAssertNil([MADReportExporterRegistry exporterClassForFormat: @"yaml"]);
	XCTAssertNil([MADReportExporterRegistry exporterClassForFormat: @""]);
}

- (void)testRegistrationIsVisibleThroughTheLookup {
	[MADReportExporterRegistry registerExporterClass: [MADTestReportExporter class]];
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"test-format"], [MADTestReportExporter class]);
	XCTAssertTrue([[MADReportExporterRegistry registeredExporterClasses] containsObject: [MADTestReportExporter class]]);
	XCTAssertNoThrow([MADReportExporterRegistry registerExporterClass: [MADTestReportExporter class]]);
}

// The render-side formats: json-report and the two HTML ones read the page walk,
// which is compiled on both platforms now (docs/developers/build/linux.md §9 Phase E); pdf draws with
// Core Graphics and is Apple's, so it registers everywhere and says so.
- (void)testTheRenderSideFormatsAreRegistered {
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"html"], [MADReportExporterHTML class]);
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"html-flow"], [MADReportExporterHTMLFlow class]);
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"pdf"], [MADReportExporterPDF class]);

	XCTAssertTrue([MADReportExporterHTML isAvailable]);
	XCTAssertTrue([MADReportExporterHTMLFlow isAvailable]);
	XCTAssertEqualObjects([MADReportExporterHTML fileExtension], @"html");
	XCTAssertEqualObjects([MADReportExporterHTMLFlow fileExtension], @"html");
	XCTAssertFalse([MADReportExporterHTML requiresOutputPath], @"a file a browser opens writes to a stream");
	XCTAssertFalse([MADReportExporterHTMLFlow requiresOutputPath], @"the same");
}

- (void)testThePDFFormatDrawsHereAndNeedsAFile {
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"pdf"], [MADReportExporterPDF class]);
	XCTAssertTrue([MADReportExporterPDF isAvailable]);
	XCTAssertNil([MADReportExporterPDF unavailableReason]);
	XCTAssertEqualObjects([MADReportExporterPDF fileExtension], @"pdf");
	XCTAssertTrue([MADReportExporterPDF requiresOutputPath], @"Core Graphics writes a file, not a stream");
}

- (void)testTheReportFormatIsRegisteredAndAnswersForThisPlatform {
	Class <MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat: @"json-report"];
	XCTAssertEqual(exporterClass, [MADReportExporterJSONReport class]);
	XCTAssertEqualObjects([exporterClass fileExtension], @"json", @"the report member rides in the json shape");
	XCTAssertTrue([exporterClass isKindOfClass: [NSObject class]]);
	XCTAssertTrue([MADReportExporterJSONReport isSubclassOfClass: [MADReportExporterJSON class]],
				  @"the report format is the json format plus one member");

	// The render half is Apple's, so this build answers yes and gives no reason --
	// the Linux port of this suite asserts the opposite, with the reason.
	XCTAssertTrue([exporterClass isAvailable]);
	XCTAssertNil([exporterClass unavailableReason]);
}

- (void)testASecondExporterForOneNameRaises {
	[MADReportExporterRegistry registerExporterClass: [MADTestReportExporter class]];
	// The claim has to fail loudly: keeping one of two formats silently would make
	// which one runs depend on +load order.
	XCTAssertThrows([MADReportExporterRegistry registerExporterClass: [MADTestUsurperReportExporter class]]);
}

#pragma mark - The shared spellings

- (void)testQuotedStringEscapesTheJSONMetacharacters {
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"plain"], @"\"plain\"");
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"a\"b"], @"\"a\\\"b\"");
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"a\\b"], @"\"a\\\\b\"");
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"a\nb\tc\rd"], @"\"a\\nb\\tc\\rd\"");
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"\001"], @"\"\\u0001\"");
	// Anything above the control range is written as itself: the file is UTF-8, and a
	// reader that takes UTF-8 reads it back.
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"Cláudio"], @"\"Cláudio\"");
}

- (void)testNumbersAreSpelledInOneRoundTripForm {
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @1], @"1");
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @(-42)], @"-42");
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @3.5], @"3.5");
	// An integral real prints without a fraction: a JSON reader sees the integer it is.
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @3.0], @"3");
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @0.99], @"0.99");
	// 0.1 + 0.2 is not 0.3, and the spelling round-trips rather than flattering it.
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @(0.1 + 0.2)], @"0.30000000000000004");
	// The huge integer stays an integer: it is an NSNumber of long long, not a double.
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @9007199254740993LL], @"9007199254740993");
}

- (void)testDatesAreISO8601InUTC {
	NSDate *epoch = [NSDate dateWithTimeIntervalSince1970: 979257600];	// 2001-01-12 00:00:00Z
	XCTAssertEqualObjects([MADReportExportSource stringForDate: epoch], @"2001-01-12T00:00:00Z");
}

#pragma mark - The London fixture, exported end to end

//  The Mac-side half of the digest gate (the Linux half is
//  Linux/Tests/MADReportExporterTests.m): the same London fixture, the same
//  refresh chain and the same FNV-1a checksums the Linux suite pins, so the
//  "same bytes on both platforms" claim (docs/developers/cli.md's `mad export` section)
//  is asserted on Apple too rather than assumed (docs/project/registers/BUGS.md, "The pinned
//  cross-platform export digests went stale on the Apple side").
//  __FILE__ is the source's absolute path: MADTests -> MAD -> the repository
//  root.
static NSString *MADReportExporterFixturePath(void) {
	NSString *testFile = [@(__FILE__) stringByDeletingLastPathComponent];
	NSString *repositoryRoot = [[testFile stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
	return [[repositoryRoot stringByAppendingPathComponent: @"CLI/Fixtures"]
			stringByAppendingPathComponent: @"London.portable.mad"];
}

static NSString *MADReportExporterSampleDatabasePath(void) {
	NSString *testFile = [@(__FILE__) stringByDeletingLastPathComponent];
	NSString *repositoryRoot = [[testFile stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
	return [[repositoryRoot stringByAppendingPathComponent:
			 @"MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset"]
			stringByAppendingPathComponent: @"chinook.sqlite3"];
}

// The document's Sqlite3 connection stores a bare filename and MADURLFactory
// resolves it against the app-support directory, so the sample goes there.
static void MADReportExporterInstallSampleDatabase(void) {
	NSString *samplePath = MADReportExporterSampleDatabasePath();
	if (![[NSFileManager defaultManager] fileExistsAtPath: samplePath]) return;

	NSURL *supportDirectory = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID: [MADApplication groupIdentifier]];
	NSURL *target = [supportDirectory URLByAppendingPathComponent: @"chinook.sqlite3"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager createDirectoryAtURL: supportDirectory withIntermediateDirectories: YES attributes: nil error: NULL];
	[fileManager removeItemAtURL: target error: NULL];
	[fileManager copyItemAtURL: [NSURL fileURLWithPath: samplePath] toURL: target error: NULL];
}

/// The opened, refreshed fixture, or nil.  One document per process, and one
/// refresh, which every export test then reads.
static MADHeadlessDocument *MADReportExporterRefreshedDocument(void) {
	static MADHeadlessDocument *document = nil;
	static BOOL refreshed = NO;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		MADReportExporterInstallSampleDatabase();
		document = [MADHeadlessDocument documentWithContentsOfURL: [NSURL fileURLWithPath: MADReportExporterFixturePath()]
														   error: NULL];
	});
	if (document == nil || refreshed) return document;

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
	refreshed = queue.operationCount == 0 && refresh.errors.count == 0;
	return document;
}

static NSURL *MADReportExporterOutputURL(NSString *name) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	return [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: name]];
}

static NSData *MADReportExporterOutput(Class <MADReportExporting> exporterClass, NSString *name, NSString **errorDescription) {
	MADHeadlessDocument *document = MADReportExporterRefreshedDocument();
	if (document == nil) return nil;

	NSURL *url = MADReportExporterOutputURL(name);
	id <MADReportExporting> exporter = [[(Class)exporterClass alloc] init];
	NSError *error = nil;
	if (![exporter exportDocument: document toURL: url options: MADReportExportOptionsNone error: &error]) {
		*errorDescription = [error description];
		return nil;
	}
	return [NSData dataWithContentsOfURL: url];
}

#pragma mark - Publication fixtures

/// A fresh copy of the London fixture under a unique name, so opening it does not
/// unarchive over the shared export fixture's guts.
static MADFailingPublicationDocument *MADReportExporterNewPublicationDocument(void) {
	MADReportExporterInstallSampleDatabase();
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory
							  withIntermediateDirectories: YES
											   attributes: NULL
													error: NULL];
	NSString *name = [NSString stringWithFormat: @"publication-%@.mad", [[NSUUID UUID] UUIDString]];
	NSURL *copy = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: name]];
	NSError *error = nil;
	if (![[NSFileManager defaultManager] copyItemAtURL: [NSURL fileURLWithPath: MADReportExporterFixturePath()]
												 toURL: copy
												 error: &error]) {
		return nil;
	}
	return (MADFailingPublicationDocument *)[MADFailingPublicationDocument documentWithContentsOfURL: copy error: &error];
}

static BOOL MADReportExporterRefreshDocument(MADHeadlessDocument *document, NSError **outError) {
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
	if (outError != NULL && refresh.errors.count > 0) {
		*outError = refresh.errors.firstObject;
	}
	return queue.operationCount == 0 && refresh.errors.count == 0;
}

// An equality predicate on an integer field with a value the fixture cannot hold.
// The projection is unchanged; the result is zero rows.
static RptqQueryPredicate *MADReportExporterAddImpossiblePredicate(MADHeadlessDocument *document) {
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = document.activeDocumentModel.defaultDatabase.defaultQuery;
	RptqQueryField *field = nil;
	for (RptqQueryTable *table in query.hasQueryTables) {
		for (RptqQueryField *candidate in table.hasQueryFields) {
			int16_t type = candidate.databaseSchemaField.dataType;
			if (type == MADDataTypeInteger || type == MADDataTypeLong ||
				type == MADDataTypeLongLong || type == MADDataTypeShort) {
				field = candidate;
				break;
			}
		}
		if (field != nil) break;
	}
	if (field == nil) return nil;

	RptqQueryPredicate *predicate =
		(RptqQueryPredicate *)[context insertObjectForEntity: @"RptqQueryPredicate" identifier: 0];
	predicate.comparson = (int16_t)MADPredicateOperatorEqual;
	predicate.hasLeftField = field;
	predicate.rigthFieldID = @"-1";
	[query addHasQueryPredicateObject: predicate];
	return predicate;
}

static void MADReportExporterRemovePredicate(MADHeadlessDocument *document, RptqQueryPredicate *predicate) {
	if (predicate == nil) return;
	RptqQuery *query = document.activeDocumentModel.defaultDatabase.defaultQuery;
	[query removeHasQueryPredicateObject: predicate];
	[document.storeContext deleteObject: predicate error: NULL];
}

/// FNV-1a, 64 bit: the whole output's bytes in one number, the same checksum
/// the Linux suite pins (Linux/Tests/MADReportExporterTests.m), so a spelling
/// that differs between GNUstep and Apple fails here rather than going
/// unnoticed.
static uint64_t MADReportExporterChecksum(NSData *data) {
	uint64_t hash = 14695981039346656037ULL;
	const uint8_t *bytes = data.bytes;
	for (NSUInteger index = 0; index < data.length; index++) {
		hash ^= (uint64_t)bytes[index];
		hash *= 1099511628211ULL;
	}
	return hash;
}

static NSString *MADReportExporterSHA256(NSData *data) {
	unsigned char digest[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
	NSMutableString *hex = [[NSMutableString alloc] initWithCapacity: CC_SHA256_DIGEST_LENGTH * 2];
	for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
		[hex appendFormat: @"%02x", digest[index]];
	}
	return hex;
}

- (void)testTheExportsMatchTheLinuxPinnedChecksums {
	MADHeadlessDocument *document = MADReportExporterRefreshedDocument();
	XCTSkipIf(document == nil, @"the London fixture could not be opened and refreshed");

	struct {
		Class exporterClass;
		NSString *name;
		uint64_t checksum;
	} formats[] = {
		{ [MADReportExporterText class], @"london.txt", 0x03008506CF27F6EFULL },
		{ [MADReportExporterCSV class], @"london.csv", 0xFF1C607E7D2F3391ULL },
		{ [MADReportExporterJSON class], @"london.json", 0xB548747AC759A4ABULL },
		{ [MADReportExporterJSONReport class], @"london.report.json", 0x499761E44D3BDD39ULL },
		{ [MADReportExporterHTML class], @"london.html", 0xC3B163A710CA3B6FULL },
		{ [MADReportExporterHTMLFlow class], @"london.flow.html", 0x6310CBA068B4934FULL },
	};
	for (NSUInteger index = 0; index < sizeof(formats) / sizeof(formats[0]); index++) {
		NSString *errorDescription = nil;
		NSData *data = MADReportExporterOutput(formats[index].exporterClass, formats[index].name, &errorDescription);
		XCTAssertNotNil(data, @"the %@ export failed: %@", formats[index].name, errorDescription);
		if (data == nil) continue;
		XCTAssertEqualObjects(@(MADReportExporterChecksum(data)), @(formats[index].checksum),
							  @"the %@ export's bytes are the ones the Linux suite pins", formats[index].name);
	}
}

- (void)testTheReproducibleWriteMatchesTheLinuxPinnedBytes {
	MADHeadlessDocument *document = MADReportExporterRefreshedDocument();
	XCTSkipIf(document == nil, @"the London fixture could not be opened and refreshed");

	NSURL *url = MADReportExporterOutputURL(@"london-copy.mad");
	NSError *error = nil;
	XCTAssertTrue([document writeToURL: url reproducible: YES error: &error],
				  @"the reproducible write failed: %@", error);
	NSData *data = [NSData dataWithContentsOfURL: url];
	XCTAssertNotNil(data);
	if (data == nil) return;
	// The writer's bytes are not touched by the export order -- the cache is a
	// companion file, not a document member -- so this pin stays as it was.
	XCTAssertEqual(data.length, (NSUInteger)16261);
	XCTAssertEqualObjects(MADReportExporterSHA256(data), @"09815b24e91e03b6e526008f7c2700074fed10679771b9e1ee4609e54a1192f5");
}

- (void)testTheFormatterComparesStringGroupKeysByTheDefinedOrder {
	//  The formatter walks group boundaries with its own string comparator
	//  (+compareValue:withValue:forDataType:), and the cache's ORDER BY sorts
	//  the same keys with the LSASC collation; both must agree with
	//  -[NSString mad_orderedCompare:] on every pair, or the sections the walk
	//  finds will not be the sections the ORDER BY produced (docs/developers/cli.md's
	//  `mad export` section).
	NSArray *keys = @[@"", @"a", @"A", @"B", @"b", @"Core", @"[1997] Black Light Syndrome",
					  @"Ä", @"ä", @"Zebra", @"ac/dc", @"AC/DC", @"Straße", @"strabe"];
	for (NSString *lhs in keys) {
		for (NSString *rhs in keys) {
			XCTAssertEqual([MADReportFormatter compareValue: lhs
												  withValue: rhs
												forDataType: MADDataTypeString],
						   [lhs mad_orderedCompare: rhs],
						   @"the formatter and -mad_orderedCompare: agree on '%@' vs '%@'", lhs, rhs);
		}
	}
}

#pragma mark - Publication

- (void)testSuccessfulRefreshPublishesOneCompleteResult {
	MADHeadlessDocument *document = MADReportExporterNewPublicationDocument();
	XCTAssertNotNil(document, @"the London fixture could not be copied and opened");
	NSError *error = nil;
	XCTAssertTrue(MADReportExporterRefreshDocument(document, &error), @"%@", error);

	MADDataResult *result = document.currentResult;
	XCTAssertNotNil(result);
	XCTAssertGreaterThan(result.identifier.length, (NSUInteger)0);
	XCTAssertNotNil(result.rowDatabaseURL);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath: result.rowDatabaseURL.path]);
	XCTAssertEqualObjects(result.columnMapURL.path, document.urlDataTableCache.path);
	XCTAssertEqual(result.numberOfRows, document.numberOfResults);
	XCTAssertEqual(result.numberOfRows, (NSUInteger)76);
	XCTAssertEqualObjects(result.columnKeys, document.mainQuery.fieldKeys,
						  @"the published columns are the active-field projection");
	for (NSString *key in result.columnKeys) {
		XCTAssertNotNil(result.columns[key], @"the column map has %@", key);
		XCTAssertEqualObjects(result.columns[key].identifier, key);
	}

	// The stable column map reopens as the same result through the normal cache path.
	MADDataTableFast *reopened = [[MADDataTableFast alloc] initWithId: document.filename.hash];
	reopened.cacheDelegate = document;
	XCTAssertTrue([reopened loadFromCacheWithUrl: document.urlDataTableCache error: &error], @"%@", error);
	XCTAssertEqual(reopened.numberOfRows, result.numberOfRows);
	XCTAssertEqual(reopened.columnKeys.count, result.columnKeys.count);
}

- (void)testZeroRowRefreshPublishesTheProjectedColumns {
	MADHeadlessDocument *document = MADReportExporterNewPublicationDocument();
	XCTAssertNotNil(document);
	RptqQueryPredicate *predicate = MADReportExporterAddImpossiblePredicate(document);
	XCTAssertNotNil(predicate, @"the fixture has an integer query field to constrain");

	NSError *error = nil;
	XCTAssertTrue(MADReportExporterRefreshDocument(document, &error), @"%@", error);
	MADDataResult *result = document.currentResult;
	XCTAssertNotNil(result);
	XCTAssertEqual(result.numberOfRows, (NSUInteger)0);
	XCTAssertGreaterThan(result.columnKeys.count, (NSUInteger)0);
	XCTAssertEqualObjects(result.columnKeys, document.mainQuery.fieldKeys);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath: result.rowDatabaseURL.path]);
}

- (void)testFailedPublicationLeavesTheLastResultUsable {
	MADFailingPublicationDocument *document = MADReportExporterNewPublicationDocument();
	XCTAssertNotNil(document);
	NSError *error = nil;
	XCTAssertTrue(MADReportExporterRefreshDocument(document, &error), @"%@", error);

	MADDataResult *a = document.currentResult;
	XCTAssertNotNil(a);
	NSUInteger aRows = a.numberOfRows;
	NSArray<NSString *> *aKeys = a.columnKeys;
	NSString *aIdentifier = a.identifier;
	NSString *aRowPath = a.rowDatabaseURL.path;
	XCTAssertEqual(aRows, (NSUInteger)76);

	// A consumer that pinned A before the failed refresh.
	MADReportExportSource *pinned = [MADReportExportSource sourceWithDocument: document error: &error];
	XCTAssertNotNil(pinned);
	XCTAssertEqual(pinned.numberOfRows, aRows);
	XCTAssertEqualObjects(pinned.columnKeys, aKeys);

	// B is a different result: same projection, zero rows.  Its rows are written,
	// then the publication commit is forced to fail.
	RptqQueryPredicate *predicate = MADReportExporterAddImpossiblePredicate(document);
	XCTAssertNotNil(predicate);
	document.failPublication = YES;
	error = nil;
	XCTAssertFalse(MADReportExporterRefreshDocument(document, &error),
				   @"the forced publication must fail the refresh");
	XCTAssertNotNil(error);
	document.failPublication = NO;
	MADReportExporterRemovePredicate(document, predicate);

	// A is still the published generation, with its rows and column map intact.
	MADDataResult *current = document.currentResult;
	XCTAssertNotNil(current);
	XCTAssertEqualObjects(current.identifier, aIdentifier);
	XCTAssertEqualObjects(current.columnKeys, aKeys);
	XCTAssertEqual(current.numberOfRows, aRows);
	XCTAssertEqualObjects(current.rowDatabaseURL.path, aRowPath);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath: aRowPath]);

	// The pinned consumer and a fresh one both read A through the export source.
	MADReportExportSource *fresh = [MADReportExportSource sourceWithDocument: document error: &error];
	XCTAssertNotNil(fresh);
	for (MADReportExportSource *source in @[pinned, fresh]) {
		XCTAssertEqual(source.numberOfRows, aRows);
		XCTAssertEqualObjects(source.columnKeys, aKeys);
		NSDictionary *firstRow = source.rowEnumerator.nextObject;
		XCTAssertNotNil(firstRow);
		for (NSString *key in aKeys) {
			XCTAssertNotNil(firstRow[key], @"the row still has %@", key);
		}
	}
}

- (void)testRenderOperationPinsOneGeneration {
	MADHeadlessDocument *document = MADReportExporterNewPublicationDocument();
	XCTAssertNotNil(document, @"the London fixture could not be copied and opened");
	if (document == nil) return;

	NSError *error = nil;
	XCTAssertTrue(MADReportExporterRefreshDocument(document, &error), @"%@", error);
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)76);

	// Render A: the formatter pins the render data source to A.
	[MADReportPageBuilder prepareDocumentForRender: document];
	XCTAssertGreaterThan(document.reportFormatter.numberOfPages, (NSUInteger)0);
	NSDictionary *firstA = [document dataForRowReportFirst];
	XCTAssertNotNil(firstA, @"A's first detail row is readable");

	// Publish a visibly different B: zero rows, same projection.
	RptqQueryPredicate *predicate = MADReportExporterAddImpossiblePredicate(document);
	XCTAssertNotNil(predicate);
	XCTAssertTrue(MADReportExporterRefreshDocument(document, &error), @"%@", error);
	XCTAssertEqual(document.numberOfResults, (NSUInteger)0);
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)0);

	// The in-flight render operation is still pinned to A.
	NSDictionary *stillFirstA = [document dataForRowReportFirst];
	XCTAssertNotNil(stillFirstA, @"the pinned render still reads A's first row");
	XCTAssertEqualObjects(stillFirstA, firstA, @"the pinned render reads the same A row");

	// A new render pins B and re-paginates.
	[MADReportPageBuilder prepareDocumentForRender: document];
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)0);
	XCTAssertNil([document dataForRowReportFirst], @"B has no detail row to read");

	MADReportExporterRemovePredicate(document, predicate);
}

- (void)testFailedFirstRefreshThenRetryPublishes {
	MADFailingPublicationDocument *document = MADReportExporterNewPublicationDocument();
	XCTAssertNotNil(document);
	document.failPublication = YES;
	NSError *error = nil;
	XCTAssertFalse(MADReportExporterRefreshDocument(document, &error));
	XCTAssertNotNil(error);
	XCTAssertNil(document.currentResult);
	XCTAssertEqual(document.numberOfResults, (NSUInteger)0);

	document.failPublication = NO;
	error = nil;
	XCTAssertTrue(MADReportExporterRefreshDocument(document, &error), @"%@", error);
	XCTAssertNotNil(document.currentResult);
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)76);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath: document.currentResult.rowDatabaseURL.path]);
}

#pragma mark - Composition

/// Deletes one file by path.  Windows' compat `unistd.h` maps `close` to `_close`,
/// so the test declares only the delete call and never includes that header.
static int MADCompositionDeleteFile(NSString *path) {
#if defined(_WIN32)
	extern int _unlink(const char *);
	return _unlink(path.UTF8String);
#else
	extern int unlink(const char *);
	return unlink(path.UTF8String);
#endif
}

static BOOL MADCompositionCreateSource(NSURL *url, NSArray<NSString *> *statements) {
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: url];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	database.databaseConnection = connection;
	[database openDatabase];
	NSError *error = nil;
	BOOL success = YES;
	for (NSString *statement in statements) {
		if (![database executeSQL: statement
						fieldKeys: @[]
					 onConnection: nil
				  intoResultTable: nil
				   transactionSet: NO
				   returnsResults: NO
				   binaryBindings: nil
						withError: &error]) {
			success = NO;
			break;
		}
	}
	// Close explicitly so the setup never leaves the source file open for the test.
	[database closeConnection: nil];
	return success;
}

static BOOL MADCompositionAddQuery(MADHeadlessDocument *document,
								   NSString *tableName,
								   NSArray<NSString *> *activeFields) {
	RptqStoreContext *context = document.storeContext;
	RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqDatabase *database = rptqDocument.hasDatabaseSchemas.anyObject;
	RptqDatabaseSchemaTable *schemaTable = nil;
	for (RptqDatabaseSchemaTable *candidate in database.hasTables) {
		if ([candidate.name isEqualToString: tableName]) { schemaTable = candidate; break; }
	}
	if (schemaTable == nil) return NO;

	RptqQueryTable *queryTable = [RptqQueryTable newQueryTableForSchemaTable: schemaTable
																	database: database
													 forManagedObjectContext: context];
	NSMutableSet *queryFields = [NSMutableSet set];
	for (RptqDatabaseSchemaField *schemaField in schemaTable.hasFields) {
		if (![activeFields containsObject: schemaField.name]) continue;
		RptqQueryField *queryField = [RptqQueryField newQueryField: context];
		queryField.inQueryTable = queryTable;
		queryField.databaseSchemaField = schemaField;
		[queryFields addObject: queryField];
		RptqDocumentElementLabelDataField *label =
			(RptqDocumentElementLabelDataField *)[context insertObjectForEntity:
				NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier: 0];
		label.referencesQueryField = queryField;
	}
	queryTable.hasQueryFields = queryFields;
	NSError *error = nil;
	return [context save: &error];
}

static MADHeadlessDocument *MADCompositionDocument(NSString *name,
												   NSURL *sourceURL,
												   NSString *tableName,
												   NSArray<NSString *> *activeFields,
												   NSString **outError) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *documentURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: name]];

	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: sourceURL];
	NSError *error = nil;
	MADHeadlessDocument *document = [MADHeadlessDocument createDocumentAtURL: documentURL
													  withDatabaseConnection: connection
																 credentials: nil
																	   error: &error];
	if (document == nil) { if (outError) *outError = error.description; return nil; }
	if (!MADCompositionAddQuery(document, tableName, activeFields)) { if (outError) *outError = @"no query"; return nil; }
	if (!MADReportExporterRefreshDocument(document, &error)) { if (outError) *outError = error.description; return nil; }
	return document;
}

static NSString *MADCompositionLogicalKey(MADDataResult *result, NSString *fieldName) {
	for (NSString *key in result.columnKeys) {
		if ([key rangeOfString: fieldName].location != NSNotFound) {
			return key;
		}
	}
	return nil;
}

static MADDatabaseSqlite3 *MADCompositionConnection(NSURL *composerURL) {
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: composerURL];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	database.databaseConnection = connection;
	[database openDatabaseWithFlags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_URI];
	return database;
}

/// Builds a composed invoices/payments document through the production store and
/// archive writers, with a downstream-only join key on the payments side, and
/// reopens it as a headless document ready to refresh.
static MADHeadlessDocument *MADCompositionComposedDocument(NSString *directory, NSString **outError) {
	NSURL *invoicesURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"invoices.sqlite"]];
	NSURL *paymentsURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"payments.sqlite"]];
	NSURL *madURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"composed.mad"]];

	if (!MADCompositionCreateSource(invoicesURL, @[
		@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL, city TEXT);",
		// Deliberately shuffled so an ascending invoice_id group has to reorder them.
		@"INSERT INTO invoices VALUES (3, 300.0, 'Paris');",
		@"INSERT INTO invoices VALUES (1, 100.0, 'London');",
		@"INSERT INTO invoices VALUES (2, 200.0, 'Paris');"])) {
		if (outError) *outError = @"invoices source";
		return nil;
	}
	if (!MADCompositionCreateSource(paymentsURL, @[
		@"CREATE TABLE payments (payment_id INTEGER, invoice_id INTEGER, amount REAL);",
		@"INSERT INTO payments VALUES (101, 1, 40.0);",
		@"INSERT INTO payments VALUES (102, 1, 60.0);"])) {
		if (outError) *outError = @"payments source";
		return nil;
	}

	MADDocumentStore *store = [MADDocumentStore storeForDocumentURL: madURL];
	NSError *error = nil;
	if (![store openWithError: &error]) {
		if (outError) *outError = error.description;
		return nil;
	}
	RptqStoreContext *context = store.context;
	[context loadAllWithError: NULL];

	RptqObject *(^insert)(NSString *, int64_t) = ^(NSString *entity, int64_t identifier) {
		return [context insertObjectForEntity: entity identifier: identifier];
	};

	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext: context];

	// A source: database, credential, schema table + fields, named query, query
	// table and the query fields it projects (a label makes a field active).
	RptqObject *(^source)(NSURL *, NSString *, int64_t, int64_t, int64_t, NSArray<NSString *> *) =
		^(NSURL *url, NSString *queryName, int64_t dbId, int64_t queryId, int64_t tableId, NSArray<NSString *> *labelled) {
		RptqObject *database = insert(@"RptqDatabase", dbId);
		[database setValue: @"Sqlite 3" forKey: @"databaseDriverType"];
		RptqObject *credential = insert(@"RptqDatabaseCredentals", 0);
		[credential setValue: url.lastPathComponent forKey: @"dbname"];
		[credential setValue: url.path forKey: @"host"];
		[database setValue: credential forKey: @"ownedByUser"];

		RptqObject *table = insert(@"RptqDatabaseSchemaTable", tableId + 1);
		[table setValue: queryName forKey: @"name"];
		RptqObject *idField = insert(@"RptqDatabaseSchemaField", tableId + 2);
		[idField setValue: @"invoice_id" forKey: @"name"];
		RptqObject *amountField = insert(@"RptqDatabaseSchemaField", tableId + 3);
		[amountField setValue: @"amount" forKey: @"name"];
		[database setValue: @[ table ] forKey: @"hasTables"];
		[table setValue: @[ idField, amountField ] forKey: @"hasFields"];

		RptqObject *query = insert(@"RptqQuery", queryId);
		[query setValue: queryName forKey: @"name"];
		[database setValue: @[ query ] forKey: @"hasQueries"];
		RptqObject *queryTable = insert(@"RptqQueryTable", tableId);
		[queryTable setValue: table forKey: @"databaseSchemaTable"];
		[queryTable setValue: query forKey: @"inQuery"];

		NSMutableArray *fields = [NSMutableArray array];
		for (RptqObject *schemaField in @[ idField, amountField ]) {
			RptqObject *field = insert(@"RptqQueryField", 0);
			[field setValue: schemaField forKey: @"databaseSchemaField"];
			[field setValue: queryTable forKey: @"inQueryTable"];
			[fields addObject: field];
			if ([labelled containsObject: [schemaField valueForKey: @"name"]]) {
				RptqObject *label = insert(@"RptqDocumentElementLabelDataField", 0);
				[label setValue: field forKey: @"referencesQueryField"];
			}
		}
		[queryTable setValue: fields forKey: @"hasQueryFields"];
		return query;
	};

	RptqObject *invoices = source(invoicesURL, @"invoices", 10, 101, 200, @[ @"invoice_id", @"amount" ]);
	RptqObject *payments = source(paymentsURL, @"payments", 20, 102, 300, @[ @"amount" ]);

	// A predicate-only field on the payments source: payment_id is in the source table
	// but is neither an output nor a join key, so a filter on it is evaluated without the
	// value joining the source's projection (narrow projection).
	RptqObject *paymentsSchemaTable = [context objectForEntity: @"RptqDatabaseSchemaTable" identifier: 301];
	RptqObject *paymentIdSchemaField = [context insertObjectForEntity: @"RptqDatabaseSchemaField" identifier: 304];
	[paymentIdSchemaField setValue: @"payment_id" forKey: @"name"];
	NSMutableArray *paymentsFields = [[paymentsSchemaTable valueForKey: @"hasFields"] mutableCopy];
	[paymentsFields addObject: paymentIdSchemaField];
	[paymentsSchemaTable setValue: paymentsFields forKey: @"hasFields"];

	RptqObject *paymentsQueryTable = [context objectForEntity: @"RptqQueryTable" identifier: 300];
	RptqObject *paymentIdQueryField = [context insertObjectForEntity: @"RptqQueryField" identifier: 0];
	[paymentIdQueryField setValue: paymentIdSchemaField forKey: @"databaseSchemaField"];
	[paymentIdQueryField setValue: paymentsQueryTable forKey: @"inQueryTable"];
	NSMutableArray *paymentsQueryFields = [[paymentsQueryTable valueForKey: @"hasQueryFields"] mutableCopy];
	[paymentsQueryFields addObject: paymentIdQueryField];
	[paymentsQueryTable setValue: paymentsQueryFields forKey: @"hasQueryFields"];

	// A London-style text field on the invoices source, absent from the outputs, so a
	// root text predicate can filter on it without it becoming visible.
	RptqObject *invoicesSchemaTable = [context objectForEntity: @"RptqDatabaseSchemaTable" identifier: 201];
	RptqObject *citySchemaField = [context insertObjectForEntity: @"RptqDatabaseSchemaField" identifier: 204];
	[citySchemaField setValue: @"city" forKey: @"name"];
	[citySchemaField setValue: @(MADDataTypeString) forKey: @"dataType"];
	NSMutableArray *invoicesFields = [[invoicesSchemaTable valueForKey: @"hasFields"] mutableCopy];
	[invoicesFields addObject: citySchemaField];
	[invoicesSchemaTable setValue: invoicesFields forKey: @"hasFields"];

	RptqObject *invoicesQueryTable = [context objectForEntity: @"RptqQueryTable" identifier: 200];
	RptqObject *cityQueryField = [context insertObjectForEntity: @"RptqQueryField" identifier: 0];
	[cityQueryField setValue: citySchemaField forKey: @"databaseSchemaField"];
	[cityQueryField setValue: invoicesQueryTable forKey: @"inQueryTable"];
	NSMutableArray *invoicesQueryFields = [[invoicesQueryTable valueForKey: @"hasQueryFields"] mutableCopy];
	[invoicesQueryFields addObject: cityQueryField];
	[invoicesQueryTable setValue: invoicesQueryFields forKey: @"hasQueryFields"];

	RptqObject *invoicesDB = [invoices valueForKey: @"inDatabase"];
	RptqObject *paymentsDB = [payments valueForKey: @"inDatabase"];
	[document setValue: @[ invoicesDB, paymentsDB ] forKey: @"hasDatabaseSchemas"];

	RptqObject *root = insert(@"RptqQuery", 100);
	[root setValue: @"root" forKey: @"name"];
	[root setValue: invoicesDB forKey: @"inDatabase"];
	RptqObject *rootInvoices = insert(@"RptqQueryTable", 400);
	[rootInvoices setValue: root forKey: @"inQuery"];
	[rootInvoices setValue: invoices forKey: @"upstreamQuery"];
	RptqObject *rootPayments = insert(@"RptqQueryTable", 401);
	[rootPayments setValue: root forKey: @"inQuery"];
	[rootPayments setValue: payments forKey: @"upstreamQuery"];

	RptqObject *invoiceIdField = [context objectForEntity: @"RptqDatabaseSchemaField" identifier: 202];
	RptqObject *invoiceAmountField = [context objectForEntity: @"RptqDatabaseSchemaField" identifier: 203];
	RptqObject *paymentIdField = [context objectForEntity: @"RptqDatabaseSchemaField" identifier: 302];
	RptqObject *paymentAmountField = [context objectForEntity: @"RptqDatabaseSchemaField" identifier: 303];

	RptqObject *leftKey = insert(@"RptqQueryField", 500);
	[leftKey setValue: invoiceIdField forKey: @"databaseSchemaField"];
	[leftKey setValue: rootInvoices forKey: @"inQueryTable"];
	RptqObject *rightKey = insert(@"RptqQueryField", 501);
	[rightKey setValue: paymentIdField forKey: @"databaseSchemaField"];
	[rightKey setValue: rootPayments forKey: @"inQueryTable"];
	RptqObject *join = insert(@"RptqQueryLinks", 450);
	[join setValue: @(MADLinkTypeLeftOuterJoin) forKey: @"type"];
	[join setValue: leftKey forKey: @"hasLeftField"];
	[join setValue: rightKey forKey: @"hasRightField"];
	[join setValue: root forKey: @"inQuery"];

	RptqObject *out0 = insert(@"RptqQueryField", 600);
	[out0 setValue: invoiceIdField forKey: @"databaseSchemaField"];
	[out0 setValue: rootInvoices forKey: @"inQueryTable"];
	[out0 setValue: @"invoice_id" forKey: @"outputKey"];
	[out0 setValue: @0 forKey: @"outputIndex"];
	RptqObject *out1 = insert(@"RptqQueryField", 601);
	[out1 setValue: invoiceAmountField forKey: @"databaseSchemaField"];
	[out1 setValue: rootInvoices forKey: @"inQueryTable"];
	[out1 setValue: @"invoice_amount" forKey: @"outputKey"];
	[out1 setValue: @1 forKey: @"outputIndex"];
	RptqObject *out2 = insert(@"RptqQueryField", 602);
	[out2 setValue: paymentAmountField forKey: @"databaseSchemaField"];
	[out2 setValue: rootPayments forKey: @"inQueryTable"];
	[out2 setValue: @"payment_amount" forKey: @"outputKey"];
	[out2 setValue: @2 forKey: @"outputIndex"];

	// A root field for the London-style text filter: it is neither an output nor a
	// join key, so it is materialized for the root's WHERE but never projected.
	RptqObject *cityRootField = insert(@"RptqQueryField", 603);
	[cityRootField setValue: citySchemaField forKey: @"databaseSchemaField"];
	[cityRootField setValue: rootInvoices forKey: @"inQueryTable"];

	[document setValue: root forKey: @"rootQuery"];

	if (![context saveComposed: &error]) {
		if (outError) *outError = error.description;
		return nil;
	}
	[store close];
	MADArchiveManager *writer = [[MADArchiveManager alloc] initWithFileWrapperURL: store.gutsURL archiveURL: madURL];
	writer.composed = YES;
	if (![writer archive: YES]) {
		if (outError) *outError = @"archive";
		return nil;
	}

	MADHeadlessDocument *result = [MADHeadlessDocument documentWithContentsOfURL: madURL error: &error];
	if (result == nil && outError) *outError = error.description;
	return result;
}

- (void)testComposedRefreshProducesRoot {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionComposedDocument(directory, &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	NSError *error = nil;
	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: document];
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: refresh];
	while (queue.operationCount > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
								 beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
	}
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);
	XCTAssertNotNil(document.currentResult);

	XCTAssertEqualObjects(document.currentResult.columnKeys, (@[ @"invoice_id", @"invoice_amount", @"payment_amount" ]));
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)4);
}

- (void)testComposedGroupingSortsByOutputKeysAndBreaksGroups {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionComposedDocument(directory, &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	// Add two nested groups to the root: invoice_id ascending, then payment_amount
	// descending -- the same way the app's add-group path does, and the fields both
	// upstream sources could name "amount" distinguish by their root output keys.
	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqQuery *root = model.rootQuery;
	XCTAssertNotNil(root);
	if (root == nil) return;

	NSArray<RptqQueryField *> *outputs = [model orderedCompositionOutputsWithError: NULL];
	RptqQueryField *invoiceIdField = nil;
	RptqQueryField *paymentAmountField = nil;
	for (RptqQueryField *field in outputs) {
		if ([field.outputKey isEqualToString: @"invoice_id"]) invoiceIdField = field;
		if ([field.outputKey isEqualToString: @"payment_amount"]) paymentAmountField = field;
	}
	XCTAssertNotNil(invoiceIdField);
	XCTAssertNotNil(paymentAmountField);
	if (invoiceIdField == nil || paymentAmountField == nil) return;

	void (^addGroup)(RptqQueryField *, MADSortOrder, int16_t) = ^(RptqQueryField *field, MADSortOrder order, int16_t weight) {
		RptqQueryGroup *group = [RptqQueryGroup newQueryGroupQueryWithSortOrder: order andManagedObjectContext: context];
		group.hasField = field;
		group.weight = weight;
		RptqDocumentSection *header = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupHeader forManagedObjectContext: context];
		[group addHasSectionObject: header];
		RptqDocumentSection *footer = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupFooter forManagedObjectContext: context];
		[group addHasSectionObject: footer];
		[root addHasQueryGroupsObject: group];
	};
	addGroup(invoiceIdField, MADSortOrderAccending, 0);
	addGroup(paymentAmountField, MADSortOrderDecending, 1);

	NSError *saveError = nil;
	XCTAssertTrue([context save: &saveError], @"%@", saveError);

	// The root's group fields resolve to output keys, not "<alias>.<field>" (which a
	// composed output field has none of), with their declared direction.
	NSArray<NSSortDescriptor *> *descriptors = [root sortDescriptorsForDatabase: document.database];
	XCTAssertEqual(descriptors.count, (NSUInteger)2);
	if (descriptors.count == 2) {
		XCTAssertEqualObjects(descriptors[0].key, @"invoice_id");
		XCTAssertTrue(descriptors[0].ascending);
		XCTAssertEqualObjects(descriptors[1].key, @"payment_amount");
		XCTAssertFalse(descriptors[1].ascending);
	}

	// Refresh, then sort through the document's own path (readCurrentSortDescriptors
	// must read the root, not the arbitrary default query, which has no groups).
	NSError *refreshError = nil;
	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: document];
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: refresh];
	while (queue.operationCount > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
	}
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);
	[document prepareForQuery];

	// The sorted enumerator (the renderer's own read path) must yield invoice_id
	// ascending and payment_amount descending within invoice 1, so the document's
	// readCurrentSortDescriptors read the root and resolved the output keys.
	MADDataTableFast *table = document.dataTable;
	XCTAssertEqual(table.numberOfRows, (NSUInteger)4);
	NSMutableArray<NSNumber *> *invoiceIds = [NSMutableArray array];
	NSMutableArray<NSNumber *> *payments = [NSMutableArray array];
	for (NSDictionary *row in [table enumeratorForKeyObjectsSorted]) {
		id inv = row[@"invoice_id"];
		id pay = row[@"payment_amount"];
		[invoiceIds addObject: inv ? @([inv doubleValue]) : @(NAN)];
		[payments addObject: (pay && pay != [NSNull null]) ? @([pay doubleValue]) : @(NAN)];
	}
	XCTAssertEqual(invoiceIds.count, (NSUInteger)4);
	XCTAssertEqual(invoiceIds[0].doubleValue, 1.0);
	XCTAssertEqual(invoiceIds[1].doubleValue, 1.0);
	XCTAssertEqual(invoiceIds[2].doubleValue, 2.0);
	XCTAssertEqual(invoiceIds[3].doubleValue, 3.0);
	XCTAssertEqual(payments.count, (NSUInteger)4);
	XCTAssertEqual(payments[0].doubleValue, 60.0);
	XCTAssertEqual(payments[1].doubleValue, 40.0);
	XCTAssertTrue(isnan(payments[2].doubleValue));
	XCTAssertTrue(isnan(payments[3].doubleValue));

	// The renderer sees two groups and emits group breaks and all four detail rows.
	[document format];
	MADReportFormatter *formatter = document.reportFormatter;
	XCTAssertEqual(formatter.numberOfGroups, (NSUInteger)2);
	NSMutableSet<NSNumber *> *bodyRows = [NSMutableSet set];
	NSUInteger groupHeaders = 0;
	for (NSUInteger page = 0; page < formatter.reportLayout.count; page++) {
		for (MADSectionRepresentation *section in formatter.reportLayout[page]) {
			if (section.sectionType == MADDocumentSectionTypeGroupHeader) groupHeaders++;
			if (section.sectionType == MADDocumentSectionTypeBody) [bodyRows addObject: @(section.detailRowId)];
		}
	}
	XCTAssertGreaterThan(groupHeaders, (NSUInteger)0);
	XCTAssertEqual(bodyRows.count, (NSUInteger)4);
}

static RptqQuery *MADCompositionQueryNamed(RptqDocument *model, NSString *name) {
	for (RptqDatabase *db in model.hasDatabaseSchemas) {
		for (RptqQuery *q in db.hasQueries) {
			if ([q.name isEqualToString:name]) return q;
		}
	}
	return nil;
}

static RptqQueryField *MADCompositionFieldNamed(RptqQuery *query, NSString *name) {
	for (RptqQueryTable *qt in query.hasQueryTables) {
		for (RptqQueryField *f in qt.hasQueryFields) {
			if ([f.databaseSchemaField.name isEqualToString:name]) return f;
		}
	}
	return nil;
}

static RptqQueryField *MADCompositionRootOutputNamed(RptqDocument *model, NSString *outputKey) {
	for (RptqQueryField *f in [model orderedCompositionOutputsWithError: NULL]) {
		if ([f.outputKey isEqualToString:outputKey]) return f;
	}
	return nil;
}

static RptqQueryField *MADCompositionRootFieldNamed(RptqDocument *model, NSString *name) {
	for (RptqQueryTable *qt in model.rootQuery.hasQueryTables) {
		for (RptqQueryField *f in qt.hasQueryFields) {
			if ([f.databaseSchemaField.name isEqualToString:name]) return f;
		}
	}
	return nil;
}

static double MADCompositionValue(MADDataTableFast *table, NSUInteger row, NSString *key) {
	NSDictionary *dict = [table dataForRow:row column:key error:NULL];
	id value = dict[key];
	if (value == nil || value == [NSNull null]) return NAN;
	return [value doubleValue];
}

- (void)testComposedSourcePredicateFiltersTheSource {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionComposedDocument(directory, &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqQuery *payments = MADCompositionQueryNamed(model, @"payments");
	RptqQueryField *amountField = MADCompositionFieldNamed(payments, @"amount");
	XCTAssertNotNil(payments);
	XCTAssertNotNil(amountField);

	NSError *error = nil;
	RptqQueryPredicate *predicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID: amountField.identifier
																				comparsonOperator: MADPredicateOperatorGreaterThan
																					andRightValue: @"50"
																			forManagedObjectContext: context
																						  error: &error];
	XCTAssertNotNil(predicate, @"%@", error);
	[payments addHasQueryPredicateObject: predicate];
	XCTAssertTrue([context save: &error], @"%@", error);

	// Re-archive and reopen so the predicate round-trips the production save path.
	XCTAssertTrue([document writeToURL: document.fileURL reproducible: NO error: &error], @"%@", error);
	MADHeadlessDocument *reopened = [MADHeadlessDocument documentWithContentsOfURL: document.fileURL error: &error];
	XCTAssertNotNil(reopened, @"%@", error);
	if (reopened == nil) return;

	RptqDocument *reopenedModel = [RptqDocument newDocumentReadFromManagedObjectContext: reopened.storeContext];
	XCTAssertEqual(MADCompositionQueryNamed(reopenedModel, @"payments").hasQueryPredicate.count, (NSUInteger)1);
	XCTAssertEqual(MADCompositionQueryNamed(reopenedModel, @"invoices").hasQueryPredicate.count, (NSUInteger)0);

	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: reopened];
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: refresh];
	while (queue.operationCount > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
	}
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);

	// amount > 50 on payments leaves only payment 60; the left join keeps invoices 2 and 3.
	// The composed result has no ORDER BY, so compare by invoice_id rather than by row.
	XCTAssertEqual(reopened.currentResult.numberOfRows, (NSUInteger)3);
	MADDataTableFast *table = reopened.dataTable;
	NSMutableDictionary<NSNumber *, id> *rowsByInvoice = [NSMutableDictionary dictionary];
	for (NSUInteger r = 1; r <= table.numberOfRows; r++) {
		NSInteger invoice = (NSInteger)MADCompositionValue(table, r, @"invoice_id");
		double payment = MADCompositionValue(table, r, @"payment_amount");
		rowsByInvoice[@(invoice)] = isnan(payment) ? [NSNull null] : @(payment);
	}
	XCTAssertEqual(rowsByInvoice.count, (NSUInteger)3);
	XCTAssertEqual([rowsByInvoice[@1] doubleValue], 60.0);
	XCTAssertEqualObjects(rowsByInvoice[@2], [NSNull null]);
	XCTAssertEqualObjects(rowsByInvoice[@3], [NSNull null]);
}

- (void)testComposedSourcePredicateOnNonReturnedFieldPreservesProjection {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionComposedDocument(directory, &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqQuery *payments = MADCompositionQueryNamed(model, @"payments");
	RptqQueryField *paymentIdField = MADCompositionFieldNamed(payments, @"payment_id");
	XCTAssertNotNil(paymentIdField);

	// Filter on payment_id, which is neither an output nor a join key, so the value is
	// used to evaluate the filter but never becomes a visible root output.
	NSError *error = nil;
	RptqQueryPredicate *predicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID: paymentIdField.identifier
																				comparsonOperator: MADPredicateOperatorEqual
																					andRightValue: @"101"
																			forManagedObjectContext: context
																						  error: &error];
	XCTAssertNotNil(predicate, @"%@", error);
	[payments addHasQueryPredicateObject: predicate];
	XCTAssertTrue([context save: &error], @"%@", error);

	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: document];
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: refresh];
	while (queue.operationCount > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
	}
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);

	// payment_id stays out of the root projection.
	XCTAssertEqualObjects(document.currentResult.columnKeys, (@[ @"invoice_id", @"invoice_amount", @"payment_amount" ]));
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)3);

	// Only payment 101 (amount 40) survives; invoices 2 and 3 stay, with blank payments.
	MADDataTableFast *table = document.dataTable;
	NSMutableDictionary<NSNumber *, id> *rowsByInvoice = [NSMutableDictionary dictionary];
	for (NSUInteger r = 1; r <= table.numberOfRows; r++) {
		NSInteger invoice = (NSInteger)MADCompositionValue(table, r, @"invoice_id");
		double payment = MADCompositionValue(table, r, @"payment_amount");
		rowsByInvoice[@(invoice)] = isnan(payment) ? [NSNull null] : @(payment);
	}
	XCTAssertEqual(rowsByInvoice.count, (NSUInteger)3);
	XCTAssertEqual([rowsByInvoice[@1] doubleValue], 40.0);
	XCTAssertEqualObjects(rowsByInvoice[@2], [NSNull null]);
	XCTAssertEqualObjects(rowsByInvoice[@3], [NSNull null]);
}

- (void)testComposedRootPredicateFiltersTheRoot {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionComposedDocument(directory, &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqQuery *root = model.rootQuery;
	RptqQueryField *paymentAmount = nil;
	for (RptqQueryField *output in [model orderedCompositionOutputsWithError: NULL]) {
		if ([output.outputKey isEqualToString: @"payment_amount"]) paymentAmount = output;
	}
	XCTAssertNotNil(root);
	XCTAssertNotNil(paymentAmount);

	NSError *error = nil;
	RptqQueryPredicate *predicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID: paymentAmount.identifier
																				comparsonOperator: MADPredicateOperatorGreaterThan
																					andRightValue: @"50"
																			forManagedObjectContext: context
																						  error: &error];
	XCTAssertNotNil(predicate, @"%@", error);
	[root addHasQueryPredicateObject: predicate];
	XCTAssertTrue([context save: &error], @"%@", error);

	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: document];
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: refresh];
	while (queue.operationCount > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
	}
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);

	// The root predicate filters the joined rows: payment_amount > 50 keeps only
	// payment 60, and the null payments of invoices 2 and 3 fail the comparison.
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)1);
	XCTAssertEqualObjects(document.currentResult.columnKeys, (@[ @"invoice_id", @"invoice_amount", @"payment_amount" ]));
	MADDataTableFast *table = document.dataTable;
	XCTAssertEqual(MADCompositionValue(table, 1, @"invoice_id"), 1.0);
	XCTAssertEqual(MADCompositionValue(table, 1, @"invoice_amount"), 100.0);
	XCTAssertEqual(MADCompositionValue(table, 1, @"payment_amount"), 60.0);
}

- (void)testComposedChildAndRootPredicatesBothApply {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionComposedDocument(directory, &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	NSError *error = nil;

	// Child: amount > 50 on payments, so only payment 60 survives the source query.
	RptqQuery *payments = MADCompositionQueryNamed(model, @"payments");
	RptqQueryField *paymentsAmount = MADCompositionFieldNamed(payments, @"amount");
	RptqQueryPredicate *child = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID: paymentsAmount.identifier
																		comparsonOperator: MADPredicateOperatorGreaterThan
																			andRightValue: @"50"
																	forManagedObjectContext: context error: &error];
	XCTAssertNotNil(child, @"%@", error);
	[payments addHasQueryPredicateObject: child];

	// Root: invoice_amount < 250, so only invoices 1 and 2 survive the join's WHERE.
	RptqQueryField *invoiceAmount = MADCompositionRootOutputNamed(model, @"invoice_amount");
	RptqQueryPredicate *root = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID: invoiceAmount.identifier
																		comparsonOperator: MADPredicateOperatorLessThan
																			andRightValue: @"250"
																	forManagedObjectContext: context error: &error];
	XCTAssertNotNil(root, @"%@", error);
	[model.rootQuery addHasQueryPredicateObject: root];
	XCTAssertTrue([context save: &error], @"%@", error);

	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: document];
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: refresh];
	while (queue.operationCount > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
	}
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);

	// Both take effect: the child drops payment 40, the root drops invoice 3.
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)2);
	MADDataTableFast *table = document.dataTable;
	NSMutableDictionary<NSNumber *, id> *rowsByInvoice = [NSMutableDictionary dictionary];
	for (NSUInteger r = 1; r <= table.numberOfRows; r++) {
		NSInteger invoice = (NSInteger)MADCompositionValue(table, r, @"invoice_id");
		double payment = MADCompositionValue(table, r, @"payment_amount");
		rowsByInvoice[@(invoice)] = isnan(payment) ? [NSNull null] : @(payment);
	}
	XCTAssertEqual(rowsByInvoice.count, (NSUInteger)2);
	XCTAssertEqual([rowsByInvoice[@1] doubleValue], 60.0);
	XCTAssertEqualObjects(rowsByInvoice[@2], [NSNull null]);
}

- (void)testComposedRootTextPredicateOnNonOutputField {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionComposedDocument(directory, &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqQueryField *city = MADCompositionRootFieldNamed(model, @"city");
	XCTAssertNotNil(city);

	NSError *error = nil;
	RptqQueryPredicate *predicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID: city.identifier
																				comparsonOperator: MADPredicateOperatorEqual
																					andRightValue: @"London"
																			forManagedObjectContext: context error: &error];
	XCTAssertNotNil(predicate, @"%@", error);
	[model.rootQuery addHasQueryPredicateObject: predicate];
	XCTAssertTrue([context save: &error], @"%@", error);

	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: document];
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: refresh];
	while (queue.operationCount > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
	}
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);

	// London's two payments survive; city never becomes a visible output.
	XCTAssertEqualObjects(document.currentResult.columnKeys, (@[ @"invoice_id", @"invoice_amount", @"payment_amount" ]));
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)2);
	MADDataTableFast *table = document.dataTable;
	XCTAssertEqual(MADCompositionValue(table, 1, @"invoice_id"), 1.0);
	XCTAssertEqual(MADCompositionValue(table, 2, @"invoice_id"), 1.0);
}

- (void)testComposedRootFieldToFieldPredicateAcrossInputs {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionComposedDocument(directory, &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqQueryField *invoiceAmount = MADCompositionRootOutputNamed(model, @"invoice_amount");
	RptqQueryField *paymentAmount = MADCompositionRootOutputNamed(model, @"payment_amount");
	XCTAssertNotNil(invoiceAmount);
	XCTAssertNotNil(paymentAmount);

	// invoice_amount > payment_amount: both fields are named "amount" upstream, so the
	// comparison has to resolve each to its own input.
	NSError *error = nil;
	RptqQueryPredicate *predicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID: invoiceAmount.identifier
																				comparsonOperator: MADPredicateOperatorGreaterThan
																				  andRightFieldID: paymentAmount.identifier
																			forManagedObjectContext: context error: &error];
	XCTAssertNotNil(predicate, @"%@", error);
	[model.rootQuery addHasQueryPredicateObject: predicate];
	XCTAssertTrue([context save: &error], @"%@", error);

	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: document];
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: refresh];
	while (queue.operationCount > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
	}
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);

	// invoice 1's two payments satisfy 100 > 40 and 100 > 60; invoices 2 and 3 have a
	// null payment, so their comparison is null and fails.
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)2);
	MADDataTableFast *table = document.dataTable;
	XCTAssertEqual(MADCompositionValue(table, 1, @"invoice_id"), 1.0);
	XCTAssertEqual(MADCompositionValue(table, 1, @"payment_amount"), 40.0);
	XCTAssertEqual(MADCompositionValue(table, 2, @"invoice_id"), 1.0);
	XCTAssertEqual(MADCompositionValue(table, 2, @"payment_amount"), 60.0);
}



- (void)testCompositionAttachGuards {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *invoicesURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"invoices.sqlite"]];
	MADCompositionCreateSource(invoicesURL, @[
		@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL, note TEXT);",
		@"INSERT INTO invoices VALUES (1, 100.0, 'first');",
		@"INSERT INTO invoices VALUES (2, 200.0, 'second');",
		@"INSERT INTO invoices VALUES (3, 300.0, 'third');"]);

	NSString *errorDescription = nil;
	MADHeadlessDocument *invoices = MADCompositionDocument(@"invoices.mad", invoicesURL, @"invoices",
														   @[@"invoice_id", @"amount"], &errorDescription);
	XCTAssertNotNil(invoices, @"%@", errorDescription);
	if (invoices == nil) return;

	NSURL *composerURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"composer.sqlite"]];
	MADDatabaseSqlite3 *composer = MADCompositionConnection(composerURL);
	NSError *error = nil;
	XCTAssertTrue([composer attachReadOnlyDatabaseAtURL: invoices.currentResult.rowDatabaseURL asName: @"inv" error: &error]);

	NSString *writeSQL = [NSString stringWithFormat: @"INSERT INTO inv.%@ DEFAULT VALUES", invoices.currentResult.dataTable.tableName];
	BOOL wrote = [composer executeSQL: writeSQL fieldKeys: @[] onConnection: nil intoResultTable: nil
					  transactionSet: NO returnsResults: NO binaryBindings: nil withError: &error];
	XCTAssertFalse(wrote, @"a write into the read-only attachment is refused");

	error = nil;
	NSURL *missing = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"nope.maddb"]];
	XCTAssertFalse([composer attachReadOnlyDatabaseAtURL: missing asName: @"bad" error: &error]);
	XCTAssertNotNil(error);
	XCTAssertEqual(invoices.currentResult.numberOfRows, (NSUInteger)3);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath: invoices.currentResult.rowDatabaseURL.path]);

	for (NSUInteger i = 2; i <= 11; i++) {
		NSString *name = [NSString stringWithFormat: @"db%lu", (unsigned long)i];
		BOOL ok = [composer attachReadOnlyDatabaseAtURL: invoices.currentResult.rowDatabaseURL asName: name error: &error];
		if (i <= 10) {
			XCTAssertTrue(ok, @"attachment %lu accepted", (unsigned long)i);
		} else {
			XCTAssertFalse(ok, @"the eleventh attachment is refused");
			XCTAssertNotNil(error);
		}
	}
}


- (void)testCompositionAttachUnicodeReservedPathAndAlias {
	// A unique root so the run never collides with a previous run's files; the tail
	// still carries Unicode and URI-reserved characters in the path.
	NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	NSString *directory = [root stringByAppendingPathComponent: @"Café ?#% ü"];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *db = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"data ?#%.sqlite"]];
	XCTAssertTrue(MADCompositionCreateSource(db, @[
		@"CREATE TABLE t (id INTEGER, v TEXT);",
		@"INSERT INTO t VALUES (1, 'one');"]));

	NSURL *composerURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"composer.sqlite"]];
	MADDatabaseSqlite3 *composer = MADCompositionConnection(composerURL);
	NSError *error = nil;
	// A space-containing alias, and a path with Unicode and URI-reserved characters.
	XCTAssertTrue([composer attachReadOnlyDatabaseAtURL: db asName: @"my attached db" error: &error], @"%@", error);
	BOOL wrote = [composer executeSQL: @"INSERT INTO \"my attached db\".t DEFAULT VALUES"
							fieldKeys: @[] onConnection: nil intoResultTable: nil
					   transactionSet: NO returnsResults: NO binaryBindings: nil withError: &error];
	XCTAssertFalse(wrote, @"the attached file is read-only through its encoded path and quoted alias");
}

- (void)testCompositionAttachmentLimitAndSQLiteVersion {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *db = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"invoices.sqlite"]];
	XCTAssertTrue(MADCompositionCreateSource(db, @[
		@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL);",
		@"INSERT INTO invoices VALUES (1, 100.0);"]));

	NSString *errorDescription = nil;
	MADHeadlessDocument *invoices = MADCompositionDocument(@"invoices.mad", db, @"invoices", @[@"invoice_id"], &errorDescription);
	XCTAssertNotNil(invoices, @"%@", errorDescription);
	if (invoices == nil) return;

	NSURL *composerURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"composer.sqlite"]];
	MADDatabaseSqlite3 *composer = MADCompositionConnection(composerURL);
	sqlite3 *handle = (sqlite3 *)composer.databaseHandle;
	int effectiveLimit = sqlite3_limit(handle, SQLITE_LIMIT_ATTACHED, -1);
	const char *version = sqlite3_libversion();
	printf("composition connection: SQLite %s, effective SQLITE_MAX_ATTACHED %d\n", version, effectiveLimit);
	XCTAssertGreaterThan(effectiveLimit, 0, @"the connection reports its attach limit");

	NSError *error = nil;
	for (int i = 0; i < effectiveLimit; i++) {
		NSString *name = [NSString stringWithFormat: @"db%d", i];
		XCTAssertTrue([composer attachReadOnlyDatabaseAtURL: invoices.currentResult.rowDatabaseURL asName: name error: &error],
					  @"attachment %d within the limit: %@", i, error);
	}
	error = nil;
	XCTAssertFalse([composer attachReadOnlyDatabaseAtURL: invoices.currentResult.rowDatabaseURL asName: @"overflow" error: &error],
				   @"one past the limit is refused");
	XCTAssertNotNil(error);
}


- (void)testCompositionEmptyExpressionKeepsKnownType {
	// A zero-row refresh over a typed column must still expose the column's declared
	// type, not the String fallback for an untyped empty expression.
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *db = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"invoices.sqlite"]];
	XCTAssertTrue(MADCompositionCreateSource(db, @[
		@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL);",
		@"INSERT INTO invoices VALUES (1, 100.0);"]));

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionDocument(@"invoices.mad", db, @"invoices",
														   @[@"invoice_id", @"amount"], &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)1);

	// Force a zero-row refresh.
	RptqQueryPredicate *predicate = MADReportExporterAddImpossiblePredicate(document);
	XCTAssertNotNil(predicate);
	NSError *error = nil;
	XCTAssertTrue(MADReportExporterRefreshDocument(document, &error), @"%@", error);

	MADDataResult *empty = document.currentResult;
	XCTAssertEqual(empty.numberOfRows, (NSUInteger)0);
	NSString *invoiceKey = MADCompositionLogicalKey(empty, @"invoice_id");
	NSString *amountKey = MADCompositionLogicalKey(empty, @"amount");
	XCTAssertNotNil(invoiceKey);
	XCTAssertNotNil(amountKey);
	MADDataType invoiceType = empty.columns[invoiceKey].type;
	MADDataType amountType = empty.columns[amountKey].type;
	XCTAssertEqual(invoiceType, MADDataTypeInteger, @"the empty integer column keeps its declared type");
	XCTAssertEqual(amountType, MADDataTypeDouble, @"the empty real column keeps its declared type");
}

#pragma mark - General N-node composition

/// The connection-string → credential map the composed refresh still accepts, built
/// the way the older callers do: one entry per source database.
static NSDictionary<NSString *, MADCredential *> *MADCompositionCredentialsMap(MADHeadlessDocument *document) {
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	NSMutableDictionary<NSString *, MADCredential *> *map = [NSMutableDictionary dictionary];
	for (RptqDatabase *database in model.hasDatabaseSchemas) {
		if (database.ownedByUser == nil) continue;
		MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnection: database.ownedByUser
																			documentURL: document.fileURL];
		if (connection.connectionString.length > 0) {
			map[connection.connectionString] = [[MADCredential alloc] initWithUsername: @"user" andPassword: @"pass"];
		}
	}
	return map;
}

static MADOperationRefreshComposed *MADCompositionRunRefreshWithCredentials(MADHeadlessDocument *document,
																		 NSDictionary<NSString *, MADCredential *> *credentials) {
	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: document];
	refresh.credentialsByConnectionString = credentials;
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: refresh];
	while (queue.operationCount > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
	}
	return refresh;
}

/// The same credentials keyed by leaf query id, the map `mad serve` supplies.
static NSDictionary<NSNumber *, MADCredential *> *MADCompositionCredentialsByQueryIdentifier(MADHeadlessDocument *document) {
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	NSMutableDictionary<NSNumber *, MADCredential *> *map = [NSMutableDictionary dictionary];
	for (RptqDatabase *database in model.hasDatabaseSchemas) {
		for (RptqQuery *query in database.hasQueries) {
			if (query.hasQueryTables.anyObject.upstreamQuery != nil) continue;
			map[@(query.identifier)] = [[MADCredential alloc] initWithUsername: @"user" andPassword: @"pass"];
		}
	}
	return map;
}

static MADOperationRefreshComposed *MADCompositionRunRefreshWithQueryCredentials(MADHeadlessDocument *document,
																			  NSDictionary<NSNumber *, MADCredential *> *credentials) {
	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: document];
	refresh.credentialsByQueryIdentifier = credentials;
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: refresh];
	while (queue.operationCount > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
	}
	return refresh;
}

/// Runs a composed refresh to completion and returns the operation, for its errors
/// and its executed-node order.
static MADOperationRefreshComposed *MADCompositionRunRefresh(MADHeadlessDocument *document) {
	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: document];
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: refresh];
	while (queue.operationCount > 0) {
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
	}
	return refresh;
}

/// Builds an N-node composed document from leaf and composer descriptions, through
/// the production store and archive writers, reopened as a headless document.
///
/// A leaf is @{@"name", @"file", @"rows"}: one table named after the leaf with two
/// columns, `id` (INTEGER) and `value` (REAL), populated from `rows` (arrays of two
/// numbers).  A composer is @{@"name", @"children", @"links", @"outputs"}:
/// `children` is the ordered list of child names, `links` are [leftChild, leftCol,
/// rightChild, rightCol] left-outer joins over the child columns, and `outputs` are
/// [child, column, outputKey] in the persisted order.
static MADHeadlessDocument *MADCompositionGraphDocument(NSString *directory,
														NSArray<NSDictionary *> *leaves,
														NSArray<NSDictionary *> *composers,
														NSString *rootName,
														NSString **outError) {
	// Write the leaf source databases.
	for (NSDictionary *leaf in leaves) {
		NSString *name = leaf[@"name"];
		NSURL *url = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: leaf[@"file"]]];
		NSMutableArray<NSString *> *statements = [NSMutableArray arrayWithObject:
			[NSString stringWithFormat: @"CREATE TABLE %@ (id INTEGER, value REAL);", name]];
		for (NSArray *row in leaf[@"rows"]) {
			[statements addObject: [NSString stringWithFormat: @"INSERT INTO %@ VALUES (%@, %@);",
				name, [row[0] description], [row[1] description]]];
		}
		if (!MADCompositionCreateSource(url, statements)) {
			if (outError) *outError = [NSString stringWithFormat: @"source %@", name];
			return nil;
		}
	}

	NSURL *madURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"composed.mad"]];
	MADDocumentStore *store = [MADDocumentStore storeForDocumentURL: madURL];
	NSError *error = nil;
	if (![store openWithError: &error]) { if (outError) *outError = error.description; return nil; }
	RptqStoreContext *context = store.context;
	[context loadAllWithError: NULL];

	RptqObject *(^insert)(NSString *, int64_t) = ^(NSString *entity, int64_t identifier) {
		return [context insertObjectForEntity: entity identifier: identifier];
	};

	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext: context];
	__block int64_t counter = 1000;

	// Every node exposes a set of column keys: a leaf's are `id` and `value`, a
	// composer's are its output keys.  `schemaFieldsByName` maps a column key to the
	// underlying schema field, so a parent's field always resolves to the same schema
	// field its child projected.
	NSMutableDictionary<NSString *, RptqObject *> *queryByName = [NSMutableDictionary dictionary];
	NSMutableDictionary<NSString *, NSArray<NSString *> *> *columnsByName = [NSMutableDictionary dictionary];
	NSMutableDictionary<NSString *, NSDictionary<NSString *, RptqObject *> *> *schemaFieldsByName = [NSMutableDictionary dictionary];
	NSMutableDictionary<NSString *, RptqObject *> *schemaTablesByName = [NSMutableDictionary dictionary];
	NSMutableArray<RptqObject *> *databases = [NSMutableArray array];

	for (NSDictionary *leaf in leaves) {
		NSString *name = leaf[@"name"];
		NSURL *url = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: leaf[@"file"]]];

		RptqObject *database = insert(@"RptqDatabase", counter++);
		[database setValue: @"Sqlite 3" forKey: @"databaseDriverType"];
		RptqObject *credential = insert(@"RptqDatabaseCredentals", counter++);
		[credential setValue: url.lastPathComponent forKey: @"dbname"];
		[credential setValue: url.path forKey: @"host"];
		[database setValue: credential forKey: @"ownedByUser"];

		RptqObject *table = insert(@"RptqDatabaseSchemaTable", counter++);
		[table setValue: name forKey: @"name"];
		RptqObject *idField = insert(@"RptqDatabaseSchemaField", counter++);
		[idField setValue: @"id" forKey: @"name"];
		RptqObject *valueField = insert(@"RptqDatabaseSchemaField", counter++);
		[valueField setValue: @"value" forKey: @"name"];
		[database setValue: @[ table ] forKey: @"hasTables"];
		[table setValue: @[ idField, valueField ] forKey: @"hasFields"];

		RptqObject *query = insert(@"RptqQuery", counter++);
		[query setValue: name forKey: @"name"];
		[database setValue: @[ query ] forKey: @"hasQueries"];
		RptqObject *queryTable = insert(@"RptqQueryTable", counter++);
		[queryTable setValue: table forKey: @"databaseSchemaTable"];
		[queryTable setValue: query forKey: @"inQuery"];

		NSMutableArray *fields = [NSMutableArray array];
		for (RptqObject *schemaField in @[ idField, valueField ]) {
			RptqObject *field = insert(@"RptqQueryField", counter++);
			[field setValue: schemaField forKey: @"databaseSchemaField"];
			[field setValue: queryTable forKey: @"inQueryTable"];
			[fields addObject: field];
			RptqObject *label = insert(@"RptqDocumentElementLabelDataField", counter++);
			[label setValue: field forKey: @"referencesQueryField"];
		}
		[queryTable setValue: fields forKey: @"hasQueryFields"];

		queryByName[name] = query;
		columnsByName[name] = @[ @"id", @"value" ];
		schemaFieldsByName[name] = @{ @"id": idField, @"value": valueField };
		schemaTablesByName[name] = table;
		[databases addObject: database];
	}

	[document setValue: databases forKey: @"hasDatabaseSchemas"];

	for (NSDictionary *composer in composers) {
		NSString *name = composer[@"name"];
		NSArray<NSString *> *children = composer[@"children"];
		RptqObject *rootQuery = insert(@"RptqQuery", counter++);
		[rootQuery setValue: name forKey: @"name"];
		[rootQuery setValue: databases.firstObject forKey: @"inDatabase"];

		NSMutableDictionary<NSString *, NSDictionary<NSString *, RptqObject *> *> *fieldsByChild = [NSMutableDictionary dictionary];
		NSMutableArray<RptqObject *> *rootTables = [NSMutableArray array];
		for (NSString *childName in children) {
			RptqObject *childQuery = queryByName[childName];
			RptqObject *rootTable = insert(@"RptqQueryTable", counter++);
			[rootTable setValue: rootQuery forKey: @"inQuery"];
			[rootTable setValue: childQuery forKey: @"upstreamQuery"];

			NSDictionary<NSString *, RptqObject *> *childSchema = schemaFieldsByName[childName];
			NSMutableDictionary<NSString *, RptqObject *> *fieldsByCol = [NSMutableDictionary dictionary];
			NSMutableArray *fields = [NSMutableArray array];
			for (NSString *col in columnsByName[childName]) {
				RptqObject *field = insert(@"RptqQueryField", counter++);
				[field setValue: childSchema[col] forKey: @"databaseSchemaField"];
				[field setValue: rootTable forKey: @"inQueryTable"];
				[fields addObject: field];
				fieldsByCol[col] = field;
			}
			[rootTable setValue: fields forKey: @"hasQueryFields"];
			[rootTables addObject: rootTable];
			fieldsByChild[childName] = fieldsByCol;
		}
		// A composer may also list `remoteTables`: leaf schema tables added as remote
		// (non-upstream) tables, to build a node that mixes both kinds for the
		// mixed-node validation test.
		for (NSString *remoteName in composer[@"remoteTables"]) {
			RptqObject *remoteTable = insert(@"RptqQueryTable", counter++);
			[remoteTable setValue: rootQuery forKey: @"inQuery"];
			[remoteTable setValue: schemaTablesByName[remoteName] forKey: @"databaseSchemaTable"];
			RptqObject *remoteField = insert(@"RptqQueryField", counter++);
			[remoteField setValue: schemaFieldsByName[remoteName][@"id"] forKey: @"databaseSchemaField"];
			[remoteField setValue: remoteTable forKey: @"inQueryTable"];
			[remoteTable setValue: @[ remoteField ] forKey: @"hasQueryFields"];
			[rootTables addObject: remoteTable];
		}
		[rootQuery setValue: rootTables forKey: @"hasQueryTables"];

		NSMutableArray *links = [NSMutableArray array];
		for (NSArray *link in composer[@"links"]) {
			RptqObject *leftField = fieldsByChild[link[0]][link[1]];
			RptqObject *rightField = fieldsByChild[link[2]][link[3]];
			RptqObject *ql = insert(@"RptqQueryLinks", counter++);
			[ql setValue: @(MADLinkTypeLeftOuterJoin) forKey: @"type"];
			[ql setValue: leftField forKey: @"hasLeftField"];
			[ql setValue: rightField forKey: @"hasRightField"];
			[ql setValue: rootQuery forKey: @"inQuery"];
			[links addObject: ql];
		}
		[rootQuery setValue: links forKey: @"hasQueryLinks"];

		NSMutableArray<NSString *> *outputColumns = [NSMutableArray array];
		NSMutableDictionary<NSString *, RptqObject *> *outputSchema = [NSMutableDictionary dictionary];
		NSArray *outputs = composer[@"outputs"];
		[outputs enumerateObjectsUsingBlock: ^(NSArray *output, NSUInteger idx, BOOL *stop) {
			NSString *child = output[0], *col = output[1], *outputKey = output[2];
			RptqObject *field = fieldsByChild[child][col];
			[field setValue: outputKey forKey: @"outputKey"];
			[field setValue: @(idx) forKey: @"outputIndex"];
			[outputColumns addObject: outputKey];
			outputSchema[outputKey] = schemaFieldsByName[child][col];
		}];

		queryByName[name] = rootQuery;
		columnsByName[name] = outputColumns;
		schemaFieldsByName[name] = outputSchema;
	}

	[document setValue: queryByName[rootName] forKey: @"rootQuery"];

	if (![context saveComposed: &error]) { if (outError) *outError = error.description; return nil; }
	[store close];
	MADArchiveManager *writer = [[MADArchiveManager alloc] initWithFileWrapperURL: store.gutsURL archiveURL: madURL];
	writer.composed = YES;
	if (![writer archive: YES]) { if (outError) *outError = @"archive"; return nil; }

	MADHeadlessDocument *result = [MADHeadlessDocument documentWithContentsOfURL: madURL error: &error];
	if (result == nil && outError) *outError = error.description;
	return result;
}

- (void)testComposedCredentialMapPrefersQueryIdentifier {
	NSURL *placeholder = [NSURL fileURLWithPath: [NSTemporaryDirectory() stringByAppendingPathComponent: @"mad-credential-map.mad"]];
	MADHeadlessDocument *document = [[MADHeadlessDocument alloc] initWithFileURL: placeholder];
	MADOperationRefreshComposed *refresh = [[MADOperationRefreshComposed alloc] initWithDocument: document];
	MADCredential *first = [[MADCredential alloc] initWithUsername: @"first" andPassword: @"one"];
	MADCredential *second = [[MADCredential alloc] initWithUsername: @"second" andPassword: @"two"];
	MADCredential *shared = [[MADCredential alloc] initWithUsername: @"shared" andPassword: @"same"];
	MADCredential *fallback = [[MADCredential alloc] initWithUsername: @"fallback" andPassword: @"fb"];
	NSString *connectionString = @"(PostgreSQL)[127.0.0.1:5432]chinook";
	refresh.credentialsByQueryIdentifier = @{ @(10): first, @(11): second };
	refresh.credentialsByConnectionString = @{ connectionString: shared };

	XCTAssertEqualObjects([refresh credentialForQueryIdentifier: 10 connectionString: connectionString fallbackCredential: fallback].username, @"first",
						  @"two query ids sharing one connection string keep different credentials (first)");
	XCTAssertEqualObjects([refresh credentialForQueryIdentifier: 11 connectionString: connectionString fallbackCredential: fallback].username, @"second",
						  @"two query ids sharing one connection string keep different credentials (second)");
	XCTAssertEqualObjects([refresh credentialForQueryIdentifier: 12 connectionString: connectionString fallbackCredential: fallback].username, @"shared",
						  @"a query not in the id map falls back to the connection-string entry");
	XCTAssertEqualObjects([refresh credentialForQueryIdentifier: 12 connectionString: @"(MySQL)[host:3306]other" fallbackCredential: fallback].username, @"fallback",
						  @"a query with no map entry falls back to the single credential");
}

- (void)testComposedRefreshUsesPerSourceCredentialsAndNamesTheFailingSource {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[
		@{ @"name": @"a", @"file": @"a.sqlite", @"rows": @[ @[@1, @10] ] },
		@{ @"name": @"b", @"file": @"b.sqlite", @"rows": @[ @[@1, @20] ] },
	];
	NSArray *composers = @[
		@{ @"name": @"root", @"children": @[ @"a", @"b" ],
		   @"links": @[ @[ @"a", @"id", @"b", @"id" ] ],
		   @"outputs": @[ @[ @"a", @"id", @"a_id" ], @[ @"b", @"value", @"b_value" ] ] },
	];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"root", &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	NSDictionary<NSString *, MADCredential *> *legacy = MADCompositionCredentialsMap(document);
	XCTAssertEqual(legacy.count, (NSUInteger)2);
	XCTAssertEqual(MADCompositionRunRefreshWithCredentials(document, legacy).errors.count, (NSUInteger)0,
				   @"the connection-string credential map still refreshes the composition");

	NSDictionary<NSNumber *, MADCredential *> *credentials = MADCompositionCredentialsByQueryIdentifier(document);
	XCTAssertEqual(credentials.count, (NSUInteger)2);

	MADOperationRefreshComposed *refresh = MADCompositionRunRefreshWithQueryCredentials(document, credentials);
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)1);

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	int64_t bIdentifier = 0;
	RptqDatabaseCredentals *bCredentialRow = nil;
	for (RptqDatabase *database in model.hasDatabaseSchemas) {
		for (RptqQuery *query in database.hasQueries) {
			if ([query.name isEqualToString: @"b"]) {
				bIdentifier = query.identifier;
				bCredentialRow = query.inDatabase.ownedByUser;
			}
		}
	}
	XCTAssertNotEqual(bIdentifier, 0);
	XCTAssertNotNil(bCredentialRow);

	bCredentialRow.host = @"/no-such-directory/ghost.sqlite";
	bCredentialRow.dbname = @"ghost.sqlite";
	[document.storeContext saveComposed: NULL];
	MADOperationRefreshComposed *failed = MADCompositionRunRefreshWithQueryCredentials(document, credentials);
	XCTAssertEqual(failed.errors.count, (NSUInteger)1);
	NSError *sourceError = failed.errors.firstObject;
	XCTAssertEqualObjects(sourceError.userInfo[MADOperationRefreshSourceNameKey], @"b");
	XCTAssertEqual([sourceError.userInfo[MADOperationRefreshSourceQueryIdentifierKey] longLongValue], bIdentifier);
	XCTAssertTrue([sourceError.userInfo[MADOperationRefreshSourceConnectionStringKey] containsString: @"ghost.sqlite"]);
}

- (void)testComposedRefreshClosesAndReopensSqliteSources {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[
		@{ @"name": @"a", @"file": @"a.sqlite", @"rows": @[ @[@1, @10] ] },
		@{ @"name": @"b", @"file": @"b.sqlite", @"rows": @[ @[@1, @20] ] },
	];
	NSArray *composers = @[
		@{ @"name": @"root", @"children": @[ @"a", @"b" ],
		   @"links": @[ @[ @"a", @"id", @"b", @"id" ] ],
		   @"outputs": @[ @[ @"a", @"id", @"a_id" ], @[ @"b", @"value", @"b_value" ] ] },
	];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"root", &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	XCTAssertEqual(MADCompositionRunRefresh(document).errors.count, (NSUInteger)0);
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)1);

	NSString *bPath = [directory stringByAppendingPathComponent: @"b.sqlite"];
	int removeResult = MADCompositionDeleteFile(bPath);
	XCTAssertEqual(removeResult, 0,
				   @"the refreshed source file is closed and can be removed (result %d)", removeResult);
	XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath: bPath]);

	NSURL *bURL = [NSURL fileURLWithPath: bPath];

	XCTAssertTrue(MADCompositionCreateSource(bURL, @[ @"CREATE TABLE b (id INTEGER, value REAL);",
													 @"INSERT INTO b VALUES (1, 20);"]));
	MADOperationRefreshComposed *again = MADCompositionRunRefresh(document);
	XCTAssertEqual(again.errors.count, (NSUInteger)0, @"%@", again.errors.firstObject);
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)1);
}

- (void)testComposedThreeLeafRootJoinsAllThree {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[
		@{ @"name": @"a", @"file": @"a.sqlite", @"rows": @[ @[@1, @10], @[@2, @20] ] },
		@{ @"name": @"b", @"file": @"b.sqlite", @"rows": @[ @[@1, @100], @[@2, @200] ] },
		@{ @"name": @"c", @"file": @"c.sqlite", @"rows": @[ @[@1, @1000] ] },
	];
	NSArray *composers = @[
		@{ @"name": @"root", @"children": @[ @"a", @"b", @"c" ],
		   @"links": @[ @[ @"a", @"id", @"b", @"id" ], @[ @"b", @"id", @"c", @"id" ] ],
		   @"outputs": @[ @[ @"a", @"id", @"a_id" ], @[ @"a", @"value", @"a_value" ],
						  @[ @"b", @"value", @"b_value" ], @[ @"c", @"value", @"c_value" ] ] },
	];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"root", &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	MADOperationRefreshComposed *refresh = MADCompositionRunRefresh(document);
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);
	XCTAssertEqualObjects(document.currentResult.columnKeys, (@[ @"a_id", @"a_value", @"b_value", @"c_value" ]));
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)2);

	MADDataTableFast *table = document.dataTable;
	XCTAssertEqual(MADCompositionValue(table, 1, @"a_id"), 1.0);
	XCTAssertEqual(MADCompositionValue(table, 1, @"a_value"), 10.0);
	XCTAssertEqual(MADCompositionValue(table, 1, @"b_value"), 100.0);
	XCTAssertEqual(MADCompositionValue(table, 1, @"c_value"), 1000.0);
	XCTAssertEqual(MADCompositionValue(table, 2, @"a_id"), 2.0);
	XCTAssertEqual(MADCompositionValue(table, 2, @"a_value"), 20.0);
	XCTAssertEqual(MADCompositionValue(table, 2, @"b_value"), 200.0);
	XCTAssertTrue(isnan(MADCompositionValue(table, 2, @"c_value")));
}

- (void)testComposedNestedComposerRunsChildrenBeforeParents {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[
		@{ @"name": @"A", @"file": @"a.sqlite", @"rows": @[ @[@1, @10] ] },
		@{ @"name": @"B", @"file": @"b.sqlite", @"rows": @[ @[@1, @20] ] },
		@{ @"name": @"R1", @"file": @"r1.sqlite", @"rows": @[ @[@1, @30] ] },
		@{ @"name": @"D", @"file": @"d.sqlite", @"rows": @[ @[@1, @40] ] },
		@{ @"name": @"R2", @"file": @"r2.sqlite", @"rows": @[ @[@1, @50] ] },
	];
	NSArray *composers = @[
		@{ @"name": @"C1", @"children": @[ @"A", @"B", @"R1" ],
		   @"links": @[], @"outputs": @[ @[ @"A", @"id", @"a_id" ] ] },
		@{ @"name": @"C2", @"children": @[ @"C1", @"D", @"R2" ],
		   @"links": @[], @"outputs": @[ @[ @"C1", @"a_id", @"c1_id" ], @[ @"D", @"value", @"d_value" ] ] },
	];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"C2", &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	MADOperationRefreshComposed *refresh = MADCompositionRunRefresh(document);
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);

	NSArray<NSString *> *order = refresh.executedNodeNames;
	XCTAssertEqual(order.count, (NSUInteger)7);
	XCTAssertEqualObjects(order.lastObject, @"C2");
	NSUInteger indexOfC1 = [order indexOfObject: @"C1"];
	XCTAssertLessThan([order indexOfObject: @"A"], indexOfC1);
	XCTAssertLessThan([order indexOfObject: @"B"], indexOfC1);
	XCTAssertLessThan([order indexOfObject: @"R1"], indexOfC1);
	XCTAssertLessThan(indexOfC1, [order indexOfObject: @"C2"]);
	XCTAssertLessThan([order indexOfObject: @"D"], [order indexOfObject: @"C2"]);
	XCTAssertLessThan([order indexOfObject: @"R2"], [order indexOfObject: @"C2"]);
}

- (void)testComposedSharedChildRunsOnce {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[
		@{ @"name": @"A", @"file": @"a.sqlite", @"rows": @[ @[@1, @10] ] },
		@{ @"name": @"B", @"file": @"b.sqlite", @"rows": @[ @[@1, @20] ] },
	];
	// A is a child of both C1 and C2 (a diamond); it must run once.
	NSArray *composers = @[
		@{ @"name": @"C1", @"children": @[ @"A", @"B" ],
		   @"links": @[], @"outputs": @[ @[ @"A", @"id", @"a_id" ] ] },
		@{ @"name": @"C2", @"children": @[ @"C1", @"A" ],
		   @"links": @[], @"outputs": @[ @[ @"C1", @"a_id", @"c1_id" ], @[ @"A", @"value", @"a_value" ] ] },
	];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"C2", &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	MADOperationRefreshComposed *refresh = MADCompositionRunRefresh(document);
	XCTAssertEqual(refresh.errors.count, (NSUInteger)0, @"%@", refresh.errors.firstObject);

	NSArray<NSString *> *order = refresh.executedNodeNames;
	NSArray<NSString *> *matches = [order filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"self == %@", @"A"]];
	XCTAssertEqual(matches.count, (NSUInteger)1, @"the shared child runs once, not once per parent");
	XCTAssertEqualObjects(order.lastObject, @"C2");
}

- (void)testComposedRootWithMoreThanTenChildrenIsRejected {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];

	NSMutableArray<NSDictionary *> *leaves = [NSMutableArray array];
	NSMutableArray<NSString *> *children = [NSMutableArray array];
	NSMutableArray<NSArray *> *outputs = [NSMutableArray array];
	for (NSUInteger i = 0; i < 11; i++) {
		NSString *name = [NSString stringWithFormat: @"leaf%lu", (unsigned long)i];
		[leaves addObject: @{ @"name": name, @"file": [name stringByAppendingString: @".sqlite"], @"rows": @[ @[@1, @10] ] }];
		[children addObject: name];
		[outputs addObject: @[ name, @"id", [name stringByAppendingString: @"_id"] ]];
	}
	NSArray *composers = @[ @{ @"name": @"root", @"children": children, @"links": @[], @"outputs": outputs } ];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"root", &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	NSError *error = nil;
	XCTAssertFalse([model validateCompositionGraphWithError: &error], @"more than ten direct children is a design-time error");
	XCTAssertNotNil(error);
	XCTAssertTrue([error.localizedDescription containsString: @"root"], @"the error names the offending node");
}

- (void)testComposedMixedNodeIsRejected {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[ @{ @"name": @"a", @"file": @"a.sqlite", @"rows": @[ @[@1, @10] ] } ];
	NSArray *composers = @[ @{ @"name": @"root", @"children": @[ @"a" ], @"links": @[], @"outputs": @[ @[ @"a", @"id", @"a_id" ] ], @"remoteTables": @[ @"a" ] } ];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"root", &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	NSError *error = nil;
	XCTAssertFalse([model validateCompositionGraphWithError: &error], @"a node that mixes remote and upstream tables is a design-time error");
	XCTAssertNotNil(error);
	XCTAssertTrue([error.localizedDescription containsString: @"root"], @"the error names the offending node");
}

#pragma mark - Cache ownership (P1)

static NSArray<NSString *> *MADCompositionMaddbFiles(MADHeadlessDocument *document) {
	NSURL *directory = document.cachedFilesDirectory;
	NSArray<NSString *> *names = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: directory.path error: NULL];
	NSMutableArray<NSString *> *maddb = [NSMutableArray array];
	for (NSString *name in names) {
		if ([name.pathExtension isEqualToString: @"maddb"]) {
			[maddb addObject: [directory URLByAppendingPathComponent: name].path];
		}
	}
	return maddb;
}

- (void)testTwoSameNamedDocumentsInDifferentFoldersKeepSeparateCaches {
	NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSUUID UUID].UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath: root withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *dbA = [NSURL fileURLWithPath: [root stringByAppendingPathComponent: @"a.sqlite"]];
	NSURL *dbB = [NSURL fileURLWithPath: [root stringByAppendingPathComponent: @"b.sqlite"]];

	XCTAssertTrue(MADCompositionCreateSource(dbA, @[
		@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL, note TEXT);",
		@"INSERT INTO invoices VALUES (1, 100.0, 'first');",
		@"INSERT INTO invoices VALUES (2, 200.0, 'second');",
		@"INSERT INTO invoices VALUES (3, 300.0, 'third');"]));
	XCTAssertTrue(MADCompositionCreateSource(dbB, @[
		@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL, note TEXT);",
		@"INSERT INTO invoices VALUES (1, 100.0, 'first');",
		@"INSERT INTO invoices VALUES (2, 200.0, 'second');",
		@"INSERT INTO invoices VALUES (3, 300.0, 'third');",
		@"INSERT INTO invoices VALUES (4, 400.0, 'fourth');",
		@"INSERT INTO invoices VALUES (5, 500.0, 'fifth');"]));

	// Two documents that share one basename; their caches used to collide on it.
	NSString *errorDescription = nil;
	MADHeadlessDocument *a = MADCompositionDocument(@"SharedName.mad", dbA, @"invoices", @[@"invoice_id", @"amount"], &errorDescription);
	XCTAssertNotNil(a, @"%@", errorDescription);
	XCTAssertEqual(a.currentResult.numberOfRows, (NSUInteger)3);
	NSURL *aURL = a.fileURL;
	NSString *aRowPath = a.currentResult.rowDatabaseURL.path;
	a = nil;

	MADHeadlessDocument *b = MADCompositionDocument(@"SharedName.mad", dbB, @"invoices", @[@"invoice_id", @"amount"], &errorDescription);
	XCTAssertNotNil(b, @"%@", errorDescription);
	XCTAssertEqual(b.currentResult.numberOfRows, (NSUInteger)5);
	NSURL *bURL = b.fileURL;
	NSString *bRowPath = b.currentResult.rowDatabaseURL.path;
	b = nil;

	XCTAssertNotEqualObjects(aRowPath, bRowPath, @"same-named documents in different folders keep separate row files");

	// Reopen each through the normal cache-loading path, without refreshing.
	MADHeadlessDocument *reopenedA = [MADHeadlessDocument documentWithContentsOfURL: aURL error: &errorDescription];
	XCTAssertNotNil(reopenedA, @"%@", errorDescription);
	[reopenedA resetCache];
	XCTAssertEqual(reopenedA.currentResult.numberOfRows, (NSUInteger)3, @"A reads its own rows, not B's");

	MADHeadlessDocument *reopenedB = [MADHeadlessDocument documentWithContentsOfURL: bURL error: &errorDescription];
	XCTAssertNotNil(reopenedB, @"%@", errorDescription);
	[reopenedB resetCache];
	XCTAssertEqual(reopenedB.currentResult.numberOfRows, (NSUInteger)5, @"B reads its own rows, not A's");
}

- (void)testSaveAsCopyRefreshDoesNotChangeTheOriginal {
	NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSUUID UUID].UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath: root withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *db = [NSURL fileURLWithPath: [root stringByAppendingPathComponent: @"a.sqlite"]];
	XCTAssertTrue(MADCompositionCreateSource(db, @[
		@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL, note TEXT);",
		@"INSERT INTO invoices VALUES (1, 100.0, 'first');",
		@"INSERT INTO invoices VALUES (2, 200.0, 'second');",
		@"INSERT INTO invoices VALUES (3, 300.0, 'third');"]));

	NSString *errorDescription = nil;
	MADHeadlessDocument *a = MADCompositionDocument(@"SharedName.mad", db, @"invoices", @[@"invoice_id", @"amount"], &errorDescription);
	XCTAssertNotNil(a, @"%@", errorDescription);
	XCTAssertEqual(a.currentResult.numberOfRows, (NSUInteger)3);
	NSURL *aURL = a.fileURL;

	// Save As into a second folder under the same name.
	NSURL *saveAsDirectory = [NSURL fileURLWithPath: [NSTemporaryDirectory() stringByAppendingPathComponent: [NSUUID UUID].UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtURL: saveAsDirectory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *docB = [saveAsDirectory URLByAppendingPathComponent: @"SharedName.mad"];
	NSError *error = nil;
	XCTAssertTrue([a writeToURL: docB reproducible: NO error: &error], @"%@", error);
	a = nil;

	// Open the copy and refresh it to a different, zero-row result.
	MADHeadlessDocument *b = [MADHeadlessDocument documentWithContentsOfURL: docB error: &errorDescription];
	XCTAssertNotNil(b, @"%@", errorDescription);
	RptqQueryPredicate *predicate = MADReportExporterAddImpossiblePredicate(b);
	XCTAssertNotNil(predicate);
	XCTAssertTrue(MADReportExporterRefreshDocument(b, &error), @"%@", error);
	XCTAssertEqual(b.currentResult.numberOfRows, (NSUInteger)0);
	b = nil;

	// The original still reopens to its own rows.
	MADHeadlessDocument *reopenedA = [MADHeadlessDocument documentWithContentsOfURL: aURL error: &errorDescription];
	XCTAssertNotNil(reopenedA, @"%@", errorDescription);
	[reopenedA resetCache];
	XCTAssertEqual(reopenedA.currentResult.numberOfRows, (NSUInteger)3, @"refreshing the copy cannot change what the original reopens");
}

#pragma mark - One render snapshot (P2)

static MADPublishingExportDocument *MADPublishingExportNewDocument(void) {
	MADReportExporterInstallSampleDatabase();
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSUUID UUID].UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSString *name = [NSString stringWithFormat: @"publishing-%@.mad", [NSUUID UUID].UUIDString];
	NSURL *copy = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: name]];
	NSError *error = nil;
	if (![[NSFileManager defaultManager] copyItemAtURL: [NSURL fileURLWithPath: MADReportExporterFixturePath()] toURL: copy error: &error]) return nil;
	return (MADPublishingExportDocument *)[MADPublishingExportDocument documentWithContentsOfURL: copy error: &error];
}

- (void)testJSONReportExportUsesOneGenerationAcrossAPublish {
	MADPublishingExportDocument *document = MADPublishingExportNewDocument();
	XCTAssertNotNil(document, @"the London fixture could not be copied and opened");
	if (document == nil) return;

	NSError *error = nil;
	XCTAssertTrue(MADReportExporterRefreshDocument(document, &error), @"%@", error);
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)76);

	id <MADReportExporting> cleanExporter = [[MADReportExporterJSONReport alloc] init];
	NSURL *cleanURL = MADReportExporterOutputURL(@"clean.json");
	XCTAssertTrue([cleanExporter exportDocument: document toURL: cleanURL options: 0 error: &error], @"%@", error);
	NSData *cleanData = [NSData dataWithContentsOfURL: cleanURL];
	XCTAssertNotNil(cleanData);

	// Publish a zero-row B after the export source captured A and wrote A's rows but
	// before the page walk formats.  The rows and the pages must both stay A.
	document.publishOnNextFormat = YES;
	id <MADReportExporting> crossingExporter = [[MADReportExporterJSONReport alloc] init];
	NSURL *crossingURL = MADReportExporterOutputURL(@"crossing.json");
	XCTAssertTrue([crossingExporter exportDocument: document toURL: crossingURL options: 0 error: &error], @"%@", error);
	NSData *crossingData = [NSData dataWithContentsOfURL: crossingURL];
	XCTAssertNotNil(crossingData);

	XCTAssertEqualObjects(crossingData, cleanData, @"the export's rows and pages describe one generation (A)");
}

#pragma mark - Staged-file cleanup (P3)

- (void)testFailedRefreshLeavesNoStagedFilesAndRetrySucceeds {
	MADFailingPublicationDocument *document = MADReportExporterNewPublicationDocument();
	XCTAssertNotNil(document);
	if (document == nil) return;

	NSError *error = nil;
	XCTAssertTrue(MADReportExporterRefreshDocument(document, &error), @"%@", error);
	MADDataResult *a = document.currentResult;
	XCTAssertNotNil(a);
	NSString *aIdentifier = a.identifier;
	NSString *aRowPath = a.rowDatabaseURL.path;

	// The baseline set of row files: the live table's (empty) file plus A's.  A
	// failed refresh must add nothing to it.
	NSArray<NSString *> *maddbBefore = MADCompositionMaddbFiles(document);

	// Force a failed publish: the staged generation must be discarded, leaving A.
	RptqQueryPredicate *predicate = MADReportExporterAddImpossiblePredicate(document);
	XCTAssertNotNil(predicate);
	document.failPublication = YES;
	error = nil;
	XCTAssertFalse(MADReportExporterRefreshDocument(document, &error), @"the forced publication must fail");
	XCTAssertNotNil(error);
	document.failPublication = NO;

	XCTAssertEqualObjects(document.currentResult.identifier, aIdentifier, @"A stays published");
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath: aRowPath], @"A's row file is intact");

	// No staged row file leaked: the discard removed B with its handles closed.
	NSArray<NSString *> *maddbAfter = MADCompositionMaddbFiles(document);
	XCTAssertEqualObjects([maddbAfter sortedArrayUsingSelector: @selector(compare:)],
						  [maddbBefore sortedArrayUsingSelector: @selector(compare:)],
						  @"the staged row file was removed");

	// A retry succeeds.
	MADReportExporterRemovePredicate(document, predicate);
	error = nil;
	XCTAssertTrue(MADReportExporterRefreshDocument(document, &error), @"%@", error);
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)76);
}

#pragma mark - Per-node results and node-scoped export (node-as-report)

/// A nested composition -- two leaves (A, B), an intermediate composer (C1) joining
/// them, and a root (C2) over C1 -- reopened and refreshed, so every non-root node
/// has a retained result in `nodeResults`.
static MADHeadlessDocument *MADNestedCompositionRefreshedDocument(NSString **outError) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[
		@{ @"name": @"A", @"file": @"a.sqlite", @"rows": @[ @[@1, @10], @[@2, @20] ] },
		@{ @"name": @"B", @"file": @"b.sqlite", @"rows": @[ @[@1, @100] ] },
	];
	NSArray *composers = @[
		@{ @"name": @"C1", @"children": @[ @"A", @"B" ],
		   @"links": @[ @[ @"A", @"id", @"B", @"id" ] ],
		   @"outputs": @[ @[ @"A", @"id", @"a_id" ], @[ @"B", @"value", @"b_value" ] ] },
		@{ @"name": @"C2", @"children": @[ @"C1" ],
		   @"links": @[],
		   @"outputs": @[ @[ @"C1", @"a_id", @"c1_id" ] ] },
	];

	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"C2", outError);
	if (document == nil) return nil;
	MADOperationRefreshComposed *refresh = MADCompositionRunRefresh(document);
	if (refresh.errors.count > 0) {
		if (outError) *outError = refresh.errors.firstObject.description;
		return nil;
	}
	return document;
}

/// A successful composed refresh retains every non-root node's materialized table,
/// keyed by query identifier, while the root stays the document's current result.
- (void)testComposedRefreshRetainsNodeResults {
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADNestedCompositionRefreshedDocument(&errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	XCTAssertEqual(document.nodeResults.count, (NSUInteger)3);
	for (NSString *name in @[ @"A", @"B", @"C1" ]) {
		RptqQuery *query = MADCompositionQueryNamed(model, name);
		XCTAssertNotNil(query);
		MADDataResult *result = document.nodeResults[@(query.identifier)];
		XCTAssertNotNil(result, @"node %@ retained its result", name);
	}

	// The root is not in the map; its result is the document's current result.
	XCTAssertNil(document.nodeResults[@(model.rootQuery.identifier)]);
	XCTAssertNotNil(document.currentResult);
	XCTAssertEqualObjects(document.currentResult.columnKeys, (@[ @"c1_id" ]));
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)2);
}

/// A second refresh publishes a new generation: the node-result reads the new rows,
/// not the ones the previous publish retained.
- (void)testNodeResultReadsOneGenerationAcrossAPublish {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[ @{ @"name": @"A", @"file": @"a.sqlite", @"rows": @[ @[@1, @10], @[@2, @20] ] } ];
	NSArray *composers = @[
		@{ @"name": @"root", @"children": @[ @"A" ], @"links": @[],
		   @"outputs": @[ @[ @"A", @"id", @"a_id" ], @[ @"A", @"value", @"a_value" ] ] },
	];
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"root", &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	XCTAssertEqual(MADCompositionRunRefresh(document).errors.count, (NSUInteger)0);

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *leafA = MADCompositionQueryNamed(model, @"A");
	MADDataResult *first = document.nodeResults[@(leafA.identifier)];
	XCTAssertNotNil(first);
	XCTAssertEqual(first.numberOfRows, (NSUInteger)2);

	// Grow the leaf's source and refresh again: the retained result advances.
	NSURL *aURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"a.sqlite"]];
	XCTAssertTrue(MADCompositionCreateSource(aURL, @[ @"INSERT INTO A VALUES (3, 30);" ]));
	XCTAssertEqual(MADCompositionRunRefresh(document).errors.count, (NSUInteger)0);

	MADDataResult *second = document.nodeResults[@(leafA.identifier)];
	XCTAssertNotNil(second);
	XCTAssertEqual(second.numberOfRows, (NSUInteger)3, @"the node-result reads the new generation");
	XCTAssertEqual(document.currentResult.numberOfRows, (NSUInteger)3, @"the root's rows advance too");
}

/// A failed leaf refresh leaves the previous complete node results in place: the
/// failed walk never publishes, so the map a prior refresh retained is untouched.
- (void)testFailedLeafKeepsPreviousNodeResults {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[
		@{ @"name": @"A", @"file": @"a.sqlite", @"rows": @[ @[@1, @10] ] },
		@{ @"name": @"B", @"file": @"b.sqlite", @"rows": @[ @[@1, @100] ] },
	];
	NSArray *composers = @[
		@{ @"name": @"root", @"children": @[ @"A", @"B" ], @"links": @[],
		   @"outputs": @[ @[ @"A", @"id", @"a_id" ], @[ @"B", @"value", @"b_value" ] ] },
	];
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"root", &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	XCTAssertEqual(MADCompositionRunRefresh(document).errors.count, (NSUInteger)0);

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *leafA = MADCompositionQueryNamed(model, @"A");
	MADDataResult *aResult = document.nodeResults[@(leafA.identifier)];
	XCTAssertNotNil(aResult);

	// Drop leaf B's source: the next refresh fails at B, before any publish.
	NSURL *bURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"b.sqlite"]];
	XCTAssertTrue([[NSFileManager defaultManager] removeItemAtURL: bURL error: NULL]);
	MADOperationRefreshComposed *failed = MADCompositionRunRefresh(document);
	XCTAssertGreaterThan(failed.errors.count, (NSUInteger)0, @"the dropped leaf fails the refresh");

	// The previous complete results survive: A's retained rows are unchanged.
	MADDataResult *aAfter = document.nodeResults[@(leafA.identifier)];
	XCTAssertEqualObjects(aAfter, aResult, @"the prior node result is retained");
	XCTAssertEqual(aAfter.numberOfRows, (NSUInteger)1);
}

/// `MADReportExportSource sourceWithDocument:query:` reads a leaf's and a composing
/// child's retained result, not the root's.
- (void)testNodeResultExportSourceReadsLeafAndComposingChild {
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADNestedCompositionRefreshedDocument(&errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *leafA = MADCompositionQueryNamed(model, @"A");
	RptqQuery *composer = MADCompositionQueryNamed(model, @"C1");

	NSError *error = nil;
	MADReportExportSource *leafSource = [MADReportExportSource sourceWithDocument: document query: leafA error: &error];
	XCTAssertNotNil(leafSource, @"%@", error);
	XCTAssertEqual(leafSource.numberOfRows, (NSUInteger)2);
	XCTAssertEqual(leafSource.columnKeys.count, (NSUInteger)2);

	MADReportExportSource *composerSource = [MADReportExportSource sourceWithDocument: document query: composer error: &error];
	XCTAssertNotNil(composerSource, @"%@", error);
	XCTAssertEqual(composerSource.numberOfRows, (NSUInteger)2);
	XCTAssertEqual(composerSource.columnKeys.count, (NSUInteger)2);
	XCTAssertTrue([composerSource.columnKeys containsObject: @"a_id"], @"%@", composerSource.columnKeys);
	XCTAssertTrue([composerSource.columnKeys containsObject: @"b_value"], @"%@", composerSource.columnKeys);
}

/// A node (leaf or composing child) exports as JSON through the query-scoped seam,
/// and the bytes name the node's own columns rather than the root's.
- (void)testLeafAndComposingChildJSONExport {
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADNestedCompositionRefreshedDocument(&errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *leafA = MADCompositionQueryNamed(model, @"A");
	RptqQuery *composer = MADCompositionQueryNamed(model, @"C1");

	MADReportExporterJSON *exporter = [[MADReportExporterJSON alloc] init];
	NSError *error = nil;
	NSURL *leafURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"leaf.json"]];
	XCTAssertTrue([exporter exportDocument: document query: leafA toURL: leafURL options: MADReportExportOptionsNone error: &error], @"%@", error);
	NSURL *composerURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"composer.json"]];
	error = nil;
	XCTAssertTrue([exporter exportDocument: document query: composer toURL: composerURL options: MADReportExportOptionsNone error: &error], @"%@", error);

	NSData *leafData = [NSData dataWithContentsOfURL: leafURL];
	NSData *composerData = [NSData dataWithContentsOfURL: composerURL];
	XCTAssertGreaterThan(leafData.length, (NSUInteger)0);
	XCTAssertGreaterThan(composerData.length, (NSUInteger)0);
	NSString *composerJSON = [[NSString alloc] initWithData: composerData encoding: NSUTF8StringEncoding];
	XCTAssertTrue([composerJSON containsString: @"a_id"], @"the composing child's JSON carries its own columns");
	XCTAssertFalse([composerJSON containsString: @"c1_id"], @"the composing child's JSON does not carry the root's columns");
}

/// `json-report` is not node-scoped yet: a non-root query errors instead of writing
/// the root's rows under the node's name.
- (void)testJSONReportNonRootErrors {
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADNestedCompositionRefreshedDocument(&errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *composer = MADCompositionQueryNamed(model, @"C1");

	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	MADReportExporterJSONReport *reporter = [[MADReportExporterJSONReport alloc] init];

	NSError *error = nil;
	NSURL *nodeURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"node.report.json"]];
	XCTAssertFalse([reporter exportDocument: document query: composer toURL: nodeURL options: MADReportExportOptionsNone error: &error],
				   @"a non-root json-report export must be refused");
	XCTAssertNotNil(error);

	// The root still exports.
	error = nil;
	NSURL *rootURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"root.report.json"]];
	XCTAssertTrue([reporter exportDocument: document query: model.rootQuery toURL: rootURL options: MADReportExportOptionsNone error: &error], @"%@", error);
	XCTAssertGreaterThan([[NSData dataWithContentsOfURL: rootURL] length], (NSUInteger)0);
}

/// The sections layout is per-node: the root's layout reads the document's sections,
/// a leaf's reads its own, and the two never share identifiers.
- (void)testSectionsLayoutIsDistinctPerQuery {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[
		@{ @"name": @"A", @"file": @"a.sqlite", @"rows": @[ @[@1, @10] ] },
		@{ @"name": @"B", @"file": @"b.sqlite", @"rows": @[ @[@1, @100] ] },
	];
	NSArray *composers = @[
		@{ @"name": @"C1", @"children": @[ @"A", @"B" ], @"links": @[], @"outputs": @[ @[ @"A", @"id", @"a_id" ] ] },
		@{ @"name": @"C2", @"children": @[ @"C1" ], @"links": @[], @"outputs": @[ @[ @"C1", @"a_id", @"c1_id" ] ] },
	];
	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"C2", &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *leafA = MADCompositionQueryNamed(model, @"A");
	XCTAssertNotNil(leafA);

	// The leaf owns its own five sections (authorable from a legacy revision-3 leaf).
	[RptqDocumentSection createStructuralSectionsForQuery: leafA managedObjectContext: document.storeContext];
	NSError *error = nil;
	XCTAssertTrue([document.storeContext saveComposed: &error], @"%@", error);

	MADSectionsLayout *rootLayout = [[MADSectionsLayout alloc] initWithManagedObjectContext: document.storeContext
																			  databaseClass: [document.database class]
																			queryIdentifier: 0];
	MADSectionsLayout *leafLayout = [[MADSectionsLayout alloc] initWithManagedObjectContext: document.storeContext
																			  databaseClass: [document.database class]
																			queryIdentifier: leafA.identifier];

	XCTAssertNotNil(rootLayout.detail, @"the root's layout reads the document's detail section");
	XCTAssertNotNil(leafLayout.detail, @"the leaf's layout reads the leaf's detail section");
	XCTAssertNotEqualObjects(rootLayout.detail.identifierObject, leafLayout.detail.identifierObject,
							 @"root and leaf layouts are distinct");
}

/// A non-root node with an authored layout renders its own bands: the page walk draws the
/// leaf's detail band and fills it with the leaf's elements, not the root's (empty) one.
- (void)testNodeScopedHTMLRendersTheNodeLayout {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[ @{ @"name": @"a", @"file": @"a.sqlite", @"rows": @[ @[@1, @10], @[@2, @20] ] } ];
	NSArray *composers = @[ @{ @"name": @"root", @"children": @[ @"a" ], @"links": @[], @"outputs": @[ @[ @"a", @"id", @"a_id" ] ] } ];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"root", &errorDescription);
	XCTAssertNotNil(document, @"%@", errorDescription);
	if (document == nil) return;

	// Author the leaf's own layout: its five bands, a static label, and a data field bound
	// to the leaf's `value` column.
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *leaf = MADCompositionQueryNamed(model, @"a");
	XCTAssertNotNil(leaf);
	if (leaf == nil) return;

	NSArray<RptqDocumentSection *> *sections = [RptqDocumentSection createStructuralSectionsForQuery: leaf
																		managedObjectContext: document.storeContext];
	RptqDocumentSection *detail = nil;
	for (RptqDocumentSection *section in sections) {
		if (section.type == MADDocumentSectionTypeBody) { detail = section; break; }
	}
	XCTAssertNotNil(detail, @"the leaf has a detail band");
	if (detail == nil) return;

	RptqDocumentElementLabel *label =
		(RptqDocumentElementLabel *)[document.storeContext insertObjectForEntity: NSStringFromClass([RptqDocumentElementLabel class]) identifier: 0];
	label.type = MADPrintPageElementTypeLabelStatic;
	label.text = @"NODE LABEL";
	[label setSizeWidth: 120.0f height: 20.0f];
	[detail addDocumentObject: label withDropPoint: CGPointMake(12.0f, 6.0f) managedObjectContext: document.storeContext];

	RptqQueryField *valueField = MADCompositionFieldNamed(leaf, @"value");
	XCTAssertNotNil(valueField, @"the leaf's value field is present");
	if (valueField != nil) {
		RptqDocumentElementLabelDataField *dataField =
			(RptqDocumentElementLabelDataField *)[document.storeContext insertObjectForEntity: NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier: 0];
		dataField.type = MADPrintPageElementTypeLabelDynamic;
		dataField.referencesQueryField = valueField;
		[dataField setSizeWidth: 120.0f height: 20.0f];
		[detail addDocumentObject: dataField withDropPoint: CGPointMake(12.0f, 30.0f) managedObjectContext: document.storeContext];
	}

	NSError *error = nil;
	XCTAssertTrue([document.storeContext saveComposed: &error], @"%@", error);
	XCTAssertEqual(MADCompositionRunRefresh(document).errors.count, (NSUInteger)0);

	NSURL *url = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"leaf.html"]];
	MADReportExporterHTML *exporter = [[MADReportExporterHTML alloc] init];
	XCTAssertTrue([exporter exportDocument: document query: leaf toURL: url options: MADReportExportOptionsNone error: &error],
				  @"%@", error);

	NSString *html = [NSString stringWithContentsOfURL: url encoding: NSUTF8StringEncoding error: NULL];
	XCTAssertTrue([html containsString: @"NODE LABEL"], @"the leaf's HTML renders its own static label");
	XCTAssertTrue([html containsString: @"class=\"line\""], @"the leaf's HTML has rendered lines");
}

@end
