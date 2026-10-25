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
// which is compiled on both platforms now (docs/project/MAD_LINUX.md §9 Phase E); pdf draws with
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
//  "same bytes on both platforms" claim (docs/project/MAD_CLI.md's `mad export` section)
//  is asserted on Apple too rather than assumed (docs/project/BUGS.md, "The pinned
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
	//  finds will not be the sections the ORDER BY produced (docs/project/MAD_CLI.md's
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

@end
