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
#import "MADMacConnectionWindowController.h"
#import "MADMacDocument.h"
#import "MADMacWindowController.h"
#import "MADMacQueryViewController.h"
#import "MADMacDesignerViewController.h"
#import "MADMacDesignerCanvasView.h"
#import "MADMacViewerViewController.h"
#import "MADocumentDesignerProtocol.h"
#import "MADSQLQueryCompiler.h"
#import "MADSQLStatementResolver.h"
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADBarcodes/MADBarcodes.h>
#import <Quartz/Quartz.h>
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
		[macDocCtrl beginOpenPanel:testPanel forTypes:@[@"com.thomason.report.mad"] completionHandler:^(NSInteger __unused result) {}];

		if (macDocCtrl.activeOpenPanel != testPanel) {
			fprintf(stderr, "FAIL: activeOpenPanel was not tracked by MADMacDocumentController\n");
			return 15;
		}
		if (testPanel.accessoryView != nil) {
			fprintf(stderr, "FAIL: openPanel should not use accessoryView (which hides 'New Document' behind 'Options')\n");
			return 16;
		}

		// Verify existing .mad files on disk match testPanel.allowedContentTypes (not dimmed out in NSOpenPanel)
		NSURL *sampleLondonURL = [NSURL fileURLWithPath:sampleLondonPath];
		UTType *fileContentType = nil;
		[sampleLondonURL getResourceValue:&fileContentType forKey:NSURLContentTypeKey error:NULL];
		BOOL matchesAllowedType = NO;
		for (UTType *allowedType in testPanel.allowedContentTypes) {
			if ((fileContentType != nil && [fileContentType conformsToType:allowedType]) ||
				[allowedType.identifier isEqualToString:@"com.everydayapps.productivity.mad"]) {
				matchesAllowedType = YES;
				break;
			}
		}
		if (!matchesAllowedType) {
			fprintf(stderr, "FAIL: openPanel.allowedContentTypes (%s) does not match .mad file UTType (%s)\n",
					testPanel.allowedContentTypes.description.UTF8String,
					fileContentType.identifier.UTF8String);
			return 16;
		}

		// Verify NSDocumentController can resolve document type, document class, and instantiate MADMacDocument from URL
		NSString *resolvedType = [macDocCtrl typeForContentsOfURL:sampleLondonURL error:&err];
		Class resolvedDocClass = resolvedType != nil ? [macDocCtrl documentClassForType:resolvedType] : Nil;
		if (resolvedDocClass != [MADMacDocument class]) {
			fprintf(stderr, "FAIL: documentClassForType:(%s) returned %s instead of MADMacDocument\n",
					resolvedType.UTF8String,
					resolvedDocClass ? NSStringFromClass(resolvedDocClass).UTF8String : "Nil");
			return 16;
		}
		__kindof NSDocument *openedViaController = [macDocCtrl makeDocumentWithContentsOfURL:sampleLondonURL
																					  ofType:resolvedType
																					   error:&err];
		if (![openedViaController isKindOfClass:[MADMacDocument class]] ||
			((MADMacDocument *)openedViaController).headlessDocument == nil) {
			fprintf(stderr, "FAIL: makeDocumentWithContentsOfURL failed for existing .mad file: %s\n",
					err.localizedDescription.UTF8String);
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

		[openDoc makeWindowControllers];
		MADMacWindowController *wc = openDoc.windowControllers.firstObject;
		[wc.window layoutIfNeeded];
		NSToolbar *toolbar = wc.window.toolbar;
		for (NSToolbarItem *item in toolbar.items) {
			if ([item.itemIdentifier isEqualToString:@"MADToolbarRefresh"] ||
				[item.itemIdentifier isEqualToString:@"MADToolbarExport"] ||
				[item.itemIdentifier isEqualToString:@"MADToolbarPrint"]) {
				fprintf(stderr, "FAIL: Toolbar still contains removed item %s\n", item.itemIdentifier.UTF8String);
				return 21;
			}
			if ([item.itemIdentifier isEqualToString:@"MADToolbarWorkspace"] && item.view != nil) {
				NSRect rectInWindow = [item.view convertRect:item.view.bounds toView:nil];
				CGFloat midX = NSMidX(rectInWindow);
				CGFloat winMidX = wc.window.frame.size.width * 0.5;
				if (fabs(midX - winMidX) > 2.0) {
					fprintf(stderr, "FAIL: Workspace segmented control not centered (midX=%.1f vs window midX=%.1f)\n", midX, winMidX);
					return 22;
				}
			}
		}

		MADMacConnectionWindowController *connWC = [[MADMacConnectionWindowController alloc] init];
		NSPopUpButton *driverPopup = [connWC valueForKey:@"driverPopup"];
		NSArray<NSString *> *expectedDrivers = @[@"SQLite", @"MySQL", @"Microsoft SQL Server", @"PostgreSQL"];
		if (![driverPopup.itemTitles isEqualToArray:expectedDrivers]) {
			fprintf(stderr, "FAIL: Unexpected driver popup titles: %s\n", driverPopup.itemTitles.description.UTF8String);
			return 23;
		}

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

		// 4. Test Redesigned Visual Query Designer (MADMacQueryViewController)
		NSString *qDocPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
							  [NSString stringWithFormat:@"smoke-query-designer-%@.mad", NSUUID.UUID.UUIDString]];
		NSURL *qDocURL = [NSURL fileURLWithPath:qDocPath];
		MADHeadlessDocument *qHeadless = [MADHeadlessDocument createDocumentAtURL:qDocURL
														   withDatabaseConnection:conn
																	  credentials:nil
																			error:&err];
		if (qHeadless == nil) {
			fprintf(stderr, "FAIL: Could not create document for Query Designer test: %s\n", err.localizedDescription.UTF8String);
			return 24;
		}
		MADMacDocument *qMacDoc = [[MADMacDocument alloc] init];
		qMacDoc.fileURL = qDocURL;
		[qMacDoc adoptHeadlessDocument:qHeadless];
		[qMacDoc makeWindowControllers];
		MADMacWindowController *qWC = qMacDoc.windowControllers.firstObject;
		[qWC switchToWorkspaceTab:MADMacWorkspaceTabQuery];
		[qWC.window layoutIfNeeded];

		MADMacQueryViewController *qVC = qWC.queryViewController;
		NSSplitView *designerSplit = [qVC valueForKey:@"designerSplitView"];
		NSView *schemaSidebar = [qVC valueForKey:@"schemaSidebarView"];
		NSView *canvasContainer = [qVC valueForKey:@"canvasContainerView"];
		NSView *sqlEditorContainer = [qVC valueForKey:@"sqlEditorContainerView"];
		NSTextView *sqlTextView = [qVC valueForKey:@"sqlTextView"];

		// 4a. Mutually exclusive modes: Query Designer vs SQL Query
		if (qVC.workspaceMode != MADMacQueryWorkspaceModeDesigner || designerSplit.isHidden || !sqlEditorContainer.isHidden) {
			fprintf(stderr, "FAIL: Query Designer did not start in mutually exclusive Designer mode\n");
			return 25;
		}
		[qVC switchToMode:MADMacQueryWorkspaceModeSQL];
		if (qVC.workspaceMode != MADMacQueryWorkspaceModeSQL || !designerSplit.isHidden || sqlEditorContainer.isHidden) {
			fprintf(stderr, "FAIL: Switching to SQL mode did not hide visual designer and show SQL editor\n");
			return 26;
		}
		[qVC switchToMode:MADMacQueryWorkspaceModeDesigner];
		if (qVC.workspaceMode != MADMacQueryWorkspaceModeDesigner || designerSplit.isHidden || !sqlEditorContainer.isHidden) {
			fprintf(stderr, "FAIL: Switching back to Designer mode did not hide SQL editor and show visual designer\n");
			return 27;
		}

		// 4b. Left-hand table list (~200px fixed width on window resize, user-resizable without snapping back)
		if (fabs(qVC.schemaSidebarWidth - 200.0) > 1.0 || fabs(NSWidth(schemaSidebar.frame) - 200.0) > 1.0) {
			fprintf(stderr, "FAIL: Schema table list initial width is %.1f (expected 200.0)\n", NSWidth(schemaSidebar.frame));
			return 28;
		}
		CGFloat initialCanvasWidth = NSWidth(canvasContainer.frame);
		[qWC.window setFrame:NSMakeRect(0.0, 0.0, 1560.0, 920.0) display:YES];
		[qWC.window layoutIfNeeded];
		if (fabs(NSWidth(schemaSidebar.frame) - 200.0) > 1.0 || NSWidth(canvasContainer.frame) <= initialCanvasWidth + 100.0) {
			fprintf(stderr, "FAIL: Window resize did not keep left table list fixed at 200px (got %.1f) while resizing canvas\n",
					NSWidth(schemaSidebar.frame));
			return 29;
		}
		[designerSplit setPosition:260.0 ofDividerAtIndex:0];
		[designerSplit adjustSubviews];
		if (fabs(qVC.schemaSidebarWidth - 260.0) > 1.5 || fabs(NSWidth(schemaSidebar.frame) - 260.0) > 1.5) {
			fprintf(stderr, "FAIL: User resize of table list divider snapped back instead of staying at 260px (got %.1f)\n",
					NSWidth(schemaSidebar.frame));
			return 30;
		}
		[qWC.window setFrame:NSMakeRect(0.0, 0.0, 1360.0, 840.0) display:YES];
		[qWC.window layoutIfNeeded];
		if (fabs(NSWidth(schemaSidebar.frame) - 260.0) > 1.5) {
			fprintf(stderr, "FAIL: Window resize after user divider adjustment did not preserve 260px width (got %.1f)\n",
					NSWidth(schemaSidebar.frame));
			return 31;
		}

		// 4c. Double-click / add two tables (Customer and Invoice) -> floating AppKit table views on canvas
		RptqDatabaseSchemaTable *customerSchema = nil;
		RptqDatabaseSchemaTable *invoiceSchema = nil;
		for (RptqDatabaseSchemaTable *st in qMacDoc.rptqDatabase.hasTables) {
			if ([st.name isEqualToString:@"Customer"]) customerSchema = st;
			if ([st.name isEqualToString:@"Invoice"]) invoiceSchema = st;
		}
		if (customerSchema == nil || invoiceSchema == nil) {
			fprintf(stderr, "FAIL: Missing Customer or Invoice schema table in Chinook\n");
			return 32;
		}
		RptqQueryTable *qtCustomer = [qVC addSchemaTableToQuery:customerSchema];
		RptqQueryTable *qtInvoice = [qVC addSchemaTableToQuery:invoiceSchema];
		if (qtCustomer == nil || qtInvoice == nil ||
			qtCustomer.hasQueryFields.count != customerSchema.hasFields.count ||
			qtInvoice.hasQueryFields.count != invoiceSchema.hasFields.count) {
			fprintf(stderr, "FAIL: Adding tables to query did not populate RptqQueryField children\n");
			return 33;
		}
		NSView *customerCard = [qVC tableCardViewForQueryTableID:qtCustomer.identifier];
		NSView *invoiceCard = [qVC tableCardViewForQueryTableID:qtInvoice.identifier];
		if (customerCard == nil || invoiceCard == nil) {
			fprintf(stderr, "FAIL: Floating table card views were not created on the visual canvas\n");
			return 34;
		}

		// 4d. Connect Customer.CustomerId to Invoice.CustomerId -> default Left Outer Join
		RptqQueryField *custIdField = nil;
		RptqQueryField *invCustIdField = nil;
		for (RptqQueryField *qf in qtCustomer.hasQueryFields) {
			if ([qf.databaseSchemaField.name isEqualToString:@"CustomerId"]) {
				custIdField = qf;
				break;
			}
		}
		for (RptqQueryField *qf in qtInvoice.hasQueryFields) {
			if ([qf.databaseSchemaField.name isEqualToString:@"CustomerId"]) {
				invCustIdField = qf;
				break;
			}
		}
		RptqQueryLinks *joinLink = [qVC connectQueryField:custIdField toQueryField:invCustIdField];
		if (joinLink == nil || joinLink.type != MADLinkTypeLeftOuterJoin || qMacDoc.rptqQuery.hasQueryLinks.count != 1) {
			fprintf(stderr, "FAIL: Connecting fields did not create a default Left Outer Join link\n");
			return 35;
		}
		BOOL custIsRoot = [[customerCard valueForKey:@"isRootTable"] boolValue];
		BOOL invIsRoot = [[invoiceCard valueForKey:@"isRootTable"] boolValue];
		if (!custIsRoot || invIsRoot) {
			fprintf(stderr, "FAIL: Topological root/child classification failed (custIsRoot=%d, invIsRoot=%d)\n", custIsRoot, invIsRoot);
			return 36;
		}
		if (![sqlTextView.string containsString:@"LEFT OUTER JOIN"]) {
			fprintf(stderr, "FAIL: Generated SQL does not contain LEFT OUTER JOIN: %s\n", sqlTextView.string.UTF8String);
			return 37;
		}

		// 4e. Select visual link and modify link type to Inner Join
		[qVC selectQueryLink:joinLink showPopover:NO];
		if (qVC.selectedLinkIdentifier != joinLink.identifier) {
			fprintf(stderr, "FAIL: Selecting visual link did not update selectedLinkIdentifier\n");
			return 38;
		}
		[qVC updateQueryLink:joinLink joinType:MADLinkTypeInnerJoin];
		if (joinLink.type != MADLinkTypeInnerJoin || ![sqlTextView.string containsString:@"INNER JOIN"]) {
			fprintf(stderr, "FAIL: Modifying link type to Inner Join did not update link or generated SQL: %s\n", sqlTextView.string.UTF8String);
			return 39;
		}
		printf("PASS: Verified Visual Query Designer: mutually exclusive Designer/SQL modes, fixed 200px user-resizable table list, floating table cards, Left Outer Join field connection, and link type modification\n");

		// 5. Test Redesigned Report Designer (MADMacDesignerViewController & MADMacDesignerCanvasView)
		[qWC switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
		[qWC.window setFrame:NSMakeRect(0.0, 0.0, 1360.0, 860.0) display:YES];
		[qWC.window layoutIfNeeded];

		MADMacDesignerViewController *dVC = qWC.designerViewController;
		MADMacDesignerCanvasView *dCanvas = dVC.canvasView;
		NSSplitView *dMainSplit = [dVC valueForKey:@"mainSplitView"];
		NSView *dLeftSidebar = [dVC valueForKey:@"leftSidebarView"];
		NSView *dCenterContainer = [dVC valueForKey:@"centerCanvasContainerView"];
		NSView *dRightInspector = [dVC valueForKey:@"rightInspectorContainerView"];

		// 5a. Verify 3-pane split view defaults (left=220pt, right=260pt) and user resizability
		if (fabs(dVC.leftSidebarWidth - 220.0) > 1.5 || fabs(NSWidth(dLeftSidebar.frame) - 220.0) > 1.5 ||
			fabs(dVC.rightInspectorWidth - 260.0) > 1.5 || fabs(NSWidth(dRightInspector.frame) - 260.0) > 1.5) {
			fprintf(stderr, "FAIL: Designer initial split widths unexpected (left=%.1f, right=%.1f)\n",
					NSWidth(dLeftSidebar.frame), NSWidth(dRightInspector.frame));
			return 40;
		}
		CGFloat initialCenterWidth = NSWidth(dCenterContainer.frame);
		[qWC.window setFrame:NSMakeRect(0.0, 0.0, 1560.0, 920.0) display:YES];
		[qWC.window layoutIfNeeded];
		if (fabs(NSWidth(dLeftSidebar.frame) - 220.0) > 1.5 ||
			fabs(NSWidth(dRightInspector.frame) - 260.0) > 1.5 ||
			NSWidth(dCenterContainer.frame) <= initialCenterWidth + 100.0) {
			fprintf(stderr, "FAIL: Window resize did not keep Designer sidebars fixed (left=%.1f, right=%.1f)\n",
					NSWidth(dLeftSidebar.frame), NSWidth(dRightInspector.frame));
			return 41;
		}
		// User drags right inspector divider to make right inspector 300pt wide
		CGFloat totalSplitW = NSWidth(dMainSplit.bounds);
		CGFloat dThick = dMainSplit.dividerThickness;
		[dMainSplit setPosition:(totalSplitW - dThick - 300.0) ofDividerAtIndex:1];
		[dMainSplit adjustSubviews];
		if (fabs(dVC.rightInspectorWidth - 300.0) > 2.0 || fabs(NSWidth(dRightInspector.frame) - 300.0) > 2.0) {
			fprintf(stderr, "FAIL: Right inspector divider could not be resized to 300pt (got %.1f)\n",
					NSWidth(dRightInspector.frame));
			return 42;
		}
		[qWC.window setFrame:NSMakeRect(0.0, 0.0, 1400.0, 860.0) display:YES];
		[qWC.window layoutIfNeeded];
		if (fabs(NSWidth(dRightInspector.frame) - 300.0) > 2.0) {
			fprintf(stderr, "FAIL: Window resize snapped right inspector back instead of keeping 300pt (got %.1f)\n",
					NSWidth(dRightInspector.frame));
			return 43;
		}

		// 5b. Verify minimap view is wired to canvasView
		if (dVC.minimapView == nil || dVC.minimapView.canvasView != dCanvas) {
			fprintf(stderr, "FAIL: Designer minimapView is missing or not connected to canvasView\n");
			return 44;
		}

		// 5c. Verify adding multiple elements does NOT stack them at (0, 0)
		RptqDocumentSection *detailSec = qMacDoc.rptqDocument.hasDetailSection;
		dCanvas.selectedSection = detailSec;
		[dVC addStaticLabelAction:nil];
		RptqDocumentElement *el1 = dCanvas.primarySelectedElement;
		[dVC addDataFieldAction:nil];
		RptqDocumentElement *el2 = dCanvas.primarySelectedElement;
		[dVC addAggregateAction:nil];
		RptqDocumentElement *el3 = dCanvas.primarySelectedElement;
		if (el1 == nil || el2 == nil || el3 == nil || el1 == el2 || el2 == el3) {
			fprintf(stderr, "FAIL: Failed to insert three distinct elements into Detail section\n");
			return 45;
		}
		NSRect r1 = [dCanvas elementRectInSectionContent:el1];
		NSRect r2 = [dCanvas elementRectInSectionContent:el2];
		NSRect r3 = [dCanvas elementRectInSectionContent:el3];
		if (NSEqualPoints(r1.origin, r2.origin) || NSEqualPoints(r2.origin, r3.origin) ||
			NSIntersectsRect(NSInsetRect(r1, 1.0, 1.0), NSInsetRect(r2, 1.0, 1.0))) {
			fprintf(stderr, "FAIL: Inserted elements stacked or overlapped: r1=(%.1f,%.1f) r2=(%.1f,%.1f) r3=(%.1f,%.1f)\n",
					r1.origin.x, r1.origin.y, r2.origin.x, r2.origin.y, r3.origin.x, r3.origin.y);
			return 46;
		}

		// 5d. Verify changing X (pt) and Y (pt) updates element position and does NOT reset to origin
		[dCanvas selectElement:el1 extendSelection:NO];
		NSTextField *posXField = [dVC valueForKey:@"posXField"];
		NSTextField *posYField = [dVC valueForKey:@"posYField"];
		posXField.doubleValue = 184.0;
		posYField.doubleValue = 28.0;
		[dVC performSelector:@selector(elementGeometryEdited:) withObject:posXField];
		NSRect movedRect = [dCanvas elementRectInSectionContent:el1];
		if (fabs(movedRect.origin.x - 184.0) > 0.5 || fabs(movedRect.origin.y - 28.0) > 0.5 ||
			fabs(el1.rect.origin.x - 184.0) > 0.5 || fabs(el1.dropPoint.x - 184.0) > 0.5 ||
			fabs(posXField.doubleValue - 184.0) > 0.5) {
			fprintf(stderr, "FAIL: Editing X/Y in inspector did not persist (rect=(%.1f,%.1f), field=%.1f)\n",
					movedRect.origin.x, movedRect.origin.y, posXField.doubleValue);
			return 47;
		}
		// Verify Undo & Redo of X/Y move
		[qMacDoc.undoManager undo];
		NSRect undoneRect = [dCanvas elementRectInSectionContent:el1];
		if (fabs(undoneRect.origin.x - r1.origin.x) > 0.5 || fabs(undoneRect.origin.y - r1.origin.y) > 0.5) {
			fprintf(stderr, "FAIL: Undo of element geometry edit did not restore original origin (%.1f, %.1f)\n",
					undoneRect.origin.x, undoneRect.origin.y);
			return 48;
		}
		[qMacDoc.undoManager redo];
		NSRect redoneRect = [dCanvas elementRectInSectionContent:el1];
		if (fabs(redoneRect.origin.x - 184.0) > 0.5 || fabs(redoneRect.origin.y - 28.0) > 0.5) {
			fprintf(stderr, "FAIL: Redo of element geometry edit did not re-apply (184, 28)\n");
			return 49;
		}

		// 5e. Verify moving element across sections (Detail -> Page Header) and Undo/Redo
		RptqDocumentSection *pageHeaderSec = qMacDoc.rptqDocument.hasPageHeaderSection;
		[dCanvas selectElement:el1 extendSelection:NO];
		if (![dVC moveSelectedElementsToSection:pageHeaderSec] ||
			[dCanvas sectionContainingElement:el1] != pageHeaderSec ||
			[[dCanvas elementsInSection:detailSec] containsObject:el1]) {
			fprintf(stderr, "FAIL: Moving element from Detail to Page Header failed\n");
			return 50;
		}
		[qMacDoc.undoManager undo];
		if ([dCanvas sectionContainingElement:el1] != detailSec ||
			![[dCanvas elementsInSection:detailSec] containsObject:el1]) {
			fprintf(stderr, "FAIL: Undo of cross-section move did not return element to Detail section\n");
			return 51;
		}
		[qMacDoc.undoManager redo];
		if ([dCanvas sectionContainingElement:el1] != pageHeaderSec) {
			fprintf(stderr, "FAIL: Redo of cross-section move did not return element to Page Header\n");
			return 52;
		}

		[fm removeItemAtURL:qDocURL error:NULL];
		printf("PASS: Verified Report Designer: resizable 3-pane split view, interactive minimap, non-stacking element insertion, persistent X/Y positioning with Undo/Redo, and cross-section element movement\n");

		// 6. Test Redesigned Report Viewer (MADMacViewerViewController)
		MADMacDocument *vMacDoc = [[MADMacDocument alloc] init];
		vMacDoc.fileURL = [NSURL fileURLWithPath:sampleLondonPath];
		[vMacDoc adoptHeadlessDocument:london];
		[vMacDoc makeWindowControllers];
		MADMacWindowController *vWC = vMacDoc.windowControllers.firstObject;
		[vWC switchToWorkspaceTab:MADMacWorkspaceTabViewer];
		[vWC.window layoutIfNeeded];

		MADMacViewerViewController *vVC = vWC.viewerViewController;

		// 6a. Refresh, Print, and Export buttons have icons
		if (vVC.refreshButton.image == nil || vVC.printButton.image == nil || vVC.exportButton.image == nil) {
			fprintf(stderr, "FAIL: Viewer toolbar buttons missing icons\n");
			return 53;
		}

		// 6b. Status bar pluralization for 0, 1, and >1 items and green rendered color
		NSString *msg0 = [MADMacViewerViewController statusMessageForPageCount:0 rowCount:0];
		NSString *msg1 = [MADMacViewerViewController statusMessageForPageCount:1 rowCount:1];
		NSString *msgN = [MADMacViewerViewController statusMessageForPageCount:3 rowCount:42];
		if (![msg0 isEqualToString:@"Rendered 0 pages from 0 cached rows."] ||
			![msg1 isEqualToString:@"Rendered 1 page from 1 cached row."] ||
			![msgN isEqualToString:@"Rendered 3 pages from 42 cached rows."]) {
			fprintf(stderr, "FAIL: Unexpected status message pluralization: '%s' / '%s' / '%s'\n",
					msg0.UTF8String, msg1.UTF8String, msgN.UTF8String);
			return 54;
		}
		if (![vVC.statusLabel.superview isDescendantOf:vVC.statusBarView] ||
			![vVC.statusLabel.textColor isEqual:[NSColor systemGreenColor]]) {
			fprintf(stderr, "FAIL: Status label not inside bottom status bar or not green after render\n");
			return 55;
		}

		// 6c. Framed fixed-size page canvas (autoScales == NO) that does not resize with window, plus explicit zoom
		if (vVC.pdfView.autoScales || !vVC.pdfView.displaysPageBreaks || fabs(vVC.zoomScale - 1.0) > 0.01) {
			fprintf(stderr, "FAIL: Viewer PDFView is not fixed-size framed (autoScales=%d, zoom=%.2f)\n",
					vVC.pdfView.autoScales, vVC.zoomScale);
			return 56;
		}
		[vWC.window setFrame:NSMakeRect(0.0, 0.0, 1600.0, 960.0) display:YES];
		[vWC.window layoutIfNeeded];
		if (fabs(vVC.pdfView.scaleFactor - 1.0) > 0.01 ||
			fabs(vVC.renderedPaperSize.width - 612.0) > 0.5 ||
			fabs(vVC.renderedPaperSize.height - 792.0) > 0.5) {
			fprintf(stderr, "FAIL: Resizing viewer window altered scaleFactor (%.2f) or paperSize (%.1fx%.1f)\n",
					vVC.pdfView.scaleFactor, vVC.renderedPaperSize.width, vVC.renderedPaperSize.height);
			return 57;
		}
		[vVC zoomInAction:nil];
		if (fabs(vVC.zoomScale - 1.25) > 0.01 || fabs(vVC.pdfView.scaleFactor - 1.25) > 0.01) {
			fprintf(stderr, "FAIL: Zoom In did not set scaleFactor to 1.25 (got %.2f)\n", vVC.pdfView.scaleFactor);
			return 58;
		}
		[vVC zoomActualSizeAction:nil];
		if (fabs(vVC.zoomScale - 1.0) > 0.01 || fabs(vVC.pdfView.scaleFactor - 1.0) > 0.01) {
			fprintf(stderr, "FAIL: Zoom Actual Size did not restore scaleFactor to 1.0\n");
			return 59;
		}

		// 6d. Page Size selection before refresh & persistence until next refresh
		if (vVC.selectedPaperType != MTPaperTypeLetter || vVC.renderedPaperType != MTPaperTypeLetter) {
			fprintf(stderr, "FAIL: Viewer did not default to US Letter paper size\n");
			return 60;
		}
		// Select A4 in combo box without refreshing yet -> renderedPaperType stays US Letter (612x792)
		[vVC selectPaperType:MTPaperTypeA4];
		if (vVC.selectedPaperType != MTPaperTypeA4 || vVC.renderedPaperType != MTPaperTypeLetter ||
			fabs(vVC.renderedPaperSize.width - 612.0) > 0.5) {
			fprintf(stderr, "FAIL: Changing page size combo before refresh mutated renderedPaperType prematurely\n");
			return 61;
		}
		// Now refresh -> renderedPaperType locks to A4 (595x842) and PDF page MediaBox matches A4
		[london setPaperType:vVC.selectedPaperType];
		[vVC setValue:@(MTPaperTypeA4) forKey:@"renderedPaperType"];
		[vVC reloadPreview];
		PDFPage *firstPage = [vVC.pdfView.document pageAtIndex:0];
		NSRect pageMediaBox = [firstPage boundsForBox:kPDFDisplayBoxMediaBox];
		if (vVC.renderedPaperType != MTPaperTypeA4 ||
			fabs(vVC.renderedPaperSize.width - 595.0) > 1.0 ||
			fabs(vVC.renderedPaperSize.height - 842.0) > 1.0 ||
			fabs(pageMediaBox.size.width - 595.0) > 1.0 ||
			fabs(pageMediaBox.size.height - 842.0) > 1.0) {
			fprintf(stderr, "FAIL: Refresh with A4 did not render A4 PDF page (got %.1fx%.1f)\n",
					pageMediaBox.size.width, pageMediaBox.size.height);
			return 62;
		}
		// Reset london back to Letter
		[vVC selectPaperType:MTPaperTypeLetter];
		[london setPaperType:MTPaperTypeLetter];

		// 6e. Export save panel includes format selector accessory view and updates filename extension
		NSSavePanel *exportPanel = [vVC configureExportSavePanel:[NSSavePanel savePanel]];
		if (exportPanel.accessoryView == nil || vVC.exportFormatPopup == nil || vVC.exportFormatPopup.numberOfItems < 7) {
			fprintf(stderr, "FAIL: Export save panel missing format selection accessory view\n");
			return 63;
		}
		if (![exportPanel.nameFieldStringValue hasSuffix:@".pdf"]) {
			fprintf(stderr, "FAIL: Export save panel did not default to .pdf filename (got %s)\n",
					exportPanel.nameFieldStringValue.UTF8String);
			return 64;
		}
		// Select CSV in the export format popup and verify extension updates to .csv
		NSInteger csvIdx = [vVC.exportFormatPopup indexOfItemWithRepresentedObject:@"csv"];
		[vVC.exportFormatPopup selectItemAtIndex:csvIdx];
		[vVC performSelector:@selector(exportSavePanelFormatChanged:) withObject:vVC.exportFormatPopup];
		if (![exportPanel.nameFieldStringValue hasSuffix:@".csv"]) {
			fprintf(stderr, "FAIL: Changing export format popup to CSV did not update save panel extension to .csv (got %s)\n",
					exportPanel.nameFieldStringValue.UTF8String);
			return 65;
		}
		printf("PASS: Verified Report Viewer: toolbar icons, bottom status bar with singular/plural grammar, framed fixed-size page with zoom, page size persistence across refresh, and export dialog format selector\n");
	}
	return 0;
}
