//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADImageExportTests.m
//  Linux/Tests
//
//  The image element end to end on the headless engine: a document is opened
//  (its own process -- opening the London fixture twice in one process
//  conflicts, see MADReportExporterTests), refreshed, given an image element
//  carrying PNG bytes, and exported.  The HTML facsimile must carry the picture
//  as a data-URI PNG; the JSON report must mark the line as an image.
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
#import <MAD/RptqDocumentElementImage.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/RptqStoreContext.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADURLFactory.h>

/// A real 1x1 transparent PNG -- the wire format the image column carries.
static NSData *MADImageExportOnePixelPNG(void) {
	static NSData *data = nil;
	if (data == nil) {
		data = [[NSData alloc] initWithBase64EncodedString:
				@"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
												   options: 0];
	}
	return data;
}

static NSString *MADImageExportRepositoryRoot(void) {
	NSString *directory = [@(__FILE__) stringByDeletingLastPathComponent];
#if defined(_WIN32)
	directory = [directory stringByDeletingLastPathComponent];	// Engine
#endif
	directory = [directory stringByDeletingLastPathComponent];		// Linux / Windows
	return [directory stringByDeletingLastPathComponent];			// the root
}

static NSString *MADImageExportFixturePath(void) {
	return [[MADImageExportRepositoryRoot() stringByAppendingPathComponent: @"CLI/Fixtures"]
			stringByAppendingPathComponent: @"London.portable.mad"];
}

static NSString *MADImageExportSampleDatabasePath(void) {
	return [[MADImageExportRepositoryRoot() stringByAppendingPathComponent:
			 @"MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset"]
			stringByAppendingPathComponent: @"chinook.sqlite3"];
}

// The document's Sqlite3 connection stores a bare filename and MADURLFactory
// resolves it against the app-support directory, so the sample goes there.
static void MADImageExportInstallSampleDatabase(void) {
	NSString *samplePath = MADImageExportSampleDatabasePath();
	if (![[NSFileManager defaultManager] fileExistsAtPath: samplePath]) return;

	NSURL *supportDirectory = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID: [MADApplication groupIdentifier]];
	NSURL *target = [supportDirectory URLByAppendingPathComponent: @"chinook.sqlite3"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager createDirectoryAtURL: supportDirectory withIntermediateDirectories: YES attributes: nil error: NULL];
	[fileManager removeItemAtURL: target error: NULL];
	[fileManager copyItemAtURL: [NSURL fileURLWithPath: samplePath] toURL: target error: NULL];
}

/// The refresh chain the app runs, synchronously, as MADReportExporterTests does.
static BOOL MADImageExportRefresh(MADHeadlessDocument *document) {
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

/// A copied fixture, refreshed, with one PNG-carrying image in its detail section.
/// One document per process: the exporter tests' rule, and the two tests below
/// read the same opened, mutated document.
static MADHeadlessDocument *MADImageExportDocument(void) {
	static MADHeadlessDocument *document = nil;
	static BOOL prepared = NO;
	if (prepared) return document;
	prepared = YES;

	NSString *fixture = MADImageExportFixturePath();
	if (![[NSFileManager defaultManager] fileExistsAtPath: fixture]) return nil;

	MADImageExportInstallSampleDatabase();
	NSString *copy = [NSTemporaryDirectory() stringByAppendingPathComponent:
					  [[NSUUID UUID].UUIDString stringByAppendingPathExtension: @"mad"]];
	[[NSFileManager defaultManager] copyItemAtPath: fixture toPath: copy error: NULL];

	document = [[MADHeadlessDocument documentWithContentsOfURL: [NSURL fileURLWithPath: copy]
														 error: NULL] retain];
	if (document == nil || !MADImageExportRefresh(document)) return nil;

	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqDocumentSection *detail = model.hasDetailSection;
	if (detail == nil) return nil;

	RptqDocumentElementImage *image = (RptqDocumentElementImage *)[context insertObjectForEntity:
																   NSStringFromClass([RptqDocumentElementImage class])
																						 identifier: 0];
	image.type = MADPrintPageElementTypeImage;
	image.image = MADImageExportOnePixelPNG();
	[image setSizeWidth: 96.0f height: 64.0f];
	[detail addDocumentObject: image withDropPoint: CGPointMake(320.0, 6.0) managedObjectContext: context];
	return document;
}

static NSString *MADImageExportOutput(NSString *format) {
	MADHeadlessDocument *document = MADImageExportDocument();
	if (document == nil) return nil;

	Class <MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat: format];
	if (exporterClass == Nil) return nil;

	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSUUID UUID].UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: NULL error: NULL];
	NSURL *url = [NSURL fileURLWithPath: [directory stringByAppendingPathComponent:
										  [[@"image." stringByAppendingString: format] stringByAppendingPathExtension: [exporterClass fileExtension]]]];

	id <MADReportExporting> exporter = [[(Class)exporterClass alloc] init];
	NSError *error = nil;
	if (![exporter exportDocument: document toURL: url options: MADReportExportOptionsNone error: &error]) {
		MAD_PASS(NO, "the %s export failed: %s", [format UTF8String],
				 error != nil ? [[error description] UTF8String] : "no error given");
		return nil;
	}
	return [NSString stringWithContentsOfURL: url encoding: NSUTF8StringEncoding error: NULL];
}

static void testTheHTMLExportCarriesThePictureAsADataURI(void) {
	NSString *html = MADImageExportOutput(@"html");
	MAD_NEED(html != nil, @"the London fixture is missing or did not refresh");

	NSString *expected = [@"data:image/png;base64,"
		stringByAppendingString: [MADImageExportOnePixelPNG() base64EncodedStringWithOptions: 0]];
	MAD_PASS([html rangeOfString: expected].location != NSNotFound,
			 "the image line embeds its PNG bytes as a data URI");
}

static void testTheJSONReportMarksTheImageLine(void) {
	NSString *json = MADImageExportOutput(@"json-report");
	MAD_NEED(json != nil, @"the London fixture is missing or did not refresh");

	MAD_PASS([json rangeOfString: @"\"kind\": \"Image\""].location != NSNotFound,
			 "the line names the image element");
	MAD_PASS([json rangeOfString: @"\"image\": true"].location != NSNotFound,
			 "the line is marked as carrying an image");
}

MAD_TEST_MAIN("MADImageExportTests",
	MAD_TEST(testTheHTMLExportCarriesThePictureAsADataURI),
	MAD_TEST(testTheJSONReportMarksTheImageLine));
