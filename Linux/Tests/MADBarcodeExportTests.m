//
//  MADBarcodeExportTests.m
//  Linux/Tests
//
//  The barcode element end to end on the headless engine: a document is opened
//  (its own process -- opening the London fixture twice in one process conflicts,
//  see MADReportExporterTests), refreshed, given a barcode element with a static
//  input, and exported.  The HTML facsimile must carry the symbol as a data-URI
//  PNG with the input as its alt text; the JSON report must carry the line's
//  kind and text.
//

#import "MADTestSupport.h"

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/MADHeadlessDocument.h>
#import <MAD/MADOperationRefresh.h>
#import <MAD/MADOperationRefreshInitialize.h>
#import <MAD/MADOperationRefreshInitalizeMainDataTable.h>
#import <MAD/MADReportExporterHTML.h>
#import <MAD/MADReportExporterJSONReport.h>
#import <MAD/MADReportExporterRegistry.h>
#import <MAD/MADReportExporting.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementBarcode.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/RptqStoreContext.h>

#import <MADBarcodes/MADBarcodeType.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADURLFactory.h>

static NSString *MADBarcodeExportRepositoryRoot(void) {
	NSString *directory = [@(__FILE__) stringByDeletingLastPathComponent];
#if defined(_WIN32)
	directory = [directory stringByDeletingLastPathComponent];	// Engine
#endif
	directory = [directory stringByDeletingLastPathComponent];		// Linux / Windows
	return [directory stringByDeletingLastPathComponent];			// the root
}

static NSString *MADBarcodeExportFixturePath(void) {
	return [[MADBarcodeExportRepositoryRoot() stringByAppendingPathComponent: @"CLI/Fixtures"]
			stringByAppendingPathComponent: @"London.portable.mad"];
}

static NSString *MADBarcodeExportSampleDatabasePath(void) {
	return [[MADBarcodeExportRepositoryRoot() stringByAppendingPathComponent:
			 @"MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset"]
			stringByAppendingPathComponent: @"chinook.sqlite3"];
}

// The document's Sqlite3 connection stores a bare filename and MADURLFactory
// resolves it against the app-support directory, so the sample goes there.
static void MADBarcodeExportInstallSampleDatabase(void) {
	NSString *samplePath = MADBarcodeExportSampleDatabasePath();
	if (![[NSFileManager defaultManager] fileExistsAtPath: samplePath]) return;

	NSURL *supportDirectory = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID: [MADApplication groupIdentifier]];
	NSURL *target = [supportDirectory URLByAppendingPathComponent: @"chinook.sqlite3"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager createDirectoryAtURL: supportDirectory withIntermediateDirectories: YES attributes: nil error: NULL];
	[fileManager removeItemAtURL: target error: NULL];
	[fileManager copyItemAtURL: [NSURL fileURLWithPath: samplePath] toURL: target error: NULL];
}

/// The refresh chain the app runs, synchronously, as MADReportExporterTests does.
static BOOL MADBarcodeExportRefresh(MADHeadlessDocument *document) {
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
	return queue.operationCount == 0 && refresh.errors.count == 0;
}

/// A copied fixture, refreshed, with one static-input barcode in its detail section.
/// One document per process: the exporter tests' rule, and the two tests below
/// read the same opened, mutated document.
static MADHeadlessDocument *MADBarcodeExportDocument(void) {
	static MADHeadlessDocument *document = nil;
	static BOOL prepared = NO;
	if (prepared) return document;
	prepared = YES;

	NSString *fixture = MADBarcodeExportFixturePath();
	if (![[NSFileManager defaultManager] fileExistsAtPath: fixture]) return nil;

	MADBarcodeExportInstallSampleDatabase();
	NSString *copy = [NSTemporaryDirectory() stringByAppendingPathComponent:
					  [[NSUUID UUID].UUIDString stringByAppendingPathExtension: @"mad"]];
	[[NSFileManager defaultManager] copyItemAtPath: fixture toPath: copy error: NULL];

	document = [[MADHeadlessDocument documentWithContentsOfURL: [NSURL fileURLWithPath: copy]
														 error: NULL] retain];
	if (document == nil || !MADBarcodeExportRefresh(document)) return nil;

	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqDocumentSection *detail = model.hasDetailSection;
	if (detail == nil) return nil;

	RptqDocumentElementBarcode *barcode = (RptqDocumentElementBarcode *)[context insertObjectForEntity:
																		 NSStringFromClass([RptqDocumentElementBarcode class])
																		 identifier: 0];
	barcode.type = MADPrintPageElementTypeBarcode;
	barcode.barcodeType = (int16_t)MADBarcodeTypeCODE128;
	barcode.humanReadable = YES;
	barcode.useStaticInput1 = YES;
	barcode.inputStatic1 = @"UK-CUST";
	barcode.barcodeHeight = 40;
	[barcode setSizeWidth: 160.0f height: 48.0f];
	[detail addDocumentObject: barcode withDropPoint: CGPointMake(300.0, 6.0) managedObjectContext: context];
	return document;
}

static NSString *MADBarcodeExportOutput(NSString *format) {
	MADHeadlessDocument *document = MADBarcodeExportDocument();
	if (document == nil) return nil;

	Class <MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat: format];
	if (exporterClass == Nil) return nil;

	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSUUID UUID].UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *url = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent:
										  [[@"barcode." stringByAppendingString: format] stringByAppendingPathExtension: [exporterClass fileExtension]]]];

	id <MADReportExporting> exporter = [[(Class)exporterClass alloc] init];
	NSError *error = nil;
	if (![exporter exportDocument: document toURL: url options: MADReportExportOptionsNone error: &error]) {
		MAD_PASS(NO, "the %s export failed: %s", [format UTF8String],
				 error != nil ? [[error description] UTF8String] : "no error given");
		return nil;
	}
	return [NSString stringWithContentsOfURL: url encoding: NSUTF8StringEncoding error: NULL];
}

static void testTheHTMLExportCarriesTheSymbolAsADataURI(void) {
	NSString *html = MADBarcodeExportOutput(@"html");
	MAD_NEED(html != nil, @"the London fixture is missing or did not refresh");

	MAD_PASS([html rangeOfString: @"data:image/png;base64,"].location != NSNotFound,
			 "the barcode line embeds a PNG data URI");
	MAD_PASS([html rangeOfString: @"alt=\"UK-CUST\""].location != NSNotFound,
			 "the image carries the input as its alt text");
}

static void testTheJSONReportCarriesTheBarcodeLine(void) {
	NSString *json = MADBarcodeExportOutput(@"json-report");
	MAD_NEED(json != nil, @"the London fixture is missing or did not refresh");

	MAD_PASS([json rangeOfString: @"\"kind\": \"Barcode\""].location != NSNotFound,
			 "the line names the barcode element");
	MAD_PASS([json rangeOfString: @"\"text\": \"UK-CUST\""].location != NSNotFound,
			 "the line carries the static input");
}

MAD_TEST_MAIN("MADBarcodeExportTests",
	MAD_TEST(testTheHTMLExportCarriesTheSymbolAsADataURI),
	MAD_TEST(testTheJSONReportCarriesTheBarcodeLine));
