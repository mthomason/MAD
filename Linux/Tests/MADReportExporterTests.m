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
#import <MADFoundation/MADDataColumn.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryPredicate.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqStoreContext.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADFoundation/NSString+Comparison.h>

#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDataTableFast.h>

// __FILE__ is absolute here (CMake hands the compiler an absolute path), so
// Tests -> Linux -> the repository root.
static NSString *MADExporterFixturePath(void) {
	NSString *testFile = [@(__FILE__) stringByDeletingLastPathComponent];
	NSString *repositoryRoot = [[testFile stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
	return [[repositoryRoot stringByAppendingPathComponent: @"CLI/Fixtures"]
			stringByAppendingPathComponent: @"London.portable.mad"];
}

static NSString *MADExporterSampleDatabasePath(void) {
	NSString *testFile = [@(__FILE__) stringByDeletingLastPathComponent];
	NSString *repositoryRoot = [[testFile stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
	return [[repositoryRoot stringByAppendingPathComponent:
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
	MAD_TEST(testRenderOperationPinsOneGeneration));
