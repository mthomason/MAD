//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporterTests.m
//  Linux/Tests
//
//  The export seam end to end (docs/developers/cli.md §5.3, docs/developers/build/linux.md §9 Phase E): the
//  formats register themselves, and each Foundation exporter writes the London
//  fixture's rows -- the same bytes the Mac's `mad export` writes for the same
//  document, pinned here by a checksum of the whole output (Linux/README.md carries
//  the comparison and how it was made).
//
//  The document is the checked-in portable fixture MADHeadlessDocumentTests opens,
//  refreshed through the application's own chain, so the exporters are exercised on
//  the same rows the CLI's `refresh` verb produces rather than on a stub.
//

#import "MADTestSupport.h"

#import <MAD/MADDatabaseConnection+Constructor.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseCredentals.h>
#import <MADFoundation/MADCredential.h>
#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADHeadlessDocument.h>
#import <MAD/MADReportFormatter.h>
#import <MAD/MADOperationRefresh.h>
#import <MAD/MADOperationRefreshInitialize.h>
#import <MAD/MADOperationRefreshInitalizeMainDataTable.h>
#import <MAD/MADReportExporting.h>
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
#import <MAD/MADQueryFull.h>
#import <MAD/MADPredicateOperator.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDocumentElementLabel.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MADFoundation/MADDataColumn.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryPredicate.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqObject.h>
#import <MAD/MADArchiveManager.h>
#import <MAD/MADDocumentStore.h>
#import <MAD/MADQueryLinkType.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADFoundation/NSString+Comparison.h>

#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADSqlite3/MADDataTableFast.h>

#import "sqlite3.h"

// __FILE__ is absolute here (CMake hands the compiler an absolute path), so
// The test file's directory, walked up until the repository root (the directory
// holding Versions.yml) is found.  The Linux test lives at Linux/Tests and the
// Windows mirror at Windows/Engine/Tests, so a fixed number of levels cannot
// describe both.
static NSString *MADExporterRepositoryRoot(void) {
	NSString *directory = [@(__FILE__) stringByDeletingLastPathComponent];
	while (directory.length > 0) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:
				[directory stringByAppendingPathComponent: @"Versions.yml"]]) {
			return directory;
		}
		directory = [directory stringByDeletingLastPathComponent];
	}
	return directory;
}

static NSString *MADExporterFixturePath(void) {
	return [[MADExporterRepositoryRoot() stringByAppendingPathComponent: @"CLI/Fixtures"]
			stringByAppendingPathComponent: @"London.portable.mad"];
}

static NSString *MADExporterSampleDatabasePath(void) {
	return [[MADExporterRepositoryRoot() stringByAppendingPathComponent:
			 @"MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset"]
			stringByAppendingPathComponent: @"chinook.sqlite3"];
}

static BOOL MADExporterFixtureIsThere(void) {
	return [[NSFileManager defaultManager] fileExistsAtPath: MADExporterFixturePath()];
}

// The document's Sqlite3 connection stores a bare filename and MADURLFactory resolves
// it against the app-support directory, so the sample goes there (the same install
// MADHeadlessDocumentTests does).
static void MADExporterInstallSampleDatabase(void) {
	NSString *samplePath = MADExporterSampleDatabasePath();
	if (![[NSFileManager defaultManager] fileExistsAtPath: samplePath]) return;

	NSURL *supportDirectory = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID: [MADApplication groupIdentifier]];
	NSURL *target = [supportDirectory URLByAppendingPathComponent: @"chinook.sqlite3"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager createDirectoryAtURL: supportDirectory withIntermediateDirectories: YES attributes: nil error: NULL];
	[fileManager removeItemAtURL: target error: NULL];
	[fileManager copyItemAtURL: [NSURL fileURLWithPath: samplePath] toURL: target error: NULL];
}

/// The opened, refreshed fixture, or nil.  One document per process (opening the
/// same .mad twice would unarchive the second copy over the first one's guts), and
/// one refresh, which every export test then reads.
static MADHeadlessDocument *MADExporterDocument(void) {
	static MADHeadlessDocument *document = nil;
	static BOOL refreshed = NO;
	if (document == nil) {
		MADExporterInstallSampleDatabase();
		document = [[MADHeadlessDocument documentWithContentsOfURL: [NSURL fileURLWithPath: MADExporterFixturePath()]
															 error: NULL] retain];
	}
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

#pragma mark - Publication fixtures

// A document whose publication commit can be failed after the rows are staged.
@interface MADFailingPublicationDocument : MADHeadlessDocument
@property (nonatomic, assign) BOOL failPublication;
@end

@implementation MADFailingPublicationDocument
- (BOOL)writePublishedColumnMapData:(NSData *)data toURL:(NSURL *)url error:(NSError * __autoreleasing *)error {
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

/// A fresh copy of the London fixture under a unique name, so opening it does not
/// unarchive over the shared export fixture's guts.
static MADFailingPublicationDocument *MADExporterNewPublicationDocument(void) {
	MADExporterInstallSampleDatabase();
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory
							  withIntermediateDirectories: YES
											   attributes: NULL
													error: NULL];
	NSString *name = [NSString stringWithFormat: @"publication-%@.mad", [[NSUUID UUID] UUIDString]];
	NSURL *copy = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: name]];
	NSError *error = nil;
	if (![[NSFileManager defaultManager] copyItemAtURL: [NSURL fileURLWithPath: MADExporterFixturePath()]
												 toURL: copy
												 error: &error]) {
		return nil;
	}
	return (MADFailingPublicationDocument *)[MADFailingPublicationDocument documentWithContentsOfURL: copy
																							  error: &error];
}

static BOOL MADExporterRefreshDocument(MADHeadlessDocument *document, NSError **outError) {
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
static RptqQueryPredicate *MADExporterAddImpossiblePredicate(MADHeadlessDocument *document) {
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

static void MADExporterRemovePredicate(MADHeadlessDocument *document, RptqQueryPredicate *predicate) {
	if (predicate == nil) return;
	RptqQuery *query = document.activeDocumentModel.defaultDatabase.defaultQuery;
	[query removeHasQueryPredicateObject: predicate];
	[document.storeContext deleteObject: predicate error: NULL];
}

// The three conditions every export test needs, in the shape MAD_NEED wants (it
// returns from the test, so it can only be used in a void function).
#define MAD_EXPORTER_REQUIRE_FIXTURE() \
	MAD_NEED(MADExporterFixtureIsThere(), @"CLI/Fixtures/London.portable.mad is missing (it is checked in)"); \
	MAD_NEED(MADExporterDocument() != nil, @"could not open the London fixture"); \
	MAD_NEED(MADExporterDocument().numberOfResults == 76, @"the fixture did not refresh (76 rows expected)")

/// A fresh directory for one export.
static NSURL *MADExporterOutputURL(NSString *name) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	return [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: name]];
}

/// The export a format writes for the fixture, or nil.
static NSData *MADExporterOutput(Class <MADReportExporting> exporterClass, NSString *name) {
	MADHeadlessDocument *document = MADExporterDocument();
	if (document == nil) return nil;

	NSURL *url = MADExporterOutputURL(name);
	id <MADReportExporting> exporter = [[(Class)exporterClass alloc] init];
	NSError *error = nil;
	if (![exporter exportDocument: document toURL: url options: MADReportExportOptionsNone error: &error]) {
		MAD_PASS(NO, "the %s export failed: %s", [name UTF8String],
				 error != nil ? [[error description] UTF8String] : "no error given");
		return nil;
	}
	return [NSData dataWithContentsOfURL: url];
}

/// FNV-1a, 64 bit: the whole output's bytes in one number, so a spelling that
/// differs between GNUstep and Apple -- a number, a date, an escape -- fails here
/// rather than going unnoticed.  The constants are the Mac's `mad export` output for
/// the same document (Linux/README.md).
static uint64_t MADExporterChecksum(NSData *data) {
	uint64_t hash = 14695981039346656037ULL;
	const uint8_t *bytes = data.bytes;
	for (NSUInteger index = 0; index < data.length; index++) {
		hash ^= (uint64_t)bytes[index];
		hash *= 1099511628211ULL;
	}
	return hash;
}

#pragma mark - The registry

static void testTheFormatsAreRegistered(void) {
	NSArray <NSString *> *names = [MADReportExporterRegistry registeredFormatNames];
	MAD_PASS([names containsObject: @"text"], "text is registered");
	MAD_PASS([names containsObject: @"csv"], "csv is registered");
	MAD_PASS([names containsObject: @"json"], "json is registered");

	MAD_PASS([names containsObject: @"json-report"], "json-report is registered");
	MAD_PASS_EQUAL([MADReportExporterRegistry exporterClassForFormat: @"JSON"], [MADReportExporterJSON class],
				   "the lookup is case-insensitive");
	MAD_PASS([MADReportExporterRegistry exporterClassForFormat: @"yaml"] == Nil,
			 "an unregistered format answers Nil");
}

// The render half is in this build now (docs/developers/build/linux.md §9 Phase E): the formats that
// need it -- json-report, html, html-flow -- run here, on the same page walk the
// PDF draws from on Apple.
static void testTheRenderSideFormatsRegisterHere(void) {
	MAD_PASS([MADReportExporterRegistry exporterClassForFormat: @"json-report"] != Nil, "json-report is registered");
	MAD_PASS([MADReportExporterRegistry exporterClassForFormat: @"html"] != Nil, "html is registered");
	MAD_PASS([MADReportExporterRegistry exporterClassForFormat: @"html-flow"] != Nil, "html-flow is registered");

	MAD_PASS([MADReportExporterJSONReport isAvailable], "the render half is compiled here, so json-report runs");
	MAD_PASS([MADReportExporterHTML isAvailable], "and the facsimile runs");
	MAD_PASS([MADReportExporterHTMLFlow isAvailable], "and the reflowable one runs");
}

// PDF runs here too now: the walk is MADReportPageBuilder's on every platform, and
// the headless body draws it into a Cairo PDF surface (MADReportExporterPDFCairo,
// docs/developers/build/pdf.md).  The bytes are not the Mac's -- the target is
// structural parity -- so this checks the file and the walk's page count, and
// MADPDFExportTests checks each line against the json-report.
static void testThePDFFormatRunsHere(void) {
	Class <MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat: @"pdf"];
	MAD_PASS(exporterClass != Nil, "pdf is registered");
	MAD_PASS([exporterClass isAvailable], "this build produces it");
	MAD_PASS([exporterClass unavailableReason] == nil, "and gives no reason why it could not");
	MAD_PASS([exporterClass requiresOutputPath], "pdf needs --out, on every platform");
	MAD_PASS_EQUAL([exporterClass fileExtension], @"pdf", "and it is a .pdf");

	if (!MADExporterFixtureIsThere()) return;
	MADHeadlessDocument *document = MADExporterDocument();
	MAD_NEED(document != nil, @"could not open the London fixture");

	NSData *data = MADExporterOutput(exporterClass, @"london.pdf");
	if (data == nil) return;
	NSString *text = [[NSString alloc] initWithData: data encoding: NSISOLatin1StringEncoding];
	MAD_PASS([text hasPrefix: @"%PDF-1.4"], "the London fixture's PDF is a PDF");

	NSUInteger pages = 0;
	NSRange search = NSMakeRange(0, text.length);
	while (search.length > 0) {
		NSRange found = [text rangeOfString: @"/Type /Page " options: 0 range: search];
		if (found.location == NSNotFound) break;
		pages++;
		NSUInteger next = found.location + found.length;
		search = NSMakeRange(next, text.length - next);
	}
	MAD_PASS(pages == 5, "five pages, the walk's page count for the fixture (found %lu)", (unsigned long)pages);
	[text release];
}

#pragma mark - The formats

static void testTheTextExportIsATableOfTheRows(void) {
	MAD_EXPORTER_REQUIRE_FIXTURE();
	NSData *data = MADExporterOutput([MADReportExporterText class], @"london.txt");
	if (data == nil) return;
	NSString *text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

	MAD_PASS([text hasPrefix: @"Sqlite 3 -- 21 columns, 76 rows\n"], "the header names the driver and the shape");
	MAD_PASS([text rangeOfString: @"\"Customer0\".\"City\""].location != NSNotFound,
			 "the column keys are the ones the SELECT list writes");
	MAD_PASS([text rangeOfString: @"London"].location != NSNotFound, "the rows carry the London data");
	// The header, the blank line, the column-name line and one line per row.
	MAD_PASS([text componentsSeparatedByString: @"\n"].count == 80, "76 rows and three lines of framing");
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0x03008506CF27F6EFULL),
				   "the text export's bytes are the ones the Mac writes (see this file's header)");
}

static void testTheCSVExportIsTheRowsAndTheColumnKeys(void) {
	MAD_EXPORTER_REQUIRE_FIXTURE();
	NSData *data = MADExporterOutput([MADReportExporterCSV class], @"london.csv");
	if (data == nil) return;
	NSString *csv = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

	MAD_PASS([csv hasSuffix: @"\r\n"], "RFC 4180 line endings");
	MAD_PASS([csv rangeOfString: @"\"\"\"Album0\"\".\"\"AlbumId\"\"\""].location != NSNotFound,
			 "a column key with quotes in it is quoted and its quotes doubled");
	MAD_PASS([csv rangeOfString: @"phil.hughes@gmail.com"].location != NSNotFound, "the rows carry the London data");
	// The header and one line per row, plus the empty piece after the last CRLF.
	MAD_PASS([csv componentsSeparatedByString: @"\r\n"].count == 78, "76 rows and a header");
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0xFF1C607E7D2F3391ULL),
				   "the csv export's bytes are the ones the Mac writes (see this file's header)");
}

static void testTheJSONExportIsTheSchemaAndTheRows(void) {
	MAD_EXPORTER_REQUIRE_FIXTURE();
	NSData *data = MADExporterOutput([MADReportExporterJSON class], @"london.json");
	if (data == nil) return;
	NSString *json = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

	MAD_PASS([json hasPrefix: @"{\n  \"format\": \"mad.report/1\","], "the schema is named first");
	MAD_PASS([json rangeOfString: @"\"driver\": \"Sqlite 3\""].location != NSNotFound, "the driver is named");
	MAD_PASS([json rangeOfString: @"\"rowCount\": 76"].location != NSNotFound, "the row count is the cache's");
	MAD_PASS([json rangeOfString: @"\"name\": \"City\""].location != NSNotFound,
			 "a column carries the schema field's name");
	MAD_PASS([json rangeOfString: @"\"table\": \"Customer\""].location != NSNotFound,
			 "a column carries the schema table's name");
	MAD_PASS([json rangeOfString: @"\"type\": \"String\""].location != NSNotFound,
			 "a column carries a stable type token");
	MAD_PASS([json rangeOfString: @"\"\\\"Invoice0\\\".\\\"Total\\\"\": 0.99"].location != NSNotFound,
			 "a real keeps its exact value -- not 0.99000000000000005 and not a string");
	MAD_PASS([json rangeOfString: @"\"\"Customer0\"\".\"\"City\"\"\": \"London\""].location == NSNotFound,
			 "the row keys are escaped JSON strings, not CSV-quoted");
	MAD_PASS([json rangeOfString: @"\"\\\"Customer0\\\".\\\"City\\\"\": \"London\""].location != NSNotFound,
			 "a row is keyed by the column key and carries the value");
	// One line per row, and the object closes without a trailing comma.
	MAD_PASS([json hasSuffix: @"\n  ]\n}\n"], "the rows array closes the object");
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0xB548747AC759A4ABULL),
				   "the json export's bytes are the ones the Mac writes (see this file's header)");
}

static void testTheJSONReportAddsTheRenderedReport(void) {
	MAD_EXPORTER_REQUIRE_FIXTURE();
	NSData *data = MADExporterOutput([MADReportExporterJSONReport class], @"london.report.json");
	if (data == nil) return;
	NSString *json = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

	// The data half is the json format's, and the report member follows it.
	MAD_PASS([json hasPrefix: @"{\n  \"format\": \"mad.report/1\","], "the schema is named first");
	MAD_PASS([json rangeOfString: @"\"rows\": ["].location != NSNotFound, "the rows are the data half's");
	MAD_PASS([json rangeOfString: @"\"report\": {\n    \"pages\": [\n"].location != NSNotFound,
			 "the report member holds the pages");
	MAD_PASS([json rangeOfString: @"\"type\": \"ReportHeader\""].location != NSNotFound,
			 "a section carries its type");
	MAD_PASS([json rangeOfString: @"\"kind\": \"LabelStatic\", \"frame\": ["].location != NSNotFound,
			 "a line carries its element kind and where it sits on the page");
	MAD_PASS([json rangeOfString: @"\"text\": \"Sales Report\""].location != NSNotFound,
			 "and its resolved text");
	// The frames are page coordinates: the trim box's 1pt origin, not the section's 0.
	MAD_PASS([json rangeOfString: @"\"frame\": [1, 1, 170, 29]" ].location != NSNotFound,
			 "the first line sits at the page's trim corner, where the PDF draws it");
	// The render side's bytes are the Mac's, like text/csv/json: the money in the
	// report is formatted from the document's own locale and precision, not the
	// machine's, so the same document writes the same report here (docs/project/registers/BUGS.md).
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0x499761E44D3BDD39ULL),
				   "the report member's bytes are the ones the Mac writes");
}

static void testTheHTMExportIsAFacsimileOfThePages(void) {
	MAD_EXPORTER_REQUIRE_FIXTURE();
	NSData *data = MADExporterOutput([MADReportExporterHTML class], @"london.html");
	if (data == nil) return;
	NSString *html = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

	MAD_PASS([html hasPrefix: @"<!doctype html>\n<html lang=\"en\">\n"], "it is an HTML file");
	MAD_PASS([html rangeOfString: @"<title>London.portable</title>"].location != NSNotFound, "titled for the document");
	// One CSS page box per walked page, at the PDF's own page size.
	MAD_PASS([html rangeOfString: @"@page { size: 612pt 792pt; margin: 0 }"].location != NSNotFound,
			 "the printed page is the PDF's page");
	NSUInteger pages = 0;
	for (NSString *piece in [html componentsSeparatedByString: @"<div class=\"page\""]) pages++;
	MAD_PASS(pages - 1 == 5, "five page boxes for the five the walk lays out");
	MAD_PASS([html rangeOfString: @"data-kind=\"LabelStatic\" style=\"left:1pt; top:1pt; width:170pt; height:29pt;" ].location != NSNotFound,
			 "an element is a box at its walked frame");
	MAD_PASS([html rangeOfString: @"font-family:'Verdana', sans-serif; font-size:22pt; font-weight:bold"].location != NSNotFound,
			 "styled with the element's own font, size and traits");
	MAD_PASS([html rangeOfString: @"Sales Report"].location != NSNotFound, "and it carries the report's text");
	MAD_PASS([html rangeOfString: @"white-space: pre; overflow: hidden; text-overflow: ellipsis"].location != NSNotFound,
			 "one line, clipped with an ellipsis: the renderer's own line-break rule");
	MAD_PASS([html hasSuffix: @"</body>\n</html>\n"], "and it closes");
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0xC3B163A710CA3B6FULL),
				   "the facsimile's bytes are the ones the Mac writes");
}

static void testTheHTMLFlowExportIsTheSectionsAndRows(void) {
	MAD_EXPORTER_REQUIRE_FIXTURE();
	NSData *data = MADExporterOutput([MADReportExporterHTMLFlow class], @"london.flow.html");
	if (data == nil) return;
	NSString *html = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

	MAD_PASS([html rangeOfString: @"<section data-type=\"ReportHeader\" data-visible=\"true\">"].location != NSNotFound,
			 "a section is a section");
	MAD_PASS([html rangeOfString: @"<section data-type=\"Body\" data-visible=\"true\">"].location != NSNotFound,
			 "the detail rows are one");
	MAD_PASS([html rangeOfString: @"<tr><td class=\"s"].location != NSNotFound, "a row is a table row");
	MAD_PASS([html rangeOfString: @"data-kind=\"LabelDynamic\""].location != NSNotFound, "a cell says what kind of element it is");
	MAD_PASS([html rangeOfString: @"Blue Rythm Fantasy"].location != NSNotFound, "and carries the data");
	// The page furniture is emitted once, not once per page.
	NSUInteger headers = 0;
	for (NSString *piece in [html componentsSeparatedByString: @"data-type=\"PageHeader\""]) headers++;
	MAD_PASS(headers - 1 == 1, "the page header appears once, not five times");
	// A style table rather than an inline style per cell.
	MAD_PASS([html rangeOfString: @".s1 { font-family:"].location != NSNotFound, "the styles are a class table");
	MAD_PASS([html rangeOfString: @"<section data-type=\"GroupFooter\" data-group-level=\"0\" data-visible=\"false\">"].location != NSNotFound,
			 "an invisible section is named and left empty");
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0x6310CBA068B4934FULL),
				   "the reflowable file's bytes are the ones the Mac writes");
}

#pragma mark - The defined order, shared by the three comparison sites

static NSComparisonResult MADExporterCollationResult(NSString *lhs, NSString *rhs) {
	const char *l = lhs.UTF8String;
	const char *r = rhs.UTF8String;
	int result = compare_string_utf8_localized_asc_collation(NULL,
															 (int)[lhs lengthOfBytesUsingEncoding:NSUTF8StringEncoding], l,
															 (int)[rhs lengthOfBytesUsingEncoding:NSUTF8StringEncoding], r);
	return (NSComparisonResult)result;
}

static void testTheFormatterComparesStringGroupKeysByTheDefinedOrder(void) {
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
			NSComparisonResult expected = [lhs mad_orderedCompare: rhs];
			NSComparisonResult formatterResult = [MADReportFormatter compareValue: lhs
																		withValue: rhs
																	  forDataType: MADDataTypeString];
			MAD_PASS(formatterResult == expected,
					 "the formatter and -mad_orderedCompare: agree on '%s' vs '%s'",
					 lhs.UTF8String, rhs.UTF8String);
			MAD_PASS(MADExporterCollationResult(lhs, rhs) == expected,
					 "the collation and -mad_orderedCompare: agree on '%s' vs '%s'",
					 lhs.UTF8String, rhs.UTF8String);
		}
	}
}

#pragma mark - The value presentations, shared by the formats

static void testNumbersAreSpelledInOneRoundTripForm(void) {
	MAD_PASS_EQUAL([MADReportExportSource stringForNumber: @1], @"1", "an integer");
	MAD_PASS_EQUAL([MADReportExportSource stringForNumber: @3.0], @"3", "an integral real prints as an integer");
	MAD_PASS_EQUAL([MADReportExportSource stringForNumber: @0.99], @"0.99", "a real keeps its digits");
	MAD_PASS_EQUAL([MADReportExportSource stringForNumber: @(0.1 + 0.2)], @"0.30000000000000004",
				   "a real that needs 17 digits gets them");
}

static void testDatesAreISO8601InUTC(void) {
	NSDate *date = [NSDate dateWithTimeIntervalSince1970: 979257600];	// 2001-01-12 00:00:00Z
	MAD_PASS_EQUAL([MADReportExportSource stringForDate: date], @"2001-01-12T00:00:00Z", "the ISO 8601 UTC spelling");
}

#pragma mark - Publication

static void testSuccessfulRefreshPublishesOneCompleteResult(void) {
	MADHeadlessDocument *document = MADExporterNewPublicationDocument();
	MAD_PASS(document != nil, "the London fixture could not be copied and opened");
	if (document == nil) return;

	NSError *error = nil;
	MAD_PASS(MADExporterRefreshDocument(document, &error), "the refresh publishes: %s", [[error description] UTF8String]);
	MADDataResult *result = document.currentResult;
	MAD_PASS(result != nil, "the refresh published a result");
	MAD_PASS(result.identifier.length > 0, "the result has a generation identifier");
	MAD_PASS(result.rowDatabaseURL != nil, "the result names its row database");
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath: result.rowDatabaseURL.path], "the row database exists");
	MAD_PASS_EQUAL(result.columnMapURL.path, document.urlDataTableCache.path, "the column map is the stable one");
	MAD_PASS(result.numberOfRows == document.numberOfResults, "the result's row count is the document's");
	MAD_PASS(result.numberOfRows == (NSUInteger)76, "the London fixture published 76 rows");
	MAD_PASS_EQUAL(result.columnKeys, document.mainQuery.fieldKeys, "the columns are the active-field projection");
	for (NSString *key in result.columnKeys) {
		MAD_PASS(result.columns[key] != nil, "the column map has %s", [key UTF8String]);
		MAD_PASS_EQUAL(result.columns[key].identifier, key, "the column key is the field key");
	}

	MADDataTableFast *reopened = [[MADDataTableFast alloc] initWithId: document.filename.hash];
	reopened.cacheDelegate = document;
	MAD_PASS([reopened loadFromCacheWithUrl: document.urlDataTableCache error: &error],
			 "the stable cache reopens: %s", [[error description] UTF8String]);
	MAD_PASS(reopened.numberOfRows == result.numberOfRows, "the reopened table has the published rows");
	MAD_PASS(reopened.columnKeys.count == result.columnKeys.count, "the reopened table has the published columns");
}

static void testZeroRowRefreshPublishesTheProjectedColumns(void) {
	MADHeadlessDocument *document = MADExporterNewPublicationDocument();
	MAD_PASS(document != nil, "the London fixture could not be copied and opened");
	if (document == nil) return;

	RptqQueryPredicate *predicate = MADExporterAddImpossiblePredicate(document);
	MAD_PASS(predicate != nil, "the fixture has an integer query field to constrain");
	NSError *error = nil;
	MAD_PASS(MADExporterRefreshDocument(document, &error), "the zero-row refresh publishes: %s", [[error description] UTF8String]);
	MADDataResult *result = document.currentResult;
	MAD_PASS(result != nil, "the zero-row refresh published a result");
	MAD_PASS(result.numberOfRows == (NSUInteger)0, "the published result has no rows");
	MAD_PASS(result.columnKeys.count > 0, "the published result still has columns");
	MAD_PASS_EQUAL(result.columnKeys, document.mainQuery.fieldKeys, "the columns are the projection");
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath: result.rowDatabaseURL.path], "the row table exists");
}

static void testFailedPublicationLeavesTheLastResultUsable(void) {
	MADFailingPublicationDocument *document = MADExporterNewPublicationDocument();
	MAD_PASS(document != nil, "the London fixture could not be copied and opened");
	if (document == nil) return;

	NSError *error = nil;
	MAD_PASS(MADExporterRefreshDocument(document, &error), "A publishes: %s", [[error description] UTF8String]);
	MADDataResult *a = document.currentResult;
	MAD_PASS(a != nil, "A is published");
	NSUInteger aRows = a.numberOfRows;
	NSArray *aKeys = a.columnKeys;
	NSString *aIdentifier = a.identifier;
	NSString *aRowPath = a.rowDatabaseURL.path;
	MAD_PASS(aRows == (NSUInteger)76, "A has the fixture's rows");

	MADReportExportSource *pinned = [MADReportExportSource sourceWithDocument: document error: &error];
	MAD_PASS(pinned != nil, "the export source pins A");
	MAD_PASS(pinned.numberOfRows == aRows, "the pinned source sees A's rows");
	MAD_PASS_EQUAL(pinned.columnKeys, aKeys, "the pinned source sees A's columns");

	// B is a different result: same projection, zero rows.  Its rows are written,
	// then the publication commit is forced to fail.
	RptqQueryPredicate *predicate = MADExporterAddImpossiblePredicate(document);
	MAD_PASS(predicate != nil, "B constrains an integer field");
	document.failPublication = YES;
	error = nil;
	MAD_PASS(!MADExporterRefreshDocument(document, &error), "the forced publication fails the refresh");
	MAD_PASS(error != nil, "the failed refresh reports an error");
	document.failPublication = NO;
	MADExporterRemovePredicate(document, predicate);

	MADDataResult *current = document.currentResult;
	MAD_PASS(current != nil, "A is still current");
	MAD_PASS_EQUAL(current.identifier, aIdentifier, "A's generation is still current");
	MAD_PASS_EQUAL(current.columnKeys, aKeys, "A's column map is still current");
	MAD_PASS(current.numberOfRows == aRows, "A's rows are still current");
	MAD_PASS_EQUAL(current.rowDatabaseURL.path, aRowPath, "A's row database is still current");
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath: aRowPath], "A's row database is still there");

	MADReportExportSource *fresh = [MADReportExportSource sourceWithDocument: document error: &error];
	MAD_PASS(fresh != nil, "a fresh export source pins A");
	MADReportExportSource *sources[] = { pinned, fresh };
	for (int index = 0; index < 2; index++) {
		MADReportExportSource *source = sources[index];
		MAD_PASS(source.numberOfRows == aRows, "the source sees A's rows");
		MAD_PASS_EQUAL(source.columnKeys, aKeys, "the source sees A's columns");
		NSDictionary *firstRow = source.rowEnumerator.nextObject;
		MAD_PASS(firstRow != nil, "the source reads A's first row");
		for (NSString *key in aKeys) {
			MAD_PASS(firstRow[key] != nil, "the row still has %s", [key UTF8String]);
		}
	}
}

static void testRenderOperationPinsOneGeneration(void) {
	MADHeadlessDocument *document = MADExporterNewPublicationDocument();
	MAD_NEED(document != nil, "the London fixture could not be copied and opened");
	if (document == nil) return;

	NSError *error = nil;
	MAD_PASS(MADExporterRefreshDocument(document, &error), "A publishes: %s", [[error description] UTF8String]);
	MAD_PASS(document.currentResult.numberOfRows == (NSUInteger)76, "A has the fixture's rows");

	// Render A: the formatter pins the render data source to A.
	[MADReportPageBuilder prepareDocumentForRender: document];
	MAD_PASS(document.reportFormatter.numberOfPages > 0, "A produced pages");
	NSDictionary *firstA = [document dataForRowReportFirst];
	MAD_PASS(firstA != nil, "A's first detail row is readable");

	// Publish a visibly different B: zero rows, same projection.
	RptqQueryPredicate *predicate = MADExporterAddImpossiblePredicate(document);
	MAD_PASS(predicate != nil, "B constrains an integer field");
	MAD_PASS(MADExporterRefreshDocument(document, &error), "B publishes: %s", [[error description] UTF8String]);
	MAD_PASS(document.numberOfResults == (NSUInteger)0, "the data half sees B's zero rows");
	MAD_PASS(document.currentResult.numberOfRows == (NSUInteger)0, "B's generation is published");

	// The in-flight render operation is still pinned to A.
	NSDictionary *stillFirstA = [document dataForRowReportFirst];
	MAD_PASS(stillFirstA != nil, "the pinned render still reads A's first row");
	MAD_PASS_EQUAL(stillFirstA, firstA, "the pinned render reads the same A row");

	// A new render pins B and re-paginates.
	[MADReportPageBuilder prepareDocumentForRender: document];
	MAD_PASS(document.currentResult.numberOfRows == (NSUInteger)0, "B is still the current generation");
	MAD_PASS([document dataForRowReportFirst] == nil, "B has no detail row to read");

	MADExporterRemovePredicate(document, predicate);
}

static void testFailedFirstRefreshThenRetryPublishes(void) {
	MADFailingPublicationDocument *document = MADExporterNewPublicationDocument();
	MAD_PASS(document != nil, "the London fixture could not be copied and opened");
	if (document == nil) return;

	document.failPublication = YES;
	NSError *error = nil;
	MAD_PASS(!MADExporterRefreshDocument(document, &error), "the first refresh fails at publication");
	MAD_PASS(error != nil, "the failed first refresh reports an error");
	MAD_PASS(document.currentResult == nil, "there is no result before the first success");
	MAD_PASS(document.numberOfResults == (NSUInteger)0, "the row table is empty");

	document.failPublication = NO;
	error = nil;
	MAD_PASS(MADExporterRefreshDocument(document, &error), "the retry publishes: %s", [[error description] UTF8String]);
	MAD_PASS(document.currentResult != nil, "the retry published a result");
	MAD_PASS(document.currentResult.numberOfRows == (NSUInteger)76, "the retry has the fixture's rows");
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath: document.currentResult.rowDatabaseURL.path],
			 "the retry wrote the row table");
}

#pragma mark - Composition

// The first composition join, through the engine's own SQLite.  Two small
// portable documents (invoices, payments) are refreshed through the ordinary
// chain, their committed .maddb files are attached read-only, and the root
// join is materialized into a fresh result read back through MADDataResult.

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

/// Write a schema and rows into a SQLite file using the engine's driver.
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

/// A document whose imported schema has one table; add a one-table query whose
/// active fields are `activeFields` (the join key is one of them; other columns
/// stay out of the projection).
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

/// Build a refreshed document whose query projects `activeFields` of `tableName`.
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
	if (!MADExporterRefreshDocument(document, &error)) { if (outError) *outError = error.description; return nil; }
	return document;
}

/// The full logical key a published result uses for a source field.
static NSString *MADCompositionLogicalKey(MADDataResult *result, NSString *fieldName) {
	for (NSString *key in result.columnKeys) {
		if ([key rangeOfString: fieldName].location != NSNotFound) {
			return key;
		}
	}
	return nil;
}

/// Open a composition connection that can attach read-only URI databases.
static MADDatabaseSqlite3 *MADCompositionConnection(NSURL *composerURL) {
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: composerURL];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	database.databaseConnection = connection;
	[database openDatabaseWithFlags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_URI];
	return database;
}


// Two documents: three invoices (one with an unused `note` column) and two
// payments for invoice 1.  Both projects join the key and its amount; the other
// columns stay out of the projection.

// Refresh payments to zero rows; the LEFT JOIN keeps all three invoices with
// NULL payment fields.

// The attachment surface: read-only enforcement, a missing file, and the limit.
static void testCompositionAttachGuards(void) {
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
	MAD_NEED(invoices != nil, @"the invoices document opened");
	if (invoices == nil) return;

	NSURL *composerURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"composer.sqlite"]];
	MADDatabaseSqlite3 *composer = MADCompositionConnection(composerURL);
	NSError *error = nil;
	MAD_PASS([composer attachReadOnlyDatabaseAtURL: invoices.currentResult.rowDatabaseURL asName: @"inv" error: &error],
			 "the read-only attach succeeds");

	// Read-only enforcement: writing into the attached database is refused.
	NSString *writeSQL = [NSString stringWithFormat: @"INSERT INTO inv.%@ DEFAULT VALUES", invoices.currentResult.dataTable.tableName];
	BOOL wrote = [composer executeSQL: writeSQL fieldKeys: @[] onConnection: nil intoResultTable: nil
					  transactionSet: NO returnsResults: NO binaryBindings: nil withError: &error];
	MAD_PASS(!wrote, "a write into the read-only attachment is refused");

	// A missing input file fails the attach and leaves the inputs usable.
	error = nil;
	NSURL *missing = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"nope.maddb"]];
	MAD_PASS(![composer attachReadOnlyDatabaseAtURL: missing asName: @"bad" error: &error],
			 "a missing input file fails to attach");
	MAD_PASS(error != nil, "the missing input reports an error");
	MAD_PASS(invoices.currentResult.numberOfRows == (NSUInteger)3, "the invoices input is still usable");
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath: invoices.currentResult.rowDatabaseURL.path],
			 "the invoices row file is still present");

	// The attachment limit: ten attachments fit, the eleventh is refused.
	for (NSUInteger i = 2; i <= 11; i++) {
		NSString *name = [NSString stringWithFormat: @"db%lu", (unsigned long)i];
		BOOL ok = [composer attachReadOnlyDatabaseAtURL: invoices.currentResult.rowDatabaseURL asName: name error: &error];
		if (i <= 10) {
			MAD_PASS(ok, "attachment %lu is accepted", (unsigned long)i);
		} else {
			MAD_PASS(!ok, "the eleventh attachment is refused");
			MAD_PASS(error != nil, "the attachment limit reports an error");
		}
	}
}

// The root ORDER BY over a text key must use the LSASC collation the MAD
// connection registers -- a raw sqlite3 handle would reject it.

// The attach helper must percent-encode a URI-reserved or Unicode path and quote
// an alias that needs it, so read-only cannot silently become writable.
static void testCompositionAttachUnicodeReservedPathAndAlias(void) {
	// A unique root so the run never collides with a previous run's files; the tail
	// still carries Unicode and URI-reserved characters in the path.
	NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	// '?' is a DOS wildcard and cannot name a Windows file or directory; '#' and '%'
	// are legal on every platform and still exercise the URI-reserved encoding.
	NSString *directory = [root stringByAppendingPathComponent: @"Café #% ü"];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *db = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"data #%.sqlite"]];
	MAD_PASS(MADCompositionCreateSource(db, @[
		@"CREATE TABLE t (id INTEGER, v TEXT);",
		@"INSERT INTO t VALUES (1, 'one');"]), "the unicode-path source is written");

	NSURL *composerURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"composer.sqlite"]];
	MADDatabaseSqlite3 *composer = MADCompositionConnection(composerURL);
	NSError *error = nil;
	// A space-containing alias, and a path with Unicode and URI-reserved characters.
	MAD_PASS([composer attachReadOnlyDatabaseAtURL: db asName: @"my attached db" error: &error],
			 "the unicode path attaches: %s", [[error description] UTF8String]);
	BOOL wrote = [composer executeSQL: @"INSERT INTO \"my attached db\".t DEFAULT VALUES"
							fieldKeys: @[] onConnection: nil intoResultTable: nil
					   transactionSet: NO returnsResults: NO binaryBindings: nil withError: &error];
	MAD_PASS(!wrote, "the attached file is read-only through its encoded path and quoted alias");
}

// The attachment limit, reported against the engine-linked SQLite rather than the
// host build.
static void testCompositionAttachmentLimitAndSQLiteVersion(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *db = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"invoices.sqlite"]];
	MAD_PASS(MADCompositionCreateSource(db, @[
		@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL);",
		@"INSERT INTO invoices VALUES (1, 100.0);"]), "the invoices source is written");

	NSString *errorDescription = nil;
	MADHeadlessDocument *invoices = MADCompositionDocument(@"invoices.mad", db, @"invoices", @[@"invoice_id"], &errorDescription);
	MAD_NEED(invoices != nil, @"the invoices document opened");
	if (invoices == nil) return;

	NSURL *composerURL = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"composer.sqlite"]];
	MADDatabaseSqlite3 *composer = MADCompositionConnection(composerURL);
	sqlite3 *handle = (sqlite3 *)composer.databaseHandle;
	int effectiveLimit = sqlite3_limit(handle, SQLITE_LIMIT_ATTACHED, -1);
	const char *version = sqlite3_libversion();
	printf("composition connection: SQLite %s, effective SQLITE_MAX_ATTACHED %d\n", version, effectiveLimit);
	MAD_PASS(effectiveLimit > 0, "the connection reports its attach limit");

	NSError *error = nil;
	for (int i = 0; i < effectiveLimit; i++) {
		NSString *name = [NSString stringWithFormat: @"db%d", i];
		MAD_PASS([composer attachReadOnlyDatabaseAtURL: invoices.currentResult.rowDatabaseURL asName: name error: &error],
				 "attachment %d within the limit: %s", i, [[error description] UTF8String]);
	}
	error = nil;
	MAD_PASS(![composer attachReadOnlyDatabaseAtURL: invoices.currentResult.rowDatabaseURL asName: @"overflow" error: &error],
			 "one past the limit is refused");
	MAD_PASS(error != nil, "the attachment limit reports an error");
}

// The root's join key lives only on the payments side and is not otherwise
// projected; the composer must still project it as a required field.

// A zero-row refresh over a typed column must still expose the column's declared
// type, not the String fallback for an untyped empty expression.
static void testCompositionEmptyExpressionKeepsKnownType(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *db = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"invoices.sqlite"]];
	MAD_PASS(MADCompositionCreateSource(db, @[
		@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL);",
		@"INSERT INTO invoices VALUES (1, 100.0);"]), "the invoices source is written");

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionDocument(@"invoices.mad", db, @"invoices",
														   @[@"invoice_id", @"amount"], &errorDescription);
	MAD_NEED(document != nil, @"the document opened and refreshed");
	if (document == nil) return;
	MAD_PASS(document.currentResult.numberOfRows == (NSUInteger)1, "the document has one row");

	// Force a zero-row refresh.
	RptqQueryPredicate *predicate = MADExporterAddImpossiblePredicate(document);
	MAD_PASS(predicate != nil, "the query has an integer key to constrain");
	NSError *error = nil;
	MAD_PASS(MADExporterRefreshDocument(document, &error), "the document refreshes to zero rows: %s", [[error description] UTF8String]);

	MADDataResult *empty = document.currentResult;
	MAD_PASS(empty.numberOfRows == (NSUInteger)0, "the result is empty");
	NSString *invoiceKey = MADCompositionLogicalKey(empty, @"invoice_id");
	NSString *amountKey = MADCompositionLogicalKey(empty, @"amount");
	MAD_PASS(invoiceKey != nil, "the empty result keeps the invoice_id column");
	MAD_PASS(amountKey != nil, "the empty result keeps the amount column");
	MADDataType invoiceType = empty.columns[invoiceKey].type;
	MADDataType amountType = empty.columns[amountKey].type;
	MAD_PASS(invoiceType == MADDataTypeInteger, "the empty integer column keeps its declared type");
	MAD_PASS(amountType == MADDataTypeDouble, "the empty real column keeps its declared type");
}

static RptqObject *MADCompositionGraphInsert(RptqStoreContext *context, NSString *entity, int64_t identifier) {
	return [context insertObjectForEntity: entity identifier: identifier];
}

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

static double MADCompositionCell(MADDataTableFast *table, NSUInteger row, NSString *key) {
	NSDictionary *dict = [table dataForRow: row column: key error: NULL];
	id value = dict[key];
	if (value == nil || value == [NSNull null]) return NAN;
	return [value doubleValue];
}

/// Builds an N-node composed document from leaf and composer descriptions, through
/// the production store and archive writers, reopened as a headless document.
/// A leaf is @{@"name", @"file", @"rows"}; a composer is @{@"name", @"children",
/// @"links", @"outputs"} with the same shapes as the Apple suite's helper.
static MADHeadlessDocument *MADCompositionGraphDocument(NSString *directory,
														NSArray *leaves,
														NSArray *composers,
														NSString *rootName,
														NSString **outError) {
	for (NSDictionary *leaf in leaves) {
		NSString *name = leaf[@"name"];
		NSURL *url = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: leaf[@"file"]]];
		NSMutableArray *statements = [NSMutableArray arrayWithObject:
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

	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext: context];
	int64_t counter = 1000;

	NSMutableDictionary *queryByName = [NSMutableDictionary dictionary];
	NSMutableDictionary *columnsByName = [NSMutableDictionary dictionary];
	NSMutableDictionary *schemaFieldsByName = [NSMutableDictionary dictionary];
	NSMutableDictionary *schemaTablesByName = [NSMutableDictionary dictionary];
	NSMutableArray *databases = [NSMutableArray array];

	for (NSDictionary *leaf in leaves) {
		NSString *name = leaf[@"name"];
		NSURL *url = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: leaf[@"file"]]];

		RptqObject *database = MADCompositionGraphInsert(context, @"RptqDatabase", counter++);
		[database setValue: @"Sqlite 3" forKey: @"databaseDriverType"];
		RptqObject *credential = MADCompositionGraphInsert(context, @"RptqDatabaseCredentals", counter++);
		[credential setValue: url.lastPathComponent forKey: @"dbname"];
		[credential setValue: url.path forKey: @"host"];
		[database setValue: credential forKey: @"ownedByUser"];

		RptqObject *table = MADCompositionGraphInsert(context, @"RptqDatabaseSchemaTable", counter++);
		[table setValue: name forKey: @"name"];
		RptqObject *idField = MADCompositionGraphInsert(context, @"RptqDatabaseSchemaField", counter++);
		[idField setValue: @"id" forKey: @"name"];
		RptqObject *valueField = MADCompositionGraphInsert(context, @"RptqDatabaseSchemaField", counter++);
		[valueField setValue: @"value" forKey: @"name"];
		[database setValue: @[ table ] forKey: @"hasTables"];
		[table setValue: @[ idField, valueField ] forKey: @"hasFields"];

		RptqObject *query = MADCompositionGraphInsert(context, @"RptqQuery", counter++);
		[query setValue: name forKey: @"name"];
		[database setValue: @[ query ] forKey: @"hasQueries"];
		RptqObject *queryTable = MADCompositionGraphInsert(context, @"RptqQueryTable", counter++);
		[queryTable setValue: table forKey: @"databaseSchemaTable"];
		[queryTable setValue: query forKey: @"inQuery"];

		NSMutableArray *fields = [NSMutableArray array];
		NSArray *schemaFields = @[ idField, valueField ];
		for (RptqObject *schemaField in schemaFields) {
			RptqObject *field = MADCompositionGraphInsert(context, @"RptqQueryField", counter++);
			[field setValue: schemaField forKey: @"databaseSchemaField"];
			[field setValue: queryTable forKey: @"inQueryTable"];
			[fields addObject: field];
			RptqObject *label = MADCompositionGraphInsert(context, @"RptqDocumentElementLabelDataField", counter++);
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
		NSArray *children = composer[@"children"];
		RptqObject *rootQuery = MADCompositionGraphInsert(context, @"RptqQuery", counter++);
		[rootQuery setValue: name forKey: @"name"];
		[rootQuery setValue: databases.firstObject forKey: @"inDatabase"];

		NSMutableDictionary *fieldsByChild = [NSMutableDictionary dictionary];
		NSMutableArray *rootTables = [NSMutableArray array];
		for (NSString *childName in children) {
			RptqObject *childQuery = queryByName[childName];
			RptqObject *rootTable = MADCompositionGraphInsert(context, @"RptqQueryTable", counter++);
			[rootTable setValue: rootQuery forKey: @"inQuery"];
			[rootTable setValue: childQuery forKey: @"upstreamQuery"];

			NSDictionary *childSchema = schemaFieldsByName[childName];
			NSMutableDictionary *fieldsByCol = [NSMutableDictionary dictionary];
			NSMutableArray *fields = [NSMutableArray array];
			for (NSString *col in columnsByName[childName]) {
				RptqObject *field = MADCompositionGraphInsert(context, @"RptqQueryField", counter++);
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
			RptqObject *remoteTable = MADCompositionGraphInsert(context, @"RptqQueryTable", counter++);
			[remoteTable setValue: rootQuery forKey: @"inQuery"];
			[remoteTable setValue: schemaTablesByName[remoteName] forKey: @"databaseSchemaTable"];
			RptqObject *remoteField = MADCompositionGraphInsert(context, @"RptqQueryField", counter++);
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
			RptqObject *ql = MADCompositionGraphInsert(context, @"RptqQueryLinks", counter++);
			[ql setValue: @(MADLinkTypeLeftOuterJoin) forKey: @"type"];
			[ql setValue: leftField forKey: @"hasLeftField"];
			[ql setValue: rightField forKey: @"hasRightField"];
			[ql setValue: rootQuery forKey: @"inQuery"];
			[links addObject: ql];
		}
		[rootQuery setValue: links forKey: @"hasQueryLinks"];

		NSMutableArray *outputColumns = [NSMutableArray array];
		NSMutableDictionary *outputSchema = [NSMutableDictionary dictionary];
		NSArray *outputs = composer[@"outputs"];
		for (NSUInteger idx = 0; idx < outputs.count; idx++) {
			NSArray *output = outputs[idx];
			NSString *child = output[0], *col = output[1], *outputKey = output[2];
			RptqObject *field = fieldsByChild[child][col];
			[field setValue: outputKey forKey: @"outputKey"];
			[field setValue: @(idx) forKey: @"outputIndex"];
			[outputColumns addObject: outputKey];
			outputSchema[outputKey] = schemaFieldsByName[child][col];
		}

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

/// The connection-string → credential map the composed refresh is keyed by, built the
/// way the CLI does: one entry per source database, from its persisted credential row.
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

/// The same credentials keyed by leaf query id — the map `mad serve` now supplies, and
/// the one that can distinguish two sources on an identical connection string.
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

// The query-id map is what lets two sources on one connection string carry different
// credentials; the connection-string map remains the next fallback, then the single
// credential.  This pins the precedence without a live server.
static void testComposedCredentialMapPrefersQueryIdentifier(void) {
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

	MAD_PASS([[refresh credentialForQueryIdentifier: 10 connectionString: connectionString fallbackCredential: fallback].username isEqualToString: @"first"],
			 "two query ids sharing one connection string keep different credentials (first)");
	MAD_PASS([[refresh credentialForQueryIdentifier: 11 connectionString: connectionString fallbackCredential: fallback].username isEqualToString: @"second"],
			 "two query ids sharing one connection string keep different credentials (second)");
	MAD_PASS([[refresh credentialForQueryIdentifier: 12 connectionString: connectionString fallbackCredential: fallback].username isEqualToString: @"shared"],
			 "a query not in the id map falls back to the connection-string entry");
	MAD_PASS([[refresh credentialForQueryIdentifier: 12 connectionString: @"(MySQL)[host:3306]other" fallbackCredential: fallback].username isEqualToString: @"fallback"],
			 "a query with no map entry falls back to the single credential");
}

// The composed refresh takes one credential per source, keyed by that source's query
// id (the map `mad serve` supplies), and a source that fails names itself — name,
// query id and connection string — which is what the serve error and the WPF prompt
// rely on.  The sources are SQLite, so no live server is needed to pin the contract.
static void testComposedRefreshUsesPerSourceCredentialsAndNamesTheFailingSource(void) {
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
	MAD_NEED(document != nil, "the two-source composition opened");
	if (document == nil) return;

	// The older connection-string map still refreshes, for callers that have not moved.
	NSDictionary<NSString *, MADCredential *> *legacy = MADCompositionCredentialsMap(document);
	MAD_PASS(legacy.count == 2, "each source has its own connection-string credential");
	MAD_PASS(MADCompositionRunRefreshWithCredentials(document, legacy).errors.count == 0,
			 "the connection-string credential map still refreshes the composition");

	NSDictionary<NSNumber *, MADCredential *> *credentials = MADCompositionCredentialsByQueryIdentifier(document);
	MAD_PASS(credentials.count == 2, "each source has its own query-id credential");

	MADOperationRefreshComposed *refresh = MADCompositionRunRefreshWithQueryCredentials(document, credentials);
	MAD_PASS(refresh.errors.count == 0, "the per-source credentials refresh the composition");
	MAD_PASS(document.currentResult.numberOfRows == 1, "the join produced its row");

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
	MAD_PASS(bIdentifier != 0, "the b source has a query id");

	// Point one source at an impossible path: the next refresh must fail on it and name
	// it.  A path that does not resolve to a readable sibling keeps the test independent
	// of whether the first refresh still holds the source file open.
	MAD_PASS(bCredentialRow != nil, "the b source has a credential row");
	bCredentialRow.host = @"/no-such-directory/ghost.sqlite";
	bCredentialRow.dbname = @"ghost.sqlite";
	[document.storeContext saveComposed: NULL];
	MADOperationRefreshComposed *failed = MADCompositionRunRefreshWithQueryCredentials(document, credentials);
	MAD_PASS(failed.errors.count == 1, "the broken source fails the refresh");
	NSError *sourceError = failed.errors.firstObject;
	MAD_PASS([sourceError.userInfo[MADOperationRefreshSourceNameKey] isEqualToString: @"b"],
			 "the error names the failing source");
	NSNumber *queryIdentifier = sourceError.userInfo[MADOperationRefreshSourceQueryIdentifierKey];
	MAD_PASS(queryIdentifier != nil && [queryIdentifier longLongValue] == bIdentifier,
			 "the error carries the failing source's query id");
	NSString *connectionString = sourceError.userInfo[MADOperationRefreshSourceConnectionStringKey];
	MAD_PASS([connectionString containsString: @"ghost.sqlite"],
			 "the error carries the failing source's connection string");
}

// The composed refresh closes each leaf's SQLite handle after its query, so the source
// file is not left locked.  The file can be deleted, recreated, and picked up again by
// the next refresh — the behavior the impossible-path test used to work around.
static void testComposedRefreshClosesAndReopensSqliteSources(void) {
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
	MAD_NEED(document != nil, "the composition opened");
	if (document == nil) return;

	MAD_PASS(MADCompositionRunRefresh(document).errors.count == 0, "the first refresh closes its sources");
	MAD_PASS(document.currentResult.numberOfRows == 1, "the first refresh joined its row");

	NSString *bPath = [directory stringByAppendingPathComponent: @"b.sqlite"];
	int removeResult = MADCompositionDeleteFile(bPath);
	MAD_PASS(removeResult == 0,
			 "the refreshed source file is closed and can be removed (result %d)", removeResult);
	MAD_PASS(![[NSFileManager defaultManager] fileExistsAtPath: bPath],
			 "the source file is gone after the remove");

	NSURL *bURL = [NSURL fileURLWithPath: bPath];

	MAD_PASS(MADCompositionCreateSource(bURL, @[ @"CREATE TABLE b (id INTEGER, value REAL);",
												 @"INSERT INTO b VALUES (1, 20);"]),
			 "the source can be recreated after the close");
	MADOperationRefreshComposed *again = MADCompositionRunRefresh(document);
	MAD_PASS(again.errors.count == 0, "the recreated source refreshes through a new connection");
	MAD_PASS(document.currentResult.numberOfRows == 1, "the second refresh joined its row");
}

static void testComposedThreeLeafRootJoinsAllThree(void) {
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
	MAD_NEED(document != nil, "the composed document opened");
	if (document == nil) return;

	MADOperationRefreshComposed *refresh = MADCompositionRunRefresh(document);
	MAD_PASS(refresh.errors.count == 0, "the three-leaf refresh succeeds");
	MAD_PASS([document.currentResult.columnKeys isEqualToArray: (@[ @"a_id", @"a_value", @"b_value", @"c_value" ])], "the root projects in output order");
	MAD_PASS(document.currentResult.numberOfRows == 2, "the chain join keeps both left rows");

	MADDataTableFast *table = document.dataTable;
	MAD_PASS(MADCompositionCell(table, 1, @"a_id") == 1.0, "row 1 joins a/b/c");
	MAD_PASS(MADCompositionCell(table, 1, @"c_value") == 1000.0, "row 1 c value");
	MAD_PASS(MADCompositionCell(table, 2, @"a_id") == 2.0, "row 2 a id");
	MAD_PASS(MADCompositionCell(table, 2, @"b_value") == 200.0, "row 2 b value");
	MAD_PASS(isnan(MADCompositionCell(table, 2, @"c_value")), "row 2 has no c match");
}

static void testComposedNestedComposerRunsChildrenBeforeParents(void) {
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
	MAD_NEED(document != nil, "the nested document opened");
	if (document == nil) return;

	MADOperationRefreshComposed *refresh = MADCompositionRunRefresh(document);
	MAD_PASS(refresh.errors.count == 0, "the nested refresh succeeds");

	NSArray *order = refresh.executedNodeNames;
	MAD_PASS(order.count == 7, "all seven nodes execute");
	MAD_PASS([order.lastObject isEqualToString: @"C2"], "the root runs last");
	NSUInteger c1 = [order indexOfObject: @"C1"];
	MAD_PASS([order indexOfObject: @"A"] < c1, "A before C1");
	MAD_PASS([order indexOfObject: @"B"] < c1, "B before C1");
	MAD_PASS([order indexOfObject: @"R1"] < c1, "R1 before C1");
	MAD_PASS(c1 < [order indexOfObject: @"C2"], "C1 before C2");
	MAD_PASS([order indexOfObject: @"D"] < [order indexOfObject: @"C2"], "D before C2");
	MAD_PASS([order indexOfObject: @"R2"] < [order indexOfObject: @"C2"], "R2 before C2");
}

static void testComposedSharedChildRunsOnce(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[
		@{ @"name": @"A", @"file": @"a.sqlite", @"rows": @[ @[@1, @10] ] },
		@{ @"name": @"B", @"file": @"b.sqlite", @"rows": @[ @[@1, @20] ] },
	];
	NSArray *composers = @[
		@{ @"name": @"C1", @"children": @[ @"A", @"B" ],
		   @"links": @[], @"outputs": @[ @[ @"A", @"id", @"a_id" ] ] },
		@{ @"name": @"C2", @"children": @[ @"C1", @"A" ],
		   @"links": @[], @"outputs": @[ @[ @"C1", @"a_id", @"c1_id" ], @[ @"A", @"value", @"a_value" ] ] },
	];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"C2", &errorDescription);
	MAD_NEED(document != nil, "the diamond document opened");
	if (document == nil) return;

	MADOperationRefreshComposed *refresh = MADCompositionRunRefresh(document);
	MAD_PASS(refresh.errors.count == 0, "the diamond refresh succeeds");

	NSUInteger aCount = 0;
	for (NSString *name in refresh.executedNodeNames) {
		if ([name isEqualToString: @"A"]) aCount++;
	}
	MAD_PASS(aCount == 1, "the shared child runs once");
	MAD_PASS([refresh.executedNodeNames.lastObject isEqualToString: @"C2"], "the root runs last");
}

static void testComposedRootWithMoreThanTenChildrenIsRejected(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];

	NSMutableArray *leaves = [NSMutableArray array];
	NSMutableArray *children = [NSMutableArray array];
	NSMutableArray *outputs = [NSMutableArray array];
	for (NSUInteger i = 0; i < 11; i++) {
		NSString *name = [NSString stringWithFormat: @"leaf%lu", (unsigned long)i];
		[leaves addObject: @{ @"name": name, @"file": [name stringByAppendingString: @".sqlite"], @"rows": @[ @[@1, @10] ] }];
		[children addObject: name];
		[outputs addObject: @[ name, @"id", [name stringByAppendingString: @"_id"] ]];
	}
	NSArray *composers = @[ @{ @"name": @"root", @"children": children, @"links": @[], @"outputs": outputs } ];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"root", &errorDescription);
	MAD_NEED(document != nil, "the over-wide document opened");
	if (document == nil) return;

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	NSError *error = nil;
	MAD_PASS(![model validateCompositionGraphWithError: &error], "more than ten direct children is a design-time error");
	MAD_PASS(error != nil && [error.localizedDescription rangeOfString: @"root"].location != NSNotFound, "the error names the node");
}

static void testComposedMixedNodeIsRejected(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[ @{ @"name": @"a", @"file": @"a.sqlite", @"rows": @[ @[@1, @10] ] } ];
	NSArray *composers = @[ @{ @"name": @"root", @"children": @[ @"a" ], @"links": @[], @"outputs": @[ @[ @"a", @"id", @"a_id" ] ], @"remoteTables": @[ @"a" ] } ];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"root", &errorDescription);
	MAD_NEED(document != nil, "the mixed document opened");
	if (document == nil) return;

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	NSError *error = nil;
	MAD_PASS(![model validateCompositionGraphWithError: &error], "a node that mixes remote and upstream tables is a design-time error");
	MAD_PASS(error != nil && [error.localizedDescription rangeOfString: @"root"].location != NSNotFound, "the error names the offending node");
}

// A non-root node with an authored layout renders its OWN bands: the page walk draws the
// leaf's detail band and fills it with the leaf's elements, not the root's (empty) one.
static void testNodeScopedHTMLRendersTheNodeLayout(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSArray *leaves = @[ @{ @"name": @"a", @"file": @"a.sqlite", @"rows": @[ @[@1, @10], @[@2, @20] ] } ];
	NSArray *composers = @[ @{ @"name": @"root", @"children": @[ @"a" ], @"links": @[], @"outputs": @[ @[ @"a", @"id", @"a_id" ] ] } ];

	NSString *errorDescription = nil;
	MADHeadlessDocument *document = MADCompositionGraphDocument(directory, leaves, composers, @"root", &errorDescription);
	MAD_NEED(document != nil, "the composed document opened");
	if (document == nil) return;

	// Author the leaf's own layout: its five bands, a static label, and a data field bound
	// to the leaf's `value` column.
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *leaf = nil;
	for (RptqDatabase *database in model.hasDatabaseSchemas) {
		for (RptqQuery *query in database.hasQueries) {
			if ([query.name isEqualToString: @"a"]) { leaf = query; break; }
		}
		if (leaf != nil) break;
	}
	MAD_NEED(leaf != nil, "the leaf query is present");
	if (leaf == nil) return;

	NSArray<RptqDocumentSection *> *sections = [RptqDocumentSection createStructuralSectionsForQuery: leaf
																		managedObjectContext: document.storeContext];
	RptqDocumentSection *detail = nil;
	for (RptqDocumentSection *section in sections) {
		if (section.type == MADDocumentSectionTypeBody) { detail = section; break; }
	}
	MAD_NEED(detail != nil, "the leaf has a detail band");
	if (detail == nil) return;

	RptqDocumentElementLabel *label =
		(RptqDocumentElementLabel *)[document.storeContext insertObjectForEntity: NSStringFromClass([RptqDocumentElementLabel class]) identifier: 0];
	label.type = MADPrintPageElementTypeLabelStatic;
	label.text = @"NODE LABEL";
	[label setSizeWidth: 120.0f height: 20.0f];
	[detail addDocumentObject: label withDropPoint: CGPointMake(12.0f, 6.0f) managedObjectContext: document.storeContext];

	RptqQueryField *valueField = nil;
	for (RptqQueryTable *table in leaf.hasQueryTables) {
		for (RptqQueryField *field in table.hasQueryFields) {
			if ([field.databaseSchemaField.name isEqualToString: @"value"]) { valueField = field; break; }
		}
		if (valueField != nil) break;
	}
	MAD_NEED(valueField != nil, "the leaf's value field is present");
	if (valueField != nil) {
		RptqDocumentElementLabelDataField *dataField =
			(RptqDocumentElementLabelDataField *)[document.storeContext insertObjectForEntity: NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier: 0];
		dataField.type = MADPrintPageElementTypeLabelDynamic;
		dataField.referencesQueryField = valueField;
		[dataField setSizeWidth: 120.0f height: 20.0f];
		[detail addDocumentObject: dataField withDropPoint: CGPointMake(12.0f, 30.0f) managedObjectContext: document.storeContext];
	}

	NSError *error = nil;
	MAD_PASS([document.storeContext saveComposed: &error], "the authored leaf layout saved");
	MAD_PASS(MADCompositionRunRefresh(document).errors.count == 0, "the composition refreshed");

	NSURL *url = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent: @"leaf.html"]];
	MADReportExporterHTML *exporter = [[MADReportExporterHTML alloc] init];
	MAD_PASS([exporter exportDocument: document query: leaf toURL: url options: MADReportExportOptionsNone error: &error],
			 "the leaf exports its HTML");

	NSString *html = [NSString stringWithContentsOfURL: url encoding: NSUTF8StringEncoding error: NULL];
	MAD_PASS([html containsString: @"NODE LABEL"], "the leaf's HTML renders its own static label");
	MAD_PASS([html containsString: @"class=\"line\""], "the leaf's HTML has rendered lines");
}

MAD_TEST_MAIN("MADReportExporterTests",
	MAD_TEST(testTheFormatsAreRegistered),
	MAD_TEST(testTheRenderSideFormatsRegisterHere),
	MAD_TEST(testThePDFFormatRunsHere),
	MAD_TEST(testNumbersAreSpelledInOneRoundTripForm),
	MAD_TEST(testDatesAreISO8601InUTC),
	MAD_TEST(testTheFormatterComparesStringGroupKeysByTheDefinedOrder),
	MAD_TEST(testTheTextExportIsATableOfTheRows),
	MAD_TEST(testTheCSVExportIsTheRowsAndTheColumnKeys),
	MAD_TEST(testTheJSONExportIsTheSchemaAndTheRows),
	MAD_TEST(testTheJSONReportAddsTheRenderedReport),
	MAD_TEST(testTheHTMExportIsAFacsimileOfThePages),
	MAD_TEST(testTheHTMLFlowExportIsTheSectionsAndRows),
	MAD_TEST(testSuccessfulRefreshPublishesOneCompleteResult),
	MAD_TEST(testZeroRowRefreshPublishesTheProjectedColumns),
	MAD_TEST(testFailedPublicationLeavesTheLastResultUsable),
	MAD_TEST(testFailedFirstRefreshThenRetryPublishes),
	MAD_TEST(testRenderOperationPinsOneGeneration),
	MAD_TEST(testCompositionAttachGuards),
	MAD_TEST(testCompositionAttachUnicodeReservedPathAndAlias),
	MAD_TEST(testCompositionAttachmentLimitAndSQLiteVersion),
	MAD_TEST(testComposedThreeLeafRootJoinsAllThree),
	MAD_TEST(testComposedNestedComposerRunsChildrenBeforeParents),
	MAD_TEST(testComposedSharedChildRunsOnce),
	MAD_TEST(testComposedRootWithMoreThanTenChildrenIsRejected),
	MAD_TEST(testComposedMixedNodeIsRejected),
	MAD_TEST(testComposedCredentialMapPrefersQueryIdentifier),
	MAD_TEST(testComposedRefreshUsesPerSourceCredentialsAndNamesTheFailingSource),
	MAD_TEST(testComposedRefreshClosesAndReopensSqliteSources),
	MAD_TEST(testCompositionEmptyExpressionKeepsKnownType),
	MAD_TEST(testNodeScopedHTMLRendersTheNodeLayout));
