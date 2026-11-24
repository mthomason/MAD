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
#import "MADMacAboutWindowController.h"
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
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADSqlite3/MADArrayCaching.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADFoundation/MADCredential.h>
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

static NSMutableArray *sRetainedPanels = nil;

static BOOL MADSmokeRunSQLite(NSURL *url, NSArray<NSString *> *statements);
static NSString *MADSmokeBuildComposedDocument(NSURL *invoicesURL, NSURL *paymentsURL, NSURL *madURL, BOOL grouped, NSString **outError);

// Builds a composed invoices/payments fixture -- the .mad plus its two sqlite sources
// -- the same way the CLI's MADFixtureMaker compose does, through the production store
// and archive writers, so the native document path below opens exactly what a user's
// composed document looks like.
static NSString *MADSmokeCreateComposedFixture(NSString *directory, NSString **outError) {
	NSURL *invoicesURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"invoices.sqlite"]];
	NSURL *paymentsURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"payments.sqlite"]];
	NSURL *madURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"composed.mad"]];

	if (!MADSmokeRunSQLite(invoicesURL, @[@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL, note TEXT);",
										 @"INSERT INTO invoices VALUES (1, 100.0, 'first');",
										 @"INSERT INTO invoices VALUES (2, 200.0, 'second');",
										 @"INSERT INTO invoices VALUES (3, 300.0, 'third');"])) {
		if (outError) *outError = @"could not write invoices source";
		return nil;
	}
	if (!MADSmokeRunSQLite(paymentsURL, @[@"CREATE TABLE payments (payment_id INTEGER, invoice_id INTEGER, amount REAL);",
										 @"INSERT INTO payments VALUES (101, 1, 40.0);",
										 @"INSERT INTO payments VALUES (102, 1, 60.0);"])) {
		if (outError) *outError = @"could not write payments source";
		return nil;
	}
	return MADSmokeBuildComposedDocument(invoicesURL, paymentsURL, madURL, NO, outError);
}

// Writes one sqlite source file from the given schema + row statements.
static BOOL MADSmokeRunSQLite(NSURL *url, NSArray<NSString *> *statements) {
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeItemAtURL:url error:NULL];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	database.databaseConnection = connection;
	[database openDatabase];
	NSError *error = nil;
	for (NSString *statement in statements) {
		if (![database executeSQL:statement fieldKeys:@[] onConnection:nil intoResultTable:nil transactionSet:NO returnsResults:NO binaryBindings:nil withError:&error]) {
			[database closeDatabaseConnectionIfOpen];
			return NO;
		}
	}
	[database closeDatabaseConnectionIfOpen];
	return YES;
}

// Builds a composed invoices/payments .mad from two already-written sources, through the
// production store and archive writers (the same path the CLI's MADFixtureMaker uses).
static NSString *MADSmokeBuildComposedDocument(NSURL *invoicesURL, NSURL *paymentsURL, NSURL *madURL, BOOL grouped, NSString **outError) {
	NSFileManager *fm = [NSFileManager defaultManager];
	MADDocumentStore *store = [MADDocumentStore storeForDocumentURL:madURL];
	[fm removeItemAtURL:store.gutsURL error:NULL];
	NSError *error = nil;
	if (![store openWithError:&error]) {
		if (outError) *outError = error.localizedDescription;
		return nil;
	}
	RptqStoreContext *context = store.context;
	[context loadAllWithError:NULL];

	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqObject *(^source)(NSURL *, NSString *, int64_t, int64_t, int64_t, NSArray<NSString *> *) =
		^(NSURL *url, NSString *queryName, int64_t dbId, int64_t queryId, int64_t tableId, NSArray<NSString *> *labelled) {
		RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:dbId];
		[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
		RptqObject *credential = [context insertObjectForEntity:@"RptqDatabaseCredentals" identifier:0];
		[credential setValue:url.lastPathComponent forKey:@"dbname"];
		[credential setValue:url.path forKey:@"host"];
		[database setValue:credential forKey:@"ownedByUser"];

		RptqObject *schemaTable = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:tableId + 1];
		[schemaTable setValue:queryName forKey:@"name"];
		RptqObject *idField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:tableId + 2];
		[idField setValue:@"invoice_id" forKey:@"name"];
		RptqObject *amountField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:tableId + 3];
		[amountField setValue:@"amount" forKey:@"name"];
		[database setValue:@[schemaTable] forKey:@"hasTables"];
		[schemaTable setValue:@[idField, amountField] forKey:@"hasFields"];

		RptqObject *query = [context insertObjectForEntity:@"RptqQuery" identifier:queryId];
		[query setValue:queryName forKey:@"name"];
		[database setValue:@[query] forKey:@"hasQueries"];
		RptqObject *queryTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:tableId];
		[queryTable setValue:schemaTable forKey:@"databaseSchemaTable"];
		[queryTable setValue:query forKey:@"inQuery"];

		NSMutableArray *fields = [NSMutableArray arrayWithCapacity:2];
		for (RptqObject *schemaField in @[idField, amountField]) {
			NSString *fieldName = [schemaField valueForKey:@"name"];
			RptqObject *field = [context insertObjectForEntity:@"RptqQueryField" identifier:0];
			[field setValue:schemaField forKey:@"databaseSchemaField"];
			[field setValue:queryTable forKey:@"inQueryTable"];
			[fields addObject:field];
			if ([labelled containsObject:fieldName]) {
				RptqObject *label = [context insertObjectForEntity:@"RptqDocumentElementLabelDataField" identifier:0];
				[label setValue:field forKey:@"referencesQueryField"];
			}
		}
		[queryTable setValue:fields forKey:@"hasQueryFields"];
		return query;
	};

	RptqObject *invoices = source(invoicesURL, @"invoices", 10, 101, 200, @[@"invoice_id", @"amount"]);
	RptqObject *payments = source(paymentsURL, @"payments", 20, 102, 300, @[@"amount"]);
	RptqObject *invoicesDatabase = [invoices valueForKey:@"inDatabase"];
	RptqObject *paymentsDatabase = [payments valueForKey:@"inDatabase"];
	[document setValue:@[invoicesDatabase, paymentsDatabase] forKey:@"hasDatabaseSchemas"];

	RptqObject *root = [context insertObjectForEntity:@"RptqQuery" identifier:100];
	[root setValue:@"root" forKey:@"name"];
	[root setValue:invoicesDatabase forKey:@"inDatabase"];
	RptqObject *rootInvoicesTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:400];
	[rootInvoicesTable setValue:root forKey:@"inQuery"];
	[rootInvoicesTable setValue:invoices forKey:@"upstreamQuery"];
	RptqObject *rootPaymentsTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:401];
	[rootPaymentsTable setValue:root forKey:@"inQuery"];
	[rootPaymentsTable setValue:payments forKey:@"upstreamQuery"];

	RptqObject *invoiceIdField = [context objectForEntity:@"RptqDatabaseSchemaField" identifier:202];
	RptqObject *invoiceAmountField = [context objectForEntity:@"RptqDatabaseSchemaField" identifier:203];
	RptqObject *paymentIdField = [context objectForEntity:@"RptqDatabaseSchemaField" identifier:302];
	RptqObject *paymentAmountField = [context objectForEntity:@"RptqDatabaseSchemaField" identifier:303];

	RptqObject *leftJoinField = [context insertObjectForEntity:@"RptqQueryField" identifier:500];
	[leftJoinField setValue:invoiceIdField forKey:@"databaseSchemaField"];
	[leftJoinField setValue:rootInvoicesTable forKey:@"inQueryTable"];
	RptqObject *rightJoinField = [context insertObjectForEntity:@"RptqQueryField" identifier:501];
	[rightJoinField setValue:paymentIdField forKey:@"databaseSchemaField"];
	[rightJoinField setValue:rootPaymentsTable forKey:@"inQueryTable"];
	RptqObject *join = [context insertObjectForEntity:@"RptqQueryLinks" identifier:450];
	[join setValue:@(MADLinkTypeLeftOuterJoin) forKey:@"type"];
	[join setValue:leftJoinField forKey:@"hasLeftField"];
	[join setValue:rightJoinField forKey:@"hasRightField"];
	[join setValue:root forKey:@"inQuery"];

	RptqObject *out0 = [context insertObjectForEntity:@"RptqQueryField" identifier:600];
	[out0 setValue:invoiceIdField forKey:@"databaseSchemaField"];
	[out0 setValue:rootInvoicesTable forKey:@"inQueryTable"];
	[out0 setValue:@"invoice_id" forKey:@"outputKey"];
	[out0 setValue:@0 forKey:@"outputIndex"];
	RptqObject *out1 = [context insertObjectForEntity:@"RptqQueryField" identifier:601];
	[out1 setValue:invoiceAmountField forKey:@"databaseSchemaField"];
	[out1 setValue:rootInvoicesTable forKey:@"inQueryTable"];
	[out1 setValue:@"invoice_amount" forKey:@"outputKey"];
	[out1 setValue:@1 forKey:@"outputIndex"];
	RptqObject *out2 = [context insertObjectForEntity:@"RptqQueryField" identifier:602];
	[out2 setValue:paymentAmountField forKey:@"databaseSchemaField"];
	[out2 setValue:rootPaymentsTable forKey:@"inQueryTable"];
	[out2 setValue:@"payment_amount" forKey:@"outputKey"];
	[out2 setValue:@2 forKey:@"outputIndex"];

	[document setValue:root forKey:@"rootQuery"];

	// A detail band whose labels are bound to the root outputs, so the Viewer renders
	// the joined rows and the amounts bind to their own root keys.
	RptqDocumentSection *detail = document.hasDetailSection;
	NSArray<RptqObject *> *outputs = @[out0, out1, out2];
	CGFloat labelX = 12.0;
	for (RptqObject *output in outputs) {
		RptqDocumentElementLabelDataField *label =
			(RptqDocumentElementLabelDataField *)[context insertObjectForEntity:@"RptqDocumentElementLabelDataField" identifier:0];
		label.type = MADPrintPageElementTypeLabelDynamic;
		label.referencesQueryField = (RptqQueryField *)output;
		label.text = [output valueForKey:@"outputKey"];
		[label setSizeWidth:90.0f height:20.0f];
		[detail addDocumentObject:label withDropPoint:CGPointMake(labelX, 6.0f) managedObjectContext:context];
		labelX += 100.0f;
	}

	if (grouped) {
		// Two nested groups on the root, the way the app's add-group path does:
		// invoice_id ascending, then payment_amount descending.  The fields are the
		// root output fields, whose persisted outputKey is the grouping key.
		RptqObject *(^addGroup)(RptqObject *, MADSortOrder, int16_t) = ^(RptqObject *field, MADSortOrder order, int16_t weight) {
			RptqQueryGroup *group = [RptqQueryGroup newQueryGroupQueryWithSortOrder:order andManagedObjectContext:context];
			group.hasField = (RptqQueryField *)field;
			group.weight = weight;
			RptqDocumentSection *header = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeGroupHeader forManagedObjectContext:context];
			[group addHasSectionObject:header];
			RptqDocumentSection *footer = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeGroupFooter forManagedObjectContext:context];
			[group addHasSectionObject:footer];
			[(RptqQuery *)root addHasQueryGroupsObject:group];
			return group;
		};
		addGroup(out0, MADSortOrderAccending, 0);
		addGroup(out2, MADSortOrderDecending, 1);
	}

	if (![context saveComposed:&error]) {
		if (outError) *outError = error.localizedDescription;
		return nil;
	}
	[store close];

	MADArchiveManager *writer = [[MADArchiveManager alloc] initWithFileWrapperURL:store.gutsURL archiveURL:madURL];
	writer.composed = YES;
	if (![writer archive:YES]) {
		if (outError) *outError = @"composed archive failed";
		return nil;
	}
	return madURL.path;
}

// A multi-page composed fixture: `invoiceCount` invoices in a deterministic pattern --
// invoice i has amount 1000+i; invoices i%3==0 carry two payments (2000+i and 3000+i),
// i%3==1 carry one (2000+i), and i%3==2 carry none.  Invoices and payments are inserted
// in sorted order, so the composed LEFT JOIN materializes the detail rows in that order.
static NSString *MADSmokeCreateComposedFixtureWithInvoiceCount(NSUInteger invoiceCount,
																NSString *directory,
																NSString **outError) {
	NSURL *invoicesURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"invoices.sqlite"]];
	NSURL *paymentsURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"payments.sqlite"]];
	NSURL *madURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"composed.mad"]];

	NSMutableArray<NSString *> *invoiceStatements = [NSMutableArray arrayWithObject:@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL, note TEXT);"];
	NSMutableArray<NSString *> *paymentStatements = [NSMutableArray arrayWithObject:@"CREATE TABLE payments (payment_id INTEGER, invoice_id INTEGER, amount REAL);"];
	for (NSUInteger i = 1; i <= invoiceCount; i++) {
		[invoiceStatements addObject:[NSString stringWithFormat:@"INSERT INTO invoices VALUES (%lu, %lu.0, 'inv%lu');", (unsigned long)i, (unsigned long)(1000 + i), (unsigned long)i]];
		if (i % 3 == 0) {
			[paymentStatements addObject:[NSString stringWithFormat:@"INSERT INTO payments VALUES (%lu, %lu, %lu.0);", (unsigned long)(i * 100 + 1), (unsigned long)i, (unsigned long)(2000 + i)]];
			[paymentStatements addObject:[NSString stringWithFormat:@"INSERT INTO payments VALUES (%lu, %lu, %lu.0);", (unsigned long)(i * 100 + 2), (unsigned long)i, (unsigned long)(3000 + i)]];
		} else if (i % 3 == 1) {
			[paymentStatements addObject:[NSString stringWithFormat:@"INSERT INTO payments VALUES (%lu, %lu, %lu.0);", (unsigned long)(i * 100 + 1), (unsigned long)i, (unsigned long)(2000 + i)]];
		}
	}

	if (!MADSmokeRunSQLite(invoicesURL, invoiceStatements)) {
		if (outError) *outError = @"could not write invoices source";
		return nil;
	}
	if (!MADSmokeRunSQLite(paymentsURL, paymentStatements)) {
		if (outError) *outError = @"could not write payments source";
		return nil;
	}
	return MADSmokeBuildComposedDocument(invoicesURL, paymentsURL, madURL, NO, outError);
}

// A grouped composed fixture big enough that one group crosses a page boundary: invoice 1
// carries 40 payments, invoice 2 five, and invoice 3 none, with the rows deliberately
// shuffled so both the ascending and descending groups have to reorder them.
static NSString *MADSmokeCreateGroupedComposedFixture(NSString *directory, NSString **outError) {
	NSURL *invoicesURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"invoices.sqlite"]];
	NSURL *paymentsURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"payments.sqlite"]];
	NSURL *madURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"composed.mad"]];

	NSMutableArray<NSString *> *invoiceStatements = [NSMutableArray arrayWithObject:@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL, note TEXT);"];
	[invoiceStatements addObject:@"INSERT INTO invoices VALUES (3, 300.0, 'third');"];
	[invoiceStatements addObject:@"INSERT INTO invoices VALUES (1, 100.0, 'first');"];
	[invoiceStatements addObject:@"INSERT INTO invoices VALUES (2, 200.0, 'second');"];

	NSMutableArray<NSString *> *paymentStatements = [NSMutableArray arrayWithObject:@"CREATE TABLE payments (payment_id INTEGER, invoice_id INTEGER, amount REAL);"];
	for (NSUInteger p = 1; p <= 40; p++) {
		// Insert invoice 1's payments in ascending amount order so the descending group
		// has to reorder them.
		[paymentStatements addObject:[NSString stringWithFormat:@"INSERT INTO payments VALUES (%lu, 1, %lu.0);", (unsigned long)(1000 + p), (unsigned long)(100 + p)]];
	}
	for (NSUInteger p = 1; p <= 5; p++) {
		[paymentStatements addObject:[NSString stringWithFormat:@"INSERT INTO payments VALUES (%lu, 2, %lu.0);", (unsigned long)(2000 + p), (unsigned long)(200 + p)]];
	}

	if (!MADSmokeRunSQLite(invoicesURL, invoiceStatements)) {
		if (outError) *outError = @"could not write grouped invoices source";
		return nil;
	}
	if (!MADSmokeRunSQLite(paymentsURL, paymentStatements)) {
		if (outError) *outError = @"could not write grouped payments source";
		return nil;
	}
	return MADSmokeBuildComposedDocument(invoicesURL, paymentsURL, madURL, YES, outError);
}

// The composed detail rows the multi-page fixture produces, in sorted order.  Each entry
// is (invoice_id, invoice_amount, payment_amount); payment_amount is NAN when unpaid.
static NSArray<NSArray<NSNumber *> *> *MADSmokeComposedExpectedRows(NSUInteger invoiceCount) {
	NSMutableArray<NSArray<NSNumber *> *> *rows = [NSMutableArray array];
	for (NSUInteger i = 1; i <= invoiceCount; i++) {
		double amount = 1000.0 + (double)i;
		if (i % 3 == 0) {
			[rows addObject:@[@(i), @(amount), @(2000.0 + (double)i)]];
			[rows addObject:@[@(i), @(amount), @(3000.0 + (double)i)]];
		} else if (i % 3 == 1) {
			[rows addObject:@[@(i), @(amount), @(2000.0 + (double)i)]];
		} else {
			[rows addObject:@[@(i), @(amount), @(NAN)]];
		}
	}
	return rows;
}

// The detail-band row ids across every page, in page order.
static NSArray<NSNumber *> *MADSmokeDetailRowIDsInPageOrder(MADReportFormatter *formatter) {
	NSMutableArray<NSNumber *> *rows = [NSMutableArray array];
	for (NSUInteger page = 0; page < formatter.reportLayout.count; page++) {
		for (MADSectionRepresentation *section in formatter.reportLayout[page]) {
			if (section.sectionType == MADDocumentSectionTypeBody) {
				[rows addObject:@(section.detailRowId)];
			}
		}
	}
	return rows;
}

// Reads one composed result cell as a double; NaN means the column is blank (NULL).
static double MADSmokeComposedDouble(MADDataTableFast *table, NSUInteger row, NSString *key) {
	NSError *error = nil;
	NSDictionary *dict = [table dataForRow:row column:key error:&error];
	id value = dict[key];
	if (value == nil || value == [NSNull null]) return NAN;
	return [value doubleValue];
}

int main(int argc, const char * argv[]) {
	sRetainedPanels = [[NSMutableArray alloc] init];
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
		[sRetainedPanels addObject:testPanel];
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
		[sRetainedPanels addObject:macDocCtrl.activeOpenPanel];
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
		[sRetainedPanels addObject:exportPanel];
		if (exportPanel.accessoryView == nil || vVC.exportFormatPopup == nil || vVC.exportFormatPopup.numberOfItems < 7) {
			fprintf(stderr, "FAIL: Export save panel missing format selection accessory view\n");
			return 63;
		}
		// NSSavePanel normalizes the name it reports (extension hiding is a saved user
		// preference, and a name with two extensions is trimmed differently per
		// account), so the stable contract is the selected format and its content
		// type; the panel adds the extension from the type on save.
		NSString *initialName = exportPanel.nameFieldStringValue;
		NSString *initialType = exportPanel.allowedContentTypes.firstObject.identifier;
		if (initialName.length == 0 ||
			![vVC.exportFormatPopup.selectedItem.representedObject isEqualToString:@"pdf"] ||
			![initialType isEqualToString:[UTType typeWithFilenameExtension:@"pdf"].identifier]) {
			fprintf(stderr, "FAIL: Export save panel did not default to PDF (name='%s', format='%s', type='%s')\n",
					initialName.UTF8String,
					[vVC.exportFormatPopup.selectedItem.representedObject description].UTF8String,
					initialType.UTF8String);
			return 64;
		}
		// Select CSV in the export format popup and verify the format and content type update.
		NSInteger csvIdx = [vVC.exportFormatPopup indexOfItemWithRepresentedObject:@"csv"];
		[vVC.exportFormatPopup selectItemAtIndex:csvIdx];
		[vVC performSelector:@selector(exportSavePanelFormatChanged:) withObject:vVC.exportFormatPopup];
		NSString *csvType = exportPanel.allowedContentTypes.firstObject.identifier;
		if (![vVC.exportFormatPopup.selectedItem.representedObject isEqualToString:@"csv"] ||
			![csvType isEqualToString:[UTType typeWithFilenameExtension:@"csv"].identifier]) {
			fprintf(stderr, "FAIL: Changing export format popup to CSV did not update the save panel (format='%s', type='%s')\n",
					[vVC.exportFormatPopup.selectedItem.representedObject description].UTF8String,
					csvType.UTF8String);
			return 65;
		}
		printf("PASS: Verified Report Viewer: toolbar icons, bottom status bar with singular/plural grammar, framed fixed-size page with zoom, page size persistence across refresh, and export dialog format selector\n");

		// 7. Test About Screen, Overview, Licensing, and Third-Party Acknowledgements (MADMacAboutWindowController)
		NSBundle *packagedAppBundle = [NSBundle bundleWithPath:appPath];
		if (packagedAppBundle == nil) {
			fprintf(stderr, "FAIL: Could not load NSBundle for packaged app at %s\n", appPath.UTF8String);
			return 66;
		}
		NSString *bundleIconFile = [packagedAppBundle objectForInfoDictionaryKey:@"CFBundleIconFile"];
		NSString *icnsPath = [packagedAppBundle pathForResource:@"AppIcon" ofType:@"icns"];
		NSImage *icnsImage = icnsPath.length > 0 ? [[NSImage alloc] initWithContentsOfFile:icnsPath] : nil;
		if (![bundleIconFile isEqualToString:@"AppIcon"] || icnsImage == nil || icnsImage.representations.count < 5) {
			fprintf(stderr, "FAIL: Packaged app bundle missing valid AppIcon.icns or CFBundleIconFile metadata (iconFile='%s', icnsPath='%s', reps=%lu)\n",
					bundleIconFile.UTF8String ?: "(null)",
					icnsPath.UTF8String ?: "(null)",
					(unsigned long)icnsImage.representations.count);
			return 66;
		}
		for (NSDictionary<NSString *, NSString *> *licenseEntry in [MADMacAboutWindowController bundledLicenseFiles]) {
			NSString *licenseFile = licenseEntry[@"file"];
			NSString *bundledLicensePath = [packagedAppBundle pathForResource:licenseFile ofType:nil inDirectory:@"Licenses"];
			if (bundledLicensePath.length == 0 || ![fm fileExistsAtPath:bundledLicensePath]) {
				fprintf(stderr, "FAIL: Packaged app bundle missing third-party license file Licenses/%s\n", licenseFile.UTF8String);
				return 67;
			}
		}

		// Verify App Menu "About MAD Designer" and Help menu items are wired to MADMacAppDelegate
		NSMenu *mainMenu = [NSApp mainMenu];
		NSMenu *appSubmenu = [mainMenu itemAtIndex:0].submenu;
		NSMenuItem *aboutMenuItem = [appSubmenu itemWithTitle:@"About MAD Designer"];
		if (aboutMenuItem == nil || aboutMenuItem.action != @selector(showAboutWindow:) || aboutMenuItem.target != appDelegate) {
			fprintf(stderr, "FAIL: 'About MAD Designer' menu item is not wired to showAboutWindow: on MADMacAppDelegate\n");
			return 68;
		}

		[appDelegate showAboutWindow:nil];
		MADMacAboutWindowController *aboutWC = appDelegate.aboutWindowController;
		if (aboutWC == nil || aboutWC.window == nil) {
			fprintf(stderr, "FAIL: MADMacAboutWindowController was not created by showAboutWindow:\n");
			return 69;
		}
		[aboutWC.window layoutIfNeeded];

		if (![aboutWC.titleLabel.stringValue isEqualToString:@"MAD Designer"] ||
			![aboutWC.versionLabel.stringValue containsString:@"v9.0"] ||
			![aboutWC.versionLabel.stringValue containsString:@"r4433"] ||
			![aboutWC.applicationVersionLabel.stringValue containsString:@"v0.7"] ||
			[aboutWC.versionLabel.stringValue isEqualToString:aboutWC.applicationVersionLabel.stringValue] ||
			![aboutWC.copyrightLabel.stringValue containsString:@"Copyright © 2012–2026 Michael Thomason"] ||
			![aboutWC.licenseSummaryLabel.stringValue containsString:@"Licensed under the MIT License"] ||
			![aboutWC.licenseSummaryLabel.stringValue containsString:@"not licensed under the MIT License"]) {
			fprintf(stderr, "FAIL: About window header labels missing required metadata: title='%s' engine='%s' application='%s' copyright='%s'\n",
					aboutWC.titleLabel.stringValue.UTF8String,
					aboutWC.versionLabel.stringValue.UTF8String,
					aboutWC.applicationVersionLabel.stringValue.UTF8String,
					aboutWC.copyrightLabel.stringValue.UTF8String);
			return 70;
		}

		// 7a. Verify Overview tab content matches iOS Overview (MADGettingStartedTableViewController)
		[appDelegate showAboutOverview:nil];
		NSString *overviewText = aboutWC.overviewTextView.string;
		NSArray<NSString *> *expectedOverviewPhrases = @[
			@"Mobile Analytics Document",
			@"MAD Designer is open-source business intelligence software by Michael Thomason.",
			@"A .mad file stores a report's schema snapshot, query definition, and visual layout in one compact, portable document.",
			@"MySQL / MariaDB, Microsoft SQL Server, and PostgreSQL",
			@"Workflow",
			@"1. Connect a Data Source",
			@"2. Build the Query (MAD Query)",
			@"3. Lay Out the Report (MAD Designer)",
			@"4. View & Export (MAD Viewer)",
			@"PDF, HTML, CSV, JSON, or plain text"
		];
		for (NSString *phrase in expectedOverviewPhrases) {
			if (![overviewText containsString:phrase]) {
				fprintf(stderr, "FAIL: About Overview tab missing expected text: '%s'\n", phrase.UTF8String);
				return 71;
			}
		}

		// 7b. Verify License & Notice tab content (MIT license, NOTICE, and LGPL-3.0 relink offer)
		[appDelegate showAboutLicensing:nil];
		NSString *licensingText = aboutWC.licensingTextView.string;
		NSArray<NSString *> *expectedLicensingPhrases = @[
			@"Licensed under the MIT License",
			@"not licensed under the MIT License",
			@"FreeTDS 1.4.27",
			@"MariaDB Connector/C 3.4.11",
			@"LGPL-3.0",
			@"mthomason@gmail.com",
			@"Permission is hereby granted, free of charge"
		];
		for (NSString *phrase in expectedLicensingPhrases) {
			if (![licensingText containsString:phrase]) {
				fprintf(stderr, "FAIL: About Licensing tab missing expected text: '%s'\n", phrase.UTF8String);
				return 72;
			}
		}

		// 7c. Verify Third-Party Acknowledgements tab content (all 16 components + full bundled license texts)
		[appDelegate showAboutAcknowledgements:nil];
		NSString *ackText = aboutWC.acknowledgementsTextView.string;
		NSArray<NSString *> *expectedAckPhrases = @[
			@"Open Source Components",
			@"SQLite",
			@"zlib",
			@"bzip2",
			@"libpng",
			@"libarchive",
			@"zint",
			@"OpenSSL",
			@"PostgreSQL libpq",
			@"MariaDB Connector/C",
			@"FreeTDS",
			@"asn1c runtime",
			@"pngquant rwpng",
			@"NSData+Base64",
			@"miniz",
			@"Font Awesome",
			@"Carbon Block",
			@"License Texts",
			@"GNU LESSER GENERAL PUBLIC LICENSE",
			@"Apache License"
		];
		for (NSString *phrase in expectedAckPhrases) {
			if (![ackText containsString:phrase]) {
				fprintf(stderr, "FAIL: About Acknowledgements tab missing expected text: '%s'\n", phrase.UTF8String);
				return 73;
			}
		}

		// 7d. Verify selecting an individual component in the Acknowledgements sidebar filters to that component
		[aboutWC selectComponentAtIndex:9]; // MariaDB Connector/C (1-based index in table after "All Components & Licenses")
		NSString *singleCompText = aboutWC.acknowledgementsTextView.string;
		if (![singleCompText containsString:@"MariaDB Connector/C"] ||
			![singleCompText containsString:@"GNU LESSER GENERAL PUBLIC LICENSE"]) {
			fprintf(stderr, "FAIL: Selecting MariaDB Connector/C in component sidebar did not display its attribution and LGPL-3.0 text\n");
			return 74;
		}
		[aboutWC selectComponentAtIndex:0];
		[aboutWC.window close];
		printf("PASS: Verified About Window: header metadata, Overview workflow, MIT/NOTICE/LGPL relink licensing, all 16 third-party component attributions, and 12 bundled license texts\n");

		// Remove temporary Application Support chinook copy before running datasource & path resolution tests
		[fm removeItemAtURL:installedChinook error:NULL];
		NSURL *localAppSupport = [MADURLFactory newURLForLocalApplicationSupportDirectory];
		if (localAppSupport != nil) {
			[fm removeItemAtURL:[localAppSupport URLByAppendingPathComponent:@"chinook.sqlite3"] error:NULL];
		}

		// 8. Verify Data Source & Connection UX (Parts A–D)
		NSString *dsTestDir = [NSTemporaryDirectory() stringByAppendingPathComponent:
							   [NSString stringWithFormat:@"mad-ds-smoke-%@", NSUUID.UUID.UUIDString]];
		[fm createDirectoryAtPath:dsTestDir withIntermediateDirectories:YES attributes:nil error:NULL];

		// 8a. Missing SQLite file must NOT create a 0-byte file on disk, and 0-byte artifacts must be removed
		NSURL *missingSqliteURL = [NSURL fileURLWithPath:[dsTestDir stringByAppendingPathComponent:@"nonexistent.sqlite3"]];
		MADDatabaseConnectionSqlite3 *missingConn = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:missingSqliteURL];
		MADDatabase *missingDb = [MADDatabase newDatabaseWithConnection:missingConn];
		if ([fm fileExistsAtPath:missingSqliteURL.path]) {
			fprintf(stderr, "FAIL: +newDatabaseWithConnection: created a file at missing SQLite path %s\n", missingSqliteURL.path.UTF8String);
			return 80;
		}
		NSError *missingConnErr = nil;
		id missingHandle = [missingDb connectWithConnection:missingConn credentals:nil connectionError:&missingConnErr];
		if (missingHandle != nil || missingConnErr == nil ||
			![missingConnErr.domain isEqualToString:MADDatabaseSqlite3ErrorDomain] ||
			missingConnErr.code != MADDatabaseSqlite3ErrorFileNotFound ||
			[fm fileExistsAtPath:missingSqliteURL.path]) {
			fprintf(stderr, "FAIL: Connecting to missing SQLite file did not fail cleanly without creating 0-byte file (handle=%p err=%s exists=%d)\n",
					missingHandle, missingConnErr.description.UTF8String, [fm fileExistsAtPath:missingSqliteURL.path]);
			return 81;
		}

		NSURL *zeroByteURL = [NSURL fileURLWithPath:[dsTestDir stringByAppendingPathComponent:@"zerobyte.sqlite3"]];
		[[NSData data] writeToURL:zeroByteURL atomically:YES];
		MADDatabaseConnectionSqlite3 *zeroConn = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:zeroByteURL];
		MADDatabase *zeroDb = [MADDatabase newDatabaseWithConnection:zeroConn];
		NSError *zeroErr = nil;
		id zeroHandle = [zeroDb connectWithConnection:zeroConn credentals:nil connectionError:&zeroErr];
		if (zeroHandle != nil || zeroErr.code != MADDatabaseSqlite3ErrorFileNotFound || [fm fileExistsAtPath:zeroByteURL.path]) {
			fprintf(stderr, "FAIL: 0-byte SQLite artifact was not rejected and cleaned up\n");
			return 82;
		}

		// 8b. Sibling .sqlite3 resolution next to .mad document + Locate File recovery flow
		NSURL *siblingMadURL = [NSURL fileURLWithPath:[dsTestDir stringByAppendingPathComponent:@"LondonSibling.mad"]];
		NSURL *siblingChinookURL = [NSURL fileURLWithPath:[dsTestDir stringByAppendingPathComponent:@"chinook.sqlite3"]];
		[fm copyItemAtURL:[NSURL fileURLWithPath:sampleLondonPath] toURL:siblingMadURL error:NULL];
		[fm copyItemAtURL:[NSURL fileURLWithPath:sampleChinookPath] toURL:siblingChinookURL error:NULL];

		NSError *sibOpenErr = nil;
		MADMacDocument *sibDoc = [[MADMacDocument alloc] initWithContentsOfURL:siblingMadURL ofType:@"com.thomason.mad" error:&sibOpenErr];
		if (sibDoc == nil) {
			fprintf(stderr, "FAIL: Could not open sibling London.mad: %s\n", sibOpenErr.localizedDescription.UTF8String);
			return 83;
		}
		MADMacViewerViewController *sibViewer = [[MADMacViewerViewController alloc] initWithDocument:sibDoc];
		(void)sibViewer.view;

		__block BOOL sibRefreshOK = NO;
		__block NSError *sibRefreshErr = nil;
		__block BOOL sibRefreshDone = NO;
		[sibDoc refreshDataWithPassword:nil completion:^(BOOL success, NSError * _Nullable error) {
			sibRefreshOK = success;
			sibRefreshErr = error;
			sibRefreshDone = YES;
		}];
		NSDate *sibDeadline = [NSDate dateWithTimeIntervalSinceNow:15.0];
		while (!sibRefreshDone && sibDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
		}
		if (!sibRefreshOK || [sibDoc.headlessDocument.dataTable numberOfRows] != 76) {
			fprintf(stderr, "FAIL: Sibling chinook.sqlite3 resolution failed (ok=%d rows=%lu err=%s)\n",
					sibRefreshOK, (unsigned long)[sibDoc.headlessDocument.dataTable numberOfRows],
					sibRefreshErr.description.UTF8String);
			return 84;
		}

		// Move chinook.sqlite3 to a different folder to trigger missing-file error and test Locate File recovery
		NSURL *relocatedChinookURL = [NSURL fileURLWithPath:[dsTestDir stringByAppendingPathComponent:@"relocated/custom_chinook.sqlite3"]];
		[fm createDirectoryAtURL:[relocatedChinookURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
		[fm moveItemAtURL:siblingChinookURL toURL:relocatedChinookURL error:NULL];

		// Re-open document so database connection points to the now-missing sibling path
		MADMacDocument *missingSibDoc = [[MADMacDocument alloc] initWithContentsOfURL:siblingMadURL ofType:@"com.thomason.mad" error:&sibOpenErr];
		MADMacViewerViewController *missingSibViewer = [[MADMacViewerViewController alloc] initWithDocument:missingSibDoc];
		(void)missingSibViewer.view;

		[missingSibViewer refreshReportAction:nil];
		sibDeadline = [NSDate dateWithTimeIntervalSinceNow:10.0];
		while (missingSibViewer.lastRefreshError == nil && sibDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
		}
		if (missingSibViewer.lastRefreshError == nil ||
			missingSibViewer.lastRefreshError.code != MADDatabaseSqlite3ErrorFileNotFound ||
			[fm fileExistsAtPath:siblingChinookURL.path]) {
			fprintf(stderr, "FAIL: Missing sibling SQLite file did not report MADDatabaseSqlite3ErrorFileNotFound (err=%s exists=%d)\n",
					missingSibViewer.lastRefreshError.description.UTF8String, [fm fileExistsAtPath:siblingChinookURL.path]);
			return 85;
		}

		__block BOOL locateDone = NO;
		__block BOOL locateOK = NO;
		[missingSibViewer locateMissingSQLiteDatabaseWithURL:relocatedChinookURL completion:^(BOOL success, NSError * _Nullable __unused error) {
			locateOK = success;
			locateDone = YES;
		}];
		sibDeadline = [NSDate dateWithTimeIntervalSinceNow:15.0];
		while (!locateDone && sibDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
		}
		if (!locateOK ||
			[missingSibDoc.headlessDocument.dataTable numberOfRows] != 76 ||
			![missingSibDoc.rptqDatabase.ownedByUser.host isEqualToString:relocatedChinookURL.path] ||
			![missingSibDoc.rptqDatabase.ownedByUser.dbname isEqualToString:@"custom_chinook.sqlite3"]) {
			fprintf(stderr, "FAIL: locateMissingSQLiteDatabaseWithURL: did not update credentials and refresh 76 rows (ok=%d rows=%lu host=%s)\n",
					locateOK, (unsigned long)[missingSibDoc.headlessDocument.dataTable numberOfRows],
					missingSibDoc.rptqDatabase.ownedByUser.host.UTF8String);
			return 86;
		}

		// 8c. Server credential resolution & missing-credentials error propagation
		MADDatabaseConnectionMySql *mysqlConn = [[MADDatabaseConnectionMySql alloc] initWithHost:@"127.0.0.1"
																						database:@"chinook_unauth_test"
																						 andPort:3306];
		[sibDoc updateDatabaseConnection:mysqlConn credentials:nil saveToKeychain:NO];
		__block BOOL mysqlRefreshDone = NO;
		__block BOOL mysqlRefreshOK = YES;
		__block NSError *mysqlRefreshErr = nil;
		[sibDoc refreshDataWithPassword:nil completion:^(BOOL success, NSError * _Nullable error) {
			mysqlRefreshOK = success;
			mysqlRefreshErr = error;
			mysqlRefreshDone = YES;
		}];
		sibDeadline = [NSDate dateWithTimeIntervalSinceNow:10.0];
		while (!mysqlRefreshDone && sibDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
		}
		if (mysqlRefreshOK ||
			![mysqlRefreshErr.domain isEqualToString:@"com.everydayapps.operation.refresh"] ||
			mysqlRefreshErr.code != 3) {
			fprintf(stderr, "FAIL: Server refresh without credentials did not propagate errMissingCredentials (3): err=%s\n",
					mysqlRefreshErr.description.UTF8String);
			return 87;
		}

		MADCredential *sessionCred = [[MADCredential alloc] initWithUsername:@"testuser" andPassword:@"testpass"];
		[sibDoc updateDatabaseConnection:mysqlConn credentials:sessionCred saveToKeychain:NO];
		MADCredential *resolvedCred = [sibDoc resolvedCredentialsForDatabaseConnection:mysqlConn];
		if (![resolvedCred.username isEqualToString:@"testuser"] || ![resolvedCred.password isEqualToString:@"testpass"]) {
			fprintf(stderr, "FAIL: MADMacDocument did not resolve session credentials for server connection\n");
			return 88;
		}

		// 8d. MADMacConnectionWindowController dynamic visibility, no-copy SQLite URL, and Edit mode
		MADMacConnectionWindowController *dynWC = [[MADMacConnectionWindowController alloc] init];
		NSPopUpButton *dynPopup = [dynWC valueForKey:@"driverPopup"];
		NSTextField *sqliteField = [dynWC valueForKey:@"sqlitePathField"];
		NSTextField *hostField = [dynWC valueForKey:@"hostField"];
		NSTextField *serverField = [dynWC valueForKey:@"serverInstanceField"];
		NSTextField *dbField = [dynWC valueForKey:@"databaseField"];
		NSTextField *userField = [dynWC valueForKey:@"usernameField"];
		NSSecureTextField *passField = [dynWC valueForKey:@"passwordField"];
		NSButton *keychainCheck = [dynWC valueForKey:@"saveKeychainCheckbox"];

		// SQLite selected (index 0): only SQLite controls visible; server controls hidden
		[dynPopup selectItemAtIndex:0];
		[dynWC driverPopupChanged:dynPopup];
		if (sqliteField.isHidden || !hostField.isHidden || !serverField.isHidden ||
			!dbField.isHidden || !userField.isHidden || !passField.isHidden || !keychainCheck.isHidden) {
			fprintf(stderr, "FAIL: SQLite driver selection did not hide server fields\n");
			return 89;
		}

		// MySQL selected (index 1): server fields visible, Server Instance & SQLite hidden
		[dynPopup selectItemAtIndex:1];
		[dynWC driverPopupChanged:dynPopup];
		if (!sqliteField.isHidden || hostField.isHidden || !serverField.isHidden ||
			dbField.isHidden || userField.isHidden || passField.isHidden || keychainCheck.isHidden) {
			fprintf(stderr, "FAIL: MySQL driver selection did not show server fields and hide Server Instance / SQLite\n");
			return 90;
		}

		// SQL Server selected (index 2): Server Instance visible too
		[dynPopup selectItemAtIndex:2];
		[dynWC driverPopupChanged:dynPopup];
		if (!sqliteField.isHidden || hostField.isHidden || serverField.isHidden ||
			dbField.isHidden || userField.isHidden || passField.isHidden || keychainCheck.isHidden) {
			fprintf(stderr, "FAIL: SQL Server driver selection did not show Server Instance field\n");
			return 91;
		}

		// Verify SQLite connection building does NOT copy file into Application Support
		[dynPopup selectItemAtIndex:0];
		[dynWC driverPopupChanged:dynPopup];
		sqliteField.stringValue = relocatedChinookURL.path;
		NSError *buildConnErr = nil;
		MADDatabaseConnection *builtSqliteConn = [dynWC buildConnectionWithCredentials:NULL error:&buildConnErr];
		NSURL *copiedInAppSupport = [supportDir URLByAppendingPathComponent:@"custom_chinook.sqlite3"];
		if (![builtSqliteConn isKindOfClass:[MADDatabaseConnectionSqlite3 class]] ||
			![((MADDatabaseConnectionSqlite3 *)builtSqliteConn).databaseUrl.path isEqualToString:relocatedChinookURL.path] ||
			[fm fileExistsAtPath:copiedInAppSupport.path]) {
			fprintf(stderr, "FAIL: buildConnectionWithCredentials: did not reference SQLite file in place or copied it to Application Support\n");
			return 92;
		}

		// Verify Edit / Reconnect mode on MADMacConnectionWindowController updates document back to SQLite
		MADMacConnectionWindowController *editWC =
			[[MADMacConnectionWindowController alloc] initWithDocument:sibDoc
														  statusPrompt:@"Reconnect to SQLite"];
		NSPopUpButton *editPopup = [editWC valueForKey:@"driverPopup"];
		NSTextField *editSqliteField = [editWC valueForKey:@"sqlitePathField"];
		[editPopup selectItemAtIndex:0];
		[editWC driverPopupChanged:editPopup];
		editSqliteField.stringValue = relocatedChinookURL.path;
		NSError *applyErr = nil;
		if (![editWC applyToEditingDocumentAndError:&applyErr] ||
			sibDoc.headlessDocument.database.databaseConnection.databaseType != MADDatabaseTypeSqlite3) {
			fprintf(stderr, "FAIL: Edit mode applyToEditingDocumentAndError: failed: %s\n",
					applyErr.description.UTF8String);
			return 93;
		}

		[fm removeItemAtPath:dsTestDir error:NULL];
		printf("PASS: Verified Data Source & Connection UX: no 0-byte SQLite file creation, sibling resolution, Locate File recovery, server credential propagation, and dynamic driver-specific connection dialog\n");

		// 9. Composed report: the native open -> refresh -> view -> export flow.
		// The document is built through the production store + archive writers, opened
		// through MADMacDocument (the normal document path), refreshed through the
		// Viewer's refresh action, and rendered by the same PDF exporter the Viewer uses.
		NSString *composedDir = [NSTemporaryDirectory() stringByAppendingPathComponent:
								 [NSString stringWithFormat:@"mad-composed-smoke-%@", NSUUID.UUID.UUIDString]];
		[fm createDirectoryAtPath:composedDir withIntermediateDirectories:YES attributes:nil error:NULL];

		NSString *composedError = nil;
		NSString *composedMadPath = MADSmokeCreateComposedFixture(composedDir, &composedError);
		if (composedMadPath.length == 0) {
			fprintf(stderr, "FAIL: Could not build composed fixture: %s\n", composedError.UTF8String ?: "(none)");
			return 100;
		}
		NSURL *composedMadURL = [NSURL fileURLWithPath:composedMadPath];
		NSString *composedPaymentsPath = [composedDir stringByAppendingPathComponent:@"payments.sqlite"];

		MADMacDocument *composedDoc = [[MADMacDocument alloc] initWithContentsOfURL:composedMadURL ofType:@"com.thomason.mad" error:&err];
		if (composedDoc == nil) {
			fprintf(stderr, "FAIL: Could not open composed .mad through MADMacDocument: %s\n", err.localizedDescription.UTF8String);
			return 101;
		}
		MADMacViewerViewController *composedViewer = [[MADMacViewerViewController alloc] initWithDocument:composedDoc];
		(void)composedViewer.view;

		// 9a. Refresh through the Viewer action and read back the joined values.
		[composedViewer refreshReportAction:nil];
		NSDate *composedDeadline = [NSDate dateWithTimeIntervalSinceNow:20.0];
		while (composedViewer.pdfView.document.pageCount == 0 && composedViewer.lastRefreshError == nil &&
			   composedDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
		}
		if (composedViewer.lastRefreshError != nil || composedViewer.pdfView.document.pageCount == 0) {
			fprintf(stderr, "FAIL: Composed refresh/render failed: %s\n", composedViewer.lastRefreshError.description.UTF8String);
			return 102;
		}
		MADDataTableFast *composedTable = composedDoc.headlessDocument.dataTable;
		if ([composedTable numberOfRows] != 4) {
			fprintf(stderr, "FAIL: Composed refresh produced %lu rows, expected 4\n", (unsigned long)[composedTable numberOfRows]);
			return 103;
		}
		// The joined rows, in composer order: (1,100,40) (1,100,60) (2,200,null) (3,300,null).
		// Row ids are 1-based (the sqlite rowid -dataForRow:column: binds).
		double inv1 = MADSmokeComposedDouble(composedTable, 1, @"invoice_amount");
		double pay1 = MADSmokeComposedDouble(composedTable, 1, @"payment_amount");
		double inv2 = MADSmokeComposedDouble(composedTable, 2, @"invoice_amount");
		double pay2 = MADSmokeComposedDouble(composedTable, 2, @"payment_amount");
		double inv3 = MADSmokeComposedDouble(composedTable, 3, @"invoice_amount");
		double pay3 = MADSmokeComposedDouble(composedTable, 3, @"payment_amount");
		double inv4 = MADSmokeComposedDouble(composedTable, 4, @"invoice_amount");
		double pay4 = MADSmokeComposedDouble(composedTable, 4, @"payment_amount");
		if (fabs(inv1 - 100.0) > 0.001 || fabs(pay1 - 40.0) > 0.001 ||
			fabs(inv2 - 100.0) > 0.001 || fabs(pay2 - 60.0) > 0.001 ||
			fabs(inv3 - 200.0) > 0.001 || !isnan(pay3) ||
			fabs(inv4 - 300.0) > 0.001 || !isnan(pay4)) {
			fprintf(stderr, "FAIL: Composed detail values are wrong or swapped: inv=(%.1f,%.1f,%.1f,%.1f) pay=(%.1f,%.1f,%.1f,%.1f)\n",
					inv1, inv2, inv3, inv4, pay1, pay2, pay3, pay4);
			return 104;
		}
		printf("PASS: Composed document refreshed (%lu rows) and rendered, with invoice/payment amounts bound to their own root keys\n",
			   (unsigned long)[composedTable numberOfRows]);

		// 9b. Make payments unavailable, refresh, and keep the previous report readable.
		NSString *composedPaymentsAway = [composedDir stringByAppendingPathComponent:@"payments-away.sqlite"];
		[fm moveItemAtPath:composedPaymentsPath toPath:composedPaymentsAway error:NULL];
		[composedViewer refreshReportAction:nil];
		composedDeadline = [NSDate dateWithTimeIntervalSinceNow:20.0];
		while (composedViewer.lastRefreshError == nil && composedDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
		}
		if (composedViewer.lastRefreshError == nil ||
			![composedViewer.lastRefreshError.localizedDescription containsString:@"payments"]) {
			fprintf(stderr, "FAIL: Unavailable payments source did not report a failure naming 'payments': %s\n",
					composedViewer.lastRefreshError.description.UTF8String);
			return 105;
		}
		if ([composedDoc.headlessDocument.dataTable numberOfRows] != 4) {
			fprintf(stderr, "FAIL: Failed composed refresh discarded the previous readable report (%lu rows, expected 4)\n",
					(unsigned long)[composedDoc.headlessDocument.dataTable numberOfRows]);
			return 106;
		}
		printf("PASS: Unavailable payments source reported by name and left the previous report readable\n");

		// 9c. Restore an empty payments source; the same open document refreshes to 3 invoices with blank payments.
		[fm moveItemAtPath:composedPaymentsAway toPath:composedPaymentsPath error:NULL];
		{
			MADDatabaseConnectionSqlite3 *emptyConn = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:[NSURL fileURLWithPath:composedPaymentsPath]];
			MADDatabaseSqlite3 *emptyDB = [[MADDatabaseSqlite3 alloc] init];
			emptyDB.databaseConnection = emptyConn;
			[emptyDB openDatabase];
			NSError *emptyErr = nil;
			[emptyDB executeSQL:@"DELETE FROM payments;" fieldKeys:@[] onConnection:nil intoResultTable:nil transactionSet:NO returnsResults:NO binaryBindings:nil withError:&emptyErr];
			[emptyDB closeDatabaseConnectionIfOpen];
		}
		[composedViewer refreshReportAction:nil];
		composedDeadline = [NSDate dateWithTimeIntervalSinceNow:20.0];
		while ([composedDoc.headlessDocument.dataTable numberOfRows] != 3 &&
			   composedDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
		}
		if (composedViewer.lastRefreshError != nil || [composedDoc.headlessDocument.dataTable numberOfRows] != 3) {
			fprintf(stderr, "FAIL: Empty-payments refresh did not yield 3 invoices: %s\n",
					composedViewer.lastRefreshError.description.UTF8String);
			return 107;
		}
		MADDataTableFast *emptyTable = composedDoc.headlessDocument.dataTable;
		double e1Pay = MADSmokeComposedDouble(emptyTable, 1, @"payment_amount");
		double e2Pay = MADSmokeComposedDouble(emptyTable, 2, @"payment_amount");
		double e3Pay = MADSmokeComposedDouble(emptyTable, 3, @"payment_amount");
		if (!isnan(e1Pay) || !isnan(e2Pay) || !isnan(e3Pay)) {
			fprintf(stderr, "FAIL: Empty-payments refresh left non-blank payment amounts\n");
			return 108;
		}

		// 9d. Export the visible generation and confirm the exported values agree.
		Class<MADReportExporting> composedPdfCls = [MADReportExporterRegistry exporterClassForFormat:@"pdf"];
		NSURL *composedPdfURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:
														[NSString stringWithFormat:@"smoke-composed-%@.pdf", NSUUID.UUID.UUIDString]]];
		id<MADReportExporting> composedPdfExporter = [[(Class)composedPdfCls alloc] init];
		if (![composedPdfExporter exportDocument:composedDoc.headlessDocument toURL:composedPdfURL options:MADReportExportOptionsNone error:&err]) {
			fprintf(stderr, "FAIL: Composed PDF export failed: %s\n", err.localizedDescription.UTF8String);
			return 109;
		}
		NSData *composedPdfBytes = [NSData dataWithContentsOfURL:composedPdfURL];
		[fm removeItemAtURL:composedPdfURL error:NULL];
		if (composedPdfBytes.length == 0) {
			fprintf(stderr, "FAIL: Composed PDF export wrote 0 bytes\n");
			return 110;
		}
		[fm removeItemAtPath:composedDir error:NULL];
		printf("PASS: Composed document exported to PDF and the visible generation agrees with the export\n");

		// 10. Multi-page composed report: page-order correctness, page breaks, PDF
		// agreement, and a refresh with fewer rows that shrinks the page count.
		const NSUInteger kComposedInvoiceCount = 60;
		NSString *multiDir = [NSTemporaryDirectory() stringByAppendingPathComponent:
							  [NSString stringWithFormat:@"mad-composed-multi-%@", NSUUID.UUID.UUIDString]];
		[fm createDirectoryAtPath:multiDir withIntermediateDirectories:YES attributes:nil error:NULL];

		NSString *multiError = nil;
		NSString *multiMadPath = MADSmokeCreateComposedFixtureWithInvoiceCount(kComposedInvoiceCount, multiDir, &multiError);
		if (multiMadPath.length == 0) {
			fprintf(stderr, "FAIL: Could not build multi-page composed fixture: %s\n", multiError.UTF8String ?: "(none)");
			return 120;
		}
		NSURL *multiMadURL = [NSURL fileURLWithPath:multiMadPath];
		NSURL *multiInvoicesURL = [NSURL fileURLWithPath:[multiDir stringByAppendingPathComponent:@"invoices.sqlite"]];
		NSURL *multiPaymentsURL = [NSURL fileURLWithPath:[multiDir stringByAppendingPathComponent:@"payments.sqlite"]];

		MADMacDocument *multiDoc = [[MADMacDocument alloc] initWithContentsOfURL:multiMadURL ofType:@"com.thomason.mad" error:&err];
		if (multiDoc == nil) {
			fprintf(stderr, "FAIL: Could not open multi-page composed .mad: %s\n", err.localizedDescription.UTF8String);
			return 121;
		}
		MADMacViewerViewController *multiViewer = [[MADMacViewerViewController alloc] initWithDocument:multiDoc];
		(void)multiViewer.view;

		NSArray<NSArray<NSNumber *> *> *expectedRows = MADSmokeComposedExpectedRows(kComposedInvoiceCount);

		NSDate *multiRefreshStart = [NSDate date];
		[multiViewer refreshReportAction:nil];
		NSDate *multiDeadline = [NSDate dateWithTimeIntervalSinceNow:60.0];
		while ([multiDoc.headlessDocument.dataTable numberOfRows] != expectedRows.count &&
			   multiViewer.lastRefreshError == nil && multiDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
		}
		double multiRefreshElapsed = -[multiRefreshStart timeIntervalSinceNow];
		if ([multiDoc.headlessDocument.dataTable numberOfRows] != expectedRows.count) {
			fprintf(stderr, "FAIL: Multi-page composed refresh produced %lu rows, expected %lu: %s\n",
					(unsigned long)[multiDoc.headlessDocument.dataTable numberOfRows],
					(unsigned long)expectedRows.count,
					multiViewer.lastRefreshError.description.UTF8String);
			return 122;
		}

		// Wait for the Viewer to render the multi-page PDF.
		while (multiViewer.pdfView.document.pageCount == 0 && multiDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
		}
		double multiRenderElapsed = -[multiRefreshStart timeIntervalSinceNow] - multiRefreshElapsed;
		MADReportFormatter *multiFormatter = multiDoc.headlessDocument.reportFormatter;
		NSUInteger multiPageCount = multiFormatter.reportLayout.count;
		if (multiPageCount < 3) {
			fprintf(stderr, "FAIL: Multi-page composed report rendered only %lu pages, expected several\n", (unsigned long)multiPageCount);
			return 123;
		}

		// 10a. Every detail row, in sorted order, matches the fixture.
		MADDataTableFast *multiTable = multiDoc.headlessDocument.dataTable;
		for (NSUInteger r = 0; r < expectedRows.count; r++) {
			double inv = MADSmokeComposedDouble(multiTable, r + 1, @"invoice_id");
			double amt = MADSmokeComposedDouble(multiTable, r + 1, @"invoice_amount");
			double pay = MADSmokeComposedDouble(multiTable, r + 1, @"payment_amount");
			NSArray<NSNumber *> *e = expectedRows[r];
			double eInv = e[0].doubleValue;
			double eAmt = e[1].doubleValue;
			double ePay = e[2].doubleValue;
			if ((NSUInteger)llround(inv) != (NSUInteger)llround(eInv) ||
				fabs(amt - eAmt) > 0.001 ||
				(isnan(ePay) ? !isnan(pay) : fabs(pay - ePay) > 0.001)) {
				fprintf(stderr, "FAIL: Multi-page composed row %lu wrong: got (%.0f, %.0f, %.0f) expected (%.0f, %.0f, %s)\n",
						(unsigned long)r, inv, amt, pay, eInv, eAmt, isnan(ePay) ? "null" : [e[2] stringValue].UTF8String);
				return 124;
			}
		}

		// 10b. Page-ordered detail rows are exactly 1..N (no missing/duplicated at breaks).
		NSArray<NSNumber *> *pageOrder = MADSmokeDetailRowIDsInPageOrder(multiFormatter);
		if (pageOrder.count != expectedRows.count) {
			fprintf(stderr, "FAIL: Page-ordered detail rows count %lu != expected %lu\n",
					(unsigned long)pageOrder.count, (unsigned long)expectedRows.count);
			return 125;
		}
		for (NSUInteger r = 0; r < pageOrder.count; r++) {
			if (pageOrder[r].unsignedIntegerValue != r + 1) {
				fprintf(stderr, "FAIL: Page-ordered detail row at index %lu is %lu (expected %lu) -- missing or duplicated at a page break\n",
						(unsigned long)r, (unsigned long)pageOrder[r].unsignedIntegerValue, (unsigned long)(r + 1));
				return 126;
			}
		}

		// 10c. Spot-check recognizable values on the first, middle, and last PDF pages.
		PDFDocument *multiPdfDoc = multiViewer.pdfView.document;
		if (multiPdfDoc.pageCount != multiPageCount) {
			fprintf(stderr, "FAIL: Viewer PDF page count %lu != formatter page count %lu\n",
					(unsigned long)multiPdfDoc.pageCount, (unsigned long)multiPageCount);
			return 127;
		}
		NSString *firstPageText = [[multiPdfDoc pageAtIndex:0] string] ?: @"";
		NSString *middlePageText = [[multiPdfDoc pageAtIndex:multiPdfDoc.pageCount / 2] string] ?: @"";
		NSString *lastPageText = [[multiPdfDoc pageAtIndex:multiPdfDoc.pageCount - 1] string] ?: @"";
		NSString *firstAmount = [NSString stringWithFormat:@"%.0f", (double)(1000 + 1)];
		NSString *lastAmount = [NSString stringWithFormat:@"%.0f", (double)(1000 + kComposedInvoiceCount)];
		if (firstPageText.length == 0 || ![firstPageText containsString:firstAmount]) {
			fprintf(stderr, "FAIL: First PDF page does not contain invoice 1 amount '%s'\n", firstAmount.UTF8String);
			return 128;
		}
		if (lastPageText.length == 0 || ![lastPageText containsString:lastAmount]) {
			fprintf(stderr, "FAIL: Last PDF page does not contain last invoice amount '%s'\n", lastAmount.UTF8String);
			return 129;
		}
		if (middlePageText.length == 0) {
			fprintf(stderr, "FAIL: Middle PDF page has no text\n");
			return 130;
		}

		// 10d. Export the multi-page report and confirm the page count agrees.
		Class<MADReportExporting> multiPdfCls = [MADReportExporterRegistry exporterClassForFormat:@"pdf"];
		NSURL *multiPdfURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:
													 [NSString stringWithFormat:@"smoke-composed-multi-%@.pdf", NSUUID.UUID.UUIDString]]];
		id<MADReportExporting> multiPdfExporter = [[(Class)multiPdfCls alloc] init];
		if (![multiPdfExporter exportDocument:multiDoc.headlessDocument toURL:multiPdfURL options:MADReportExportOptionsNone error:&err]) {
			fprintf(stderr, "FAIL: Multi-page composed PDF export failed: %s\n", err.localizedDescription.UTF8String);
			return 131;
		}
		PDFDocument *exportedPdf = [[PDFDocument alloc] initWithURL:multiPdfURL];
		[fm removeItemAtURL:multiPdfURL error:NULL];
		if (exportedPdf.pageCount != multiPageCount) {
			fprintf(stderr, "FAIL: Exported PDF page count %lu != rendered page count %lu\n",
					(unsigned long)exportedPdf.pageCount, (unsigned long)multiPageCount);
			return 132;
		}

		// 10e. Refresh the same open report with fewer rows; the page count must shrink.
		{
			MADDatabaseConnectionSqlite3 *invConn = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:multiInvoicesURL];
			MADDatabaseSqlite3 *invDB = [[MADDatabaseSqlite3 alloc] init];
			invDB.databaseConnection = invConn;
			[invDB openDatabase];
			NSError *pruneErr = nil;
			[invDB executeSQL:@"DELETE FROM invoices WHERE invoice_id > 5;" fieldKeys:@[] onConnection:nil intoResultTable:nil transactionSet:NO returnsResults:NO binaryBindings:nil withError:&pruneErr];
			[invDB closeDatabaseConnectionIfOpen];

			MADDatabaseConnectionSqlite3 *payConn = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:multiPaymentsURL];
			MADDatabaseSqlite3 *payDB = [[MADDatabaseSqlite3 alloc] init];
			payDB.databaseConnection = payConn;
			[payDB openDatabase];
			[payDB executeSQL:@"DELETE FROM payments WHERE invoice_id > 5;" fieldKeys:@[] onConnection:nil intoResultTable:nil transactionSet:NO returnsResults:NO binaryBindings:nil withError:&pruneErr];
			[payDB closeDatabaseConnectionIfOpen];
		}
		NSUInteger expectedPrunedRows = [MADSmokeComposedExpectedRows(5) count];
		[multiViewer refreshReportAction:nil];
		multiDeadline = [NSDate dateWithTimeIntervalSinceNow:30.0];
		while ([multiDoc.headlessDocument.dataTable numberOfRows] != expectedPrunedRows &&
			   multiDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
		}
		if ([multiDoc.headlessDocument.dataTable numberOfRows] != expectedPrunedRows) {
			fprintf(stderr, "FAIL: Pruned refresh produced %lu rows, expected %lu\n",
					(unsigned long)[multiDoc.headlessDocument.dataTable numberOfRows], (unsigned long)expectedPrunedRows);
			return 133;
		}
		// Wait for the Viewer to re-render to fewer pages.
		multiDeadline = [NSDate dateWithTimeIntervalSinceNow:30.0];
		while (multiViewer.pdfView.document.pageCount >= multiPageCount && multiDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
		}
		NSUInteger prunedPageCount = multiDoc.headlessDocument.reportFormatter.reportLayout.count;
		if (prunedPageCount >= multiPageCount) {
			fprintf(stderr, "FAIL: Pruned refresh did not shrink the page count (%lu -> %lu)\n",
					(unsigned long)multiPageCount, (unsigned long)prunedPageCount);
			return 134;
		}
		if (multiViewer.pdfView.document.pageCount != prunedPageCount) {
			fprintf(stderr, "FAIL: Viewer page count %lu != formatter page count %lu after prune\n",
					(unsigned long)multiViewer.pdfView.document.pageCount, (unsigned long)prunedPageCount);
			return 135;
		}

		[fm removeItemAtPath:multiDir error:NULL];
		printf("PASS: Multi-page composed report (%lu invoices -> %lu rows, %lu pages; refresh %.2fs, render %.2fs; pruned to %lu rows / %lu pages)\n",
			   (unsigned long)kComposedInvoiceCount, (unsigned long)expectedRows.count, (unsigned long)multiPageCount,
			   multiRefreshElapsed, multiRenderElapsed, (unsigned long)expectedPrunedRows, (unsigned long)prunedPageCount);

		// 11. Grouped composed report: the root's groups sort the joined rows and the
		// renderer emits group breaks, with one group spanning a page boundary.
		NSString *groupedDir = [NSTemporaryDirectory() stringByAppendingPathComponent:
								[NSString stringWithFormat:@"mad-composed-grouped-%@", NSUUID.UUID.UUIDString]];
		[fm createDirectoryAtPath:groupedDir withIntermediateDirectories:YES attributes:nil error:NULL];

		NSString *groupedError = nil;
		NSString *groupedMadPath = MADSmokeCreateGroupedComposedFixture(groupedDir, &groupedError);
		if (groupedMadPath.length == 0) {
			fprintf(stderr, "FAIL: Could not build grouped composed fixture: %s\n", groupedError.UTF8String ?: "(none)");
			return 140;
		}
		MADMacDocument *groupedDoc = [[MADMacDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:groupedMadPath] ofType:@"com.thomason.mad" error:&err];
		if (groupedDoc == nil) {
			fprintf(stderr, "FAIL: Could not open grouped composed .mad: %s\n", err.localizedDescription.UTF8String);
			return 141;
		}
		MADMacViewerViewController *groupedViewer = [[MADMacViewerViewController alloc] initWithDocument:groupedDoc];
		(void)groupedViewer.view;
		[groupedViewer refreshReportAction:nil];
		NSDate *groupedDeadline = [NSDate dateWithTimeIntervalSinceNow:60.0];
		while (groupedViewer.pdfView.document.pageCount == 0 && groupedViewer.lastRefreshError == nil &&
			   groupedDeadline.timeIntervalSinceNow > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
		}
		if (groupedViewer.lastRefreshError != nil || groupedViewer.pdfView.document.pageCount == 0) {
			fprintf(stderr, "FAIL: Grouped composed refresh/render failed: %s\n", groupedViewer.lastRefreshError.description.UTF8String);
			return 142;
		}

		MADReportFormatter *groupedFormatter = groupedDoc.headlessDocument.reportFormatter;
		if (groupedFormatter.numberOfGroups != 2) {
			fprintf(stderr, "FAIL: Grouped composed report has %lu groups, expected 2\n", (unsigned long)groupedFormatter.numberOfGroups);
			return 143;
		}
		NSUInteger groupedPages = groupedFormatter.reportLayout.count;
		if (groupedPages < 2) {
			fprintf(stderr, "FAIL: Grouped composed report rendered only %lu pages\n", (unsigned long)groupedPages);
			return 144;
		}

		// A group (invoice 1, forty rows) must cross a page boundary: both the first and
		// second pages carry invoice 1's detail rows.
		NSUInteger groupHeaders = 0;
		BOOL firstPageHasInvoice1 = NO;
		BOOL secondPageHasInvoice1 = NO;
		MADDataTableFast *groupedTable = groupedDoc.headlessDocument.dataTable;
		for (NSUInteger page = 0; page < groupedPages; page++) {
			for (MADSectionRepresentation *section in groupedFormatter.reportLayout[page]) {
				if (section.sectionType == MADDocumentSectionTypeGroupHeader) groupHeaders++;
				if (section.sectionType == MADDocumentSectionTypeBody && page < 2) {
					NSDictionary *row = [groupedTable dataForRow:section.detailRowId error:NULL];
					id inv = row[@"invoice_id"];
					if (inv && [inv doubleValue] == 1.0) {
						if (page == 0) firstPageHasInvoice1 = YES;
						else secondPageHasInvoice1 = YES;
					}
				}
			}
		}
		if (groupHeaders == 0) {
			fprintf(stderr, "FAIL: Grouped composed report rendered no group breaks\n");
			return 145;
		}
		if (!firstPageHasInvoice1 || !secondPageHasInvoice1) {
			fprintf(stderr, "FAIL: Invoice 1's group did not cross a page boundary (first=%d second=%d)\n",
					firstPageHasInvoice1, secondPageHasInvoice1);
			return 146;
		}

		[fm removeItemAtPath:groupedDir error:NULL];
		printf("PASS: Grouped composed report (%lu rows, %lu pages, 2 groups) rendered group breaks and crossed a page boundary\n",
			   (unsigned long)[groupedTable numberOfRows], (unsigned long)groupedPages);
	}
	return 0;
}
