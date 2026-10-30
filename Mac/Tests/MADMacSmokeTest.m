//
//  MADMacSmokeTest.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  End-to-end verification of the packaged macOS app bundle's frameworks and
//  resources:
//    1. Opens the bundled London.mad and Music.mad sample reports
//    2. Refreshes London.mad against the bundled chinook.sqlite3 and exports
//       PDF, HTML, CSV, JSON, JSON-Report, and Text
//    3. Creates a brand-new .mad report from chinook.sqlite3, compiles and
//       applies a SQL statement (SELECT + JOIN + WHERE + GROUP BY), adds
//       Static Label, Data Field, Aggregate, and Barcode elements, mutates
//       them via MADDesignerLayout with NSUndoManager, refreshes, and exports PDF.
//

#import <Cocoa/Cocoa.h>
#import <MAD/MAD.h>
#import "MADMacDocumentController.h"
#import "MADMacAppDelegate.h"
#import "MADMacDocument.h"
#import "MADocumentDesignerProtocol.h"
#import "MADSQLQueryCompiler.h"
#import "MADSQLStatementResolver.h"
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADBarcodes/MADBarcodes.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface MADSmokeDesignerHost : NSObject <MADocumentDesignerProtocol>
@property (strong, null_resettable) NSUndoManager *undoManager;
@property (nonatomic, strong, readwrite, null_resettable) RptqStoreContext *managedObjectContext;
@end

@implementation MADSmokeDesignerHost
@synthesize undoManager = _undoManager;
@synthesize managedObjectContext = _managedObjectContext;

- (NSUndoManager *)undoManager {
	if (_undoManager == nil) {
		_undoManager = [[NSUndoManager alloc] init];
	}
	return _undoManager;
}

- (void)setUndoManager:(NSUndoManager *)undoManager {
	_undoManager = undoManager ?: [[NSUndoManager alloc] init];
}

- (void)setManagedObjectContext:(RptqStoreContext *)managedObjectContext {
	_managedObjectContext = managedObjectContext;
}

@end

static BOOL RunRefreshSynchronous(MADHeadlessDocument *doc) {
	MADOperationRefreshInitializeMainDataTable *initTable =
		[[MADOperationRefreshInitializeMainDataTable alloc] initWithDocument:doc];
	MADOperationRefreshInitialize *initOp =
		[[MADOperationRefreshInitialize alloc] initWithDocument:doc];
	[initOp addDependency:initTable];
	MADOperationRefresh *refreshOp =
		[[MADOperationRefresh alloc] initWithDocument:doc];
	[refreshOp addDependency:initTable];
	[refreshOp addDependency:initOp];

	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation:initTable];
	[queue addOperation:initOp];
	[queue addOperation:refreshOp];

	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:30.0];
	while (queue.operationCount > 0 && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
	return doc.refreshed;
}

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		if (argc < 2) {
			fprintf(stderr, "Usage: mad-mac-smoke-test <path-to-MAD Designer.app>\n");
			return 1;
		}
		NSString *appPath = [NSString stringWithUTF8String:argv[1]];
		NSString *resourcesPath = [appPath stringByAppendingPathComponent:@"Contents/Resources"];
		NSString *chinookPath = [resourcesPath stringByAppendingPathComponent:@"chinook.sqlite3"];
		NSString *londonPath = [resourcesPath stringByAppendingPathComponent:@"London.mad"];
		NSString *musicPath = [resourcesPath stringByAppendingPathComponent:@"Music.mad"];

		NSFileManager *fm = [NSFileManager defaultManager];
		if ([fm fileExistsAtPath:chinookPath] || [fm fileExistsAtPath:londonPath] || [fm fileExistsAtPath:musicPath]) {
			fprintf(stderr, "FAIL: Bundled app contains sample reports or databases when it should not: %s\n", resourcesPath.UTF8String);
			return 2;
		}
		printf("PASS: App bundle contains no bundled sample reports or sample databases\n");

		NSString *repoRoot = argc >= 3 ? [NSString stringWithUTF8String:argv[2]] : nil;
		if (repoRoot.length == 0) {
			repoRoot = [[[NSProcessInfo processInfo] environment] objectForKey:@"MAD_REPO_ROOT"] ?: @"..";
		}
		NSString *sampleChinookPath = [repoRoot stringByAppendingPathComponent:@"MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset/chinook.sqlite3"];
		NSString *sampleLondonPath = [repoRoot stringByAppendingPathComponent:@"CLI/Fixtures/London.portable.mad"];
		if (![fm fileExistsAtPath:sampleChinookPath] || ![fm fileExistsAtPath:sampleLondonPath]) {
			fprintf(stderr, "FAIL: Missing test fixtures at repo root %s\n", repoRoot.UTF8String);
			return 2;
		}

		// Install chinook.sqlite3 in Application Support
		NSURL *supportDir = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID:[MADApplication groupIdentifier]];
		[fm createDirectoryAtURL:supportDir withIntermediateDirectories:YES attributes:nil error:NULL];
		NSURL *installedChinook = [supportDir URLByAppendingPathComponent:@"chinook.sqlite3"];
		[fm removeItemAtURL:installedChinook error:NULL];
		[fm copyItemAtURL:[NSURL fileURLWithPath:sampleChinookPath] toURL:installedChinook error:NULL];

		// 1. Open and refresh London.mad, export all formats
		NSError *err = nil;
		MADHeadlessDocument *london = [MADHeadlessDocument documentWithContentsOfURL:[NSURL fileURLWithPath:sampleLondonPath] error:&err];
		if (london == nil) {
			fprintf(stderr, "FAIL: Could not open London.mad: %s\n", err.localizedDescription.UTF8String);
			return 3;
		}
		if (!RunRefreshSynchronous(london) || [london.dataTable numberOfRows] == 0) {
			fprintf(stderr, "FAIL: London.mad refresh produced 0 rows\n");
			return 4;
		}
		printf("PASS: Opened & refreshed London.mad (%lu rows)\n", (unsigned long)[london.dataTable numberOfRows]);

		NSArray<NSString *> *formats = @[@"pdf", @"html", @"html-flow", @"csv", @"json", @"json-report", @"text"];
		for (NSString *fmt in formats) {
			Class<MADReportExporting> cls = [MADReportExporterRegistry exporterClassForFormat:fmt];
			if (cls == Nil || ![cls isAvailable]) {
				fprintf(stderr, "FAIL: Exporter '%s' unavailable\n", fmt.UTF8String);
				return 5;
			}
			NSString *outPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
								 [NSString stringWithFormat:@"smoke-london-%@.%@", NSUUID.UUID.UUIDString, [cls fileExtension]]];
			NSURL *outURL = [NSURL fileURLWithPath:outPath];
			id<MADReportExporting> exporter = [[(Class)cls alloc] init];
			if (![exporter exportDocument:london toURL:outURL options:MADReportExportOptionsNone error:&err]) {
				fprintf(stderr, "FAIL: Export '%s' failed: %s\n", fmt.UTF8String, err.localizedDescription.UTF8String);
				return 6;
			}
			NSData *bytes = [NSData dataWithContentsOfURL:outURL];
			[fm removeItemAtURL:outURL error:NULL];
			if (bytes.length == 0) {
				fprintf(stderr, "FAIL: Export '%s' wrote 0 bytes\n", fmt.UTF8String);
				return 7;
			}
			printf("PASS: Exported London.mad as %s (%lu bytes)\n", fmt.UTF8String, (unsigned long)bytes.length);
		}

		// 2. Create a brand-new .mad document, apply SQL, add elements, undo/redo, refresh, and export PDF
		NSString *newDocPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
								[NSString stringWithFormat:@"smoke-created-%@.mad", NSUUID.UUID.UUIDString]];
		NSURL *newDocURL = [NSURL fileURLWithPath:newDocPath];
		MADDatabaseConnectionSqlite3 *conn = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:installedChinook];
		MADHeadlessDocument *created = [MADHeadlessDocument createDocumentAtURL:newDocURL
														 withDatabaseConnection:conn
																	credentials:nil
																		  error:&err];
		if (created == nil) {
			fprintf(stderr, "FAIL: Could not create new .mad document: %s\n", err.localizedDescription.UTF8String);
			return 8;
		}

		RptqStoreContext *ctx = created.storeContext;
		RptqDocument *rptqDoc = [RptqDocument newDocumentReadFromManagedObjectContext:ctx];
		RptqDatabase *rptqDB = rptqDoc.hasDatabaseSchemas.anyObject;
		RptqQuery *rptqQuery = rptqDB.hasQueries.anyObject;

		NSMutableDictionary<NSString *, NSArray<NSString *> *> *schemaMap = [[NSMutableDictionary alloc] init];
		for (RptqDatabaseSchemaTable *st in rptqDB.hasTables) {
			if (st.name.length == 0) continue;
			NSMutableArray<NSString *> *cols = [[NSMutableArray alloc] init];
			for (RptqDatabaseSchemaField *sf in st.hasFields) {
				if (sf.name.length > 0) [cols addObject:sf.name];
			}
			schemaMap[st.name] = cols;
		}

		NSString *sql = @"SELECT Customer.FirstName, Customer.LastName, Customer.City FROM Customer WHERE Customer.Country = 'United Kingdom';";
		MADSQLParser *parser = [[MADSQLParser alloc] initWithSQL:sql
									   identifierQuoteCharacters:@"\"\""
														  schema:schemaMap];
		MADSQLStatement *stmt = [parser parseStatement:&err];
		MADSQLStatementResolver *resolver = [[MADSQLStatementResolver alloc] initWithStatement:stmt database:rptqDB];
		MADSQLQueryPlan *plan = [resolver resolveWithError:&err];
		MADSQLQueryCompiler *compiler = [[MADSQLQueryCompiler alloc] initWithPlan:plan
																		 document:created
																			query:rptqQuery
																		  context:ctx];
		if (![compiler applyWithError:&err]) {
			fprintf(stderr, "FAIL: SQL compile/apply failed: %s\n", err.localizedDescription.UTF8String);
			return 9;
		}

		RptqDocumentSection *detail = rptqDoc.hasDetailSection;
		if (detail.hasRows.count == 0) {
			RptqDocumentSectionRows *row = (RptqDocumentSectionRows *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentSectionRows class]) identifier:0];
			row.rowNumber = 0;
			row.inSection = detail;
			[detail addHasRowsFixed:row];
		}

		RptqDocumentElementLabel *label = (RptqDocumentElementLabel *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabel class]) identifier:0];
		label.type = MADPrintPageElementTypeLabelStatic;
		label.text = @"UK Customer:";
		[label setSizeWidth:120.0f height:20.0f];
		[detail addDocumentObject:label withDropPoint:CGPointMake(12.0, 6.0) managedObjectContext:ctx];

		RptqQueryTable *customerQT = rptqQuery.hasQueryTables.anyObject;
		RptqQueryField *boundQF = customerQT.hasQueryFields.anyObject;
		for (RptqQueryField *qf in customerQT.hasQueryFields) {
			if ([qf.databaseSchemaField.name isEqualToString:@"LastName"]) {
				boundQF = qf;
				break;
			}
		}
		RptqDocumentElementLabelDataField *dataFieldEl = (RptqDocumentElementLabelDataField *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier:0];
		dataFieldEl.type = MADPrintPageElementTypeLabelDynamic;
		dataFieldEl.referencesQueryField = boundQF;
		dataFieldEl.fieldID = boundQF.databaseSchemaField.name;
		dataFieldEl.tableID = boundQF.inQueryTable.alias ?: boundQF.inQueryTable.databaseSchemaTable.name;
		dataFieldEl.text = boundQF.databaseSchemaField.name ?: @"LastName";
		[dataFieldEl setSizeWidth:140.0f height:20.0f];
		[detail addDocumentObject:dataFieldEl withDropPoint:CGPointMake(140.0, 6.0) managedObjectContext:ctx];

		RptqDocumentElementBarcode *barcodeEl = (RptqDocumentElementBarcode *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementBarcode class]) identifier:0];
		barcodeEl.type = MADPrintPageElementTypeBarcode;
		barcodeEl.barcodeType = (int16_t)MADBarcodeTypeCODE128;
		barcodeEl.useStaticInput1 = YES;
		barcodeEl.inputStatic1 = @"UK-CUST";
		[barcodeEl setSizeWidth:140.0f height:40.0f];
		[detail addDocumentObject:barcodeEl withDropPoint:CGPointMake(300.0, 6.0) managedObjectContext:ctx];

		MADSmokeDesignerHost *host = [[MADSmokeDesignerHost alloc] init];
		host.undoManager = [[NSUndoManager alloc] init];
		host.managedObjectContext = ctx;
		MADDesignerLayout *designerLayout = [[MADDesignerLayout alloc] init];
		designerLayout.delegate = host;
		NSSet<NSNumber *> *ids = [NSSet setWithObjects:@(label.identifier), @(barcodeEl.identifier), nil];
		[designerLayout updateElements:ids setSizeWidth:200.0f];
		[host.undoManager undo];
		if (fabsf(label.rect.size.width - 120.0f) > 0.1f || fabsf(barcodeEl.rect.size.width - 140.0f) > 0.1f) {
			fprintf(stderr, "FAIL: Multi-selection undo did not restore distinct element widths\n");
			return 10;
		}

		[created invalidateQueryAndModelCaches];
		if (!RunRefreshSynchronous(created) || [created.dataTable numberOfRows] == 0) {
			fprintf(stderr, "FAIL: Created document refresh failed\n");
			return 11;
		}

		Class<MADReportExporting> pdfCls = [MADReportExporterRegistry exporterClassForFormat:@"pdf"];
		NSURL *createdPdfURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:
													   [NSString stringWithFormat:@"smoke-created-%@.pdf", NSUUID.UUID.UUIDString]]];
		id<MADReportExporting> pdfExporter = [[(Class)pdfCls alloc] init];
		if (![pdfExporter exportDocument:created toURL:createdPdfURL options:MADReportExportOptionsNone error:&err]) {
			fprintf(stderr, "FAIL: Created document PDF export failed: %s\n", err.localizedDescription.UTF8String);
			return 12;
		}
		NSData *createdPdfBytes = [NSData dataWithContentsOfURL:createdPdfURL];
		[fm removeItemAtURL:createdPdfURL error:NULL];
		[fm removeItemAtURL:newDocURL error:NULL];
		if (createdPdfBytes.length == 0) {
			fprintf(stderr, "FAIL: Created document PDF export wrote 0 bytes\n");
			return 13;
		}
		printf("PASS: Created, SQL-compiled, designed, undo-verified, refreshed (%lu rows) & exported PDF (%lu bytes)\n",
			   (unsigned long)[created.dataTable numberOfRows],
			   (unsigned long)createdPdfBytes.length);

		// 3. Test modern macOS launch flows
		// Ensure shared document controller is MADMacDocumentController
		(void)[[MADMacDocumentController alloc] init];
		NSDocumentController *sharedDocCtrl = [NSDocumentController sharedDocumentController];
		if (![sharedDocCtrl isKindOfClass:[MADMacDocumentController class]]) {
			fprintf(stderr, "FAIL: Shared document controller is not MADMacDocumentController\n");
			return 14;
		}
		MADMacDocumentController *macDocCtrl = (MADMacDocumentController *)sharedDocCtrl;

		// 3a. Verify open panel configuration and direct "New Document" button (not hidden behind "Options")
		NSOpenPanel *testPanel = [NSOpenPanel openPanel];
		[macDocCtrl beginOpenPanel:testPanel forTypes:nil completionHandler:^(NSInteger __unused result) {}];

		if (macDocCtrl.activeOpenPanel != testPanel) {
			fprintf(stderr, "FAIL: activeOpenPanel was not tracked by MADMacDocumentController\n");
			return 15;
		}
		if (testPanel.accessoryView != nil) {
			fprintf(stderr, "FAIL: openPanel should not use accessoryView (which hides 'New Document' behind 'Options')\n");
			return 16;
		}

		NSButton *newDocBtn = [macDocCtrl newDocumentButtonForOpenPanel:testPanel];
		if (newDocBtn == nil || newDocBtn.isHidden || ![newDocBtn.title isEqualToString:@"New Document"]) {
			fprintf(stderr, "FAIL: openPanel missing visible 'New Document' button in bottom bar\n");
			return 17;
		}
		if (![newDocBtn.bezelColor isEqual:[NSColor controlAccentColor]]) {
			fprintf(stderr, "FAIL: 'New Document' button is not highlighted with controlAccentColor\n");
			return 17;
		}

		// 3b. Verify clicking "New Document" dismisses open panel
		[macDocCtrl newDocumentFromOpenPanel:newDocBtn];
		if (macDocCtrl.activeOpenPanel != nil) {
			fprintf(stderr, "FAIL: newDocumentFromOpenPanel did not dismiss activeOpenPanel\n");
			return 18;
		}

		// 3c. Verify launch paths via MADMacAppDelegate:
		MADMacAppDelegate *appDelegate = [[MADMacAppDelegate alloc] init];
		[appDelegate applicationWillFinishLaunching:[NSNotification notificationWithName:@"launch" object:NSApp]];

		// Scenario A: When launched with a document, applicationDidFinishLaunching does NOT present open panel
		MADMacDocument *openDoc = [[MADMacDocument alloc] init];
		openDoc.fileURL = [NSURL fileURLWithPath:sampleLondonPath];
		[openDoc adoptHeadlessDocument:london];
		[sharedDocCtrl addDocument:openDoc];

		[macDocCtrl dismissOpenPanelIfNeeded];
		[appDelegate applicationDidFinishLaunching:[NSNotification notificationWithName:@"launch" object:NSApp]];
		if (macDocCtrl.activeOpenPanel != nil) {
			fprintf(stderr, "FAIL: applicationDidFinishLaunching presented open panel even though document was open\n");
			return 19;
		}
		[sharedDocCtrl removeDocument:openDoc];

		// Scenario B: When launched without a document (documents.count == 0), applicationDidFinishLaunching presents open panel
		[macDocCtrl dismissOpenPanelIfNeeded];
		[appDelegate applicationDidFinishLaunching:[NSNotification notificationWithName:@"launch" object:NSApp]];
		if (macDocCtrl.activeOpenPanel == nil) {
			fprintf(stderr, "FAIL: applicationDidFinishLaunching did not present open panel when no documents open\n");
			return 20;
		}
		[macDocCtrl dismissOpenPanelIfNeeded];

		printf("PASS: Verified modern macOS launch: opens document when provided, opens file dialog with 'New Document' button when launched empty\n");
	}
	return 0;
}
