//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporterTests.m
//  Linux/Tests
//
//  The export seam end to end (MAD_CLI.md §5.3, MAD_LINUX.md §9 Phase E): the
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

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADURLFactory.h>

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

// The render half is in this build now (MAD_LINUX.md §9 Phase E): the formats that
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

// PDF is the one format that is not: it is Core Graphics drawn by the Apple-only page
// renderer.  It registers anyway -- the format list names it on both platforms -- and
// says why (MAD_LINUX.md §10.2: the Linux writer is the next step).
static void testThePDFFormatSaysWhyItCannotRun(void) {
	Class <MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat: @"pdf"];
	MAD_PASS(exporterClass != Nil, "pdf is registered here, not hidden from the format list");
	MAD_PASS(![exporterClass isAvailable], "this build cannot produce it");
	MAD_PASS([exporterClass unavailableReason].length > 0, "it says why");
	MAD_NEED([exporterClass unavailableReason] != nil, @"the reason string is missing");
	MAD_PASS([exporterClass requiresOutputPath], "pdf needs --out, on every platform");
	MAD_PASS_EQUAL([exporterClass fileExtension], @"pdf", "and it is a .pdf");

	if (!MADExporterFixtureIsThere()) return;
	MADHeadlessDocument *document = MADExporterDocument();
	MAD_NEED(document != nil, @"could not open the London fixture");

	NSURL *url = MADExporterOutputURL(@"london.pdf");
	id <MADReportExporting> exporter = [[(Class)exporterClass alloc] init];
	NSError *error = nil;
	MAD_PASS(![exporter exportDocument: document toURL: url options: MADReportExportOptionsNone error: &error],
			 "an export that cannot run fails rather than writing something");
	MAD_PASS(error != nil, "and it says why");
	MAD_PASS(![[NSFileManager defaultManager] fileExistsAtPath: url.path], "nothing was written");
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
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0x1E679E6AD5E1A6C3ULL),
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
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0xC9FCD14079767021ULL),
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
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0x7E476E9FB57AF603ULL),
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
	// machine's, so the same document writes the same report here (BUGS.md).
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0xA72F927165709893ULL),
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
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0x2972A86316D77281ULL),
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
	MAD_PASS_EQUAL(@(MADExporterChecksum(data)), @(0xE6F5C361C537C3A7ULL),
				   "the reflowable file's bytes are the ones the Mac writes");
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

MAD_TEST_MAIN("MADReportExporterTests",
	MAD_TEST(testTheFormatsAreRegistered),
	MAD_TEST(testTheRenderSideFormatsRegisterHere),
	MAD_TEST(testThePDFFormatSaysWhyItCannotRun),
	MAD_TEST(testNumbersAreSpelledInOneRoundTripForm),
	MAD_TEST(testDatesAreISO8601InUTC),
	MAD_TEST(testTheTextExportIsATableOfTheRows),
	MAD_TEST(testTheCSVExportIsTheRowsAndTheColumnKeys),
	MAD_TEST(testTheJSONExportIsTheSchemaAndTheRows),
	MAD_TEST(testTheJSONReportAddsTheRenderedReport),
	MAD_TEST(testTheHTMExportIsAFacsimileOfThePages),
	MAD_TEST(testTheHTMLFlowExportIsTheSectionsAndRows));
