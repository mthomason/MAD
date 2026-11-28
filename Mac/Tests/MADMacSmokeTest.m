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
#import "MADMacTipBar.h"
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
#import <MADPostgres/MADDatabaseConnectionPostgres.h>
#import <MADTdsClient/MADDatabaseConnectionSQLServer.h>
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

// Refreshes a composed document through the Viewer's own action and waits for the
// expected row count (or a refresh error).
static BOOL MADSmokeRefreshComposed(MADMacDocument *doc, MADMacViewerViewController *viewer, NSUInteger expectedRows) {
	[viewer refreshReportAction:nil];
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:30.0];
	while ([doc.headlessDocument.dataTable numberOfRows] != expectedRows &&
		   viewer.lastRefreshError == nil && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
	return [doc.headlessDocument.dataTable numberOfRows] == expectedRows && viewer.lastRefreshError == nil;
}

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

// Builds an ordinary single-query `.mad` (a standard report) over `sourceURL`: one
// database, its credential, one schema table with `fieldNames`, and one query with a
// query table and field per schema field. No root, no output keys -- a plain report.
static NSString *MADSmokeBuildStandardReport(NSURL *sourceURL, NSURL *madURL, NSString *tableName,
											 NSArray<NSString *> *fieldNames, NSString **outError) {
	NSFileManager *fm = [NSFileManager defaultManager];
	MADDocumentStore *store = [MADDocumentStore storeForDocumentURL:madURL];
	[fm removeItemAtURL:store.gutsURL error:NULL];
	NSError *error = nil;
	if (![store openWithError:&error]) { if (outError) *outError = error.localizedDescription; return nil; }
	RptqStoreContext *context = store.context;
	[context loadAllWithError:NULL];

	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	RptqObject *credential = [context insertObjectForEntity:@"RptqDatabaseCredentals" identifier:0];
	[credential setValue:sourceURL.lastPathComponent forKey:@"dbname"];
	[credential setValue:sourceURL.path forKey:@"host"];
	[database setValue:credential forKey:@"ownedByUser"];

	RptqObject *schemaTable = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	[schemaTable setValue:tableName forKey:@"name"];
	NSMutableArray *schemaFields = [NSMutableArray array];
	int64_t fieldId = 20;
	for (NSString *fieldName in fieldNames) {
		RptqObject *schemaField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:fieldId++];
		[schemaField setValue:fieldName forKey:@"name"];
		[schemaFields addObject:schemaField];
	}
	[database setValue:@[schemaTable] forKey:@"hasTables"];
	[schemaTable setValue:schemaFields forKey:@"hasFields"];

	RptqObject *query = [context insertObjectForEntity:@"RptqQuery" identifier:100];
	[database setValue:@[query] forKey:@"hasQueries"];
	RptqObject *queryTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:200];
	[queryTable setValue:schemaTable forKey:@"databaseSchemaTable"];
	[queryTable setValue:query forKey:@"inQuery"];
	NSMutableArray *queryFields = [NSMutableArray array];
	for (RptqObject *schemaField in schemaFields) {
		RptqObject *field = [context insertObjectForEntity:@"RptqQueryField" identifier:0];
		[field setValue:schemaField forKey:@"databaseSchemaField"];
		[field setValue:queryTable forKey:@"inQueryTable"];
		[queryFields addObject:field];
	}
	[queryTable setValue:queryFields forKey:@"hasQueryFields"];
	[document setValue:@[database] forKey:@"hasDatabaseSchemas"];

	if (![context save:&error]) { if (outError) *outError = error.localizedDescription; [store close]; return nil; }
	[store close];
	MADArchiveManager *writer = [[MADArchiveManager alloc] initWithFileWrapperURL:store.gutsURL archiveURL:madURL];
	writer.composed = NO;
	if (![writer archive:YES]) { if (outError) *outError = @"archive failed"; return nil; }
	return madURL.path;
}

// Builds a composed invoices/payments fixture whose payments source has an authored
// layout, opens it, and returns the document (its window controller is already made).
// Test-only; the smoke run below does the same authoring in its per-node section.
static MADMacDocument *MADSmokeNodeFixtureDocument(NSString *directory) {
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSString *errorText = nil;
	NSString *madPath = MADSmokeCreateComposedFixture(directory, &errorText);
	if (madPath.length == 0) {
		fprintf(stderr, "Could not build the node fixture: %s\n", errorText.UTF8String ?: "(none)");
		return nil;
	}
	NSError *error = nil;
	NSURL *madURL = [NSURL fileURLWithPath:madPath];
	MADMacDocument *doc = [[MADMacDocument alloc] initWithContentsOfURL:madURL
																 ofType:@"com.thomason.mad"
																  error:&error];
	if (doc == nil) {
		fprintf(stderr, "Could not open the node fixture: %s\n", error.localizedDescription.UTF8String);
		return nil;
	}
	[doc makeWindowControllers];
	MADMacWindowController *wc = doc.windowControllers.firstObject;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];

	RptqQuery *payments = nil;
	for (RptqQuery *query in [doc allQueries]) {
		if ([query.name isEqualToString:@"payments"]) { payments = query; break; }
	}
	if (payments == nil) return nil;
	doc.selectedQuery = payments;
	MADMacDesignerViewController *designer = wc.designerViewController;
	[designer reloadFromDocument];

	RptqDocumentSection *detail = nil;
	for (RptqDocumentSection *section in [doc orderedSections]) {
		if ((MADDocumentSectionType)section.type == MADDocumentSectionTypeBody) { detail = section; break; }
	}
	if (detail == nil) return nil;
	RptqDocumentElementLabel *label = [designer addStaticLabelInSection:detail atPoint:NSMakePoint(12.0, 6.0)];
	label.text = NSLocalizedString(@"Payments Source", @"Screenshot fixture: static label on the payments source's detail band.");
	RptqQueryField *amount = nil;
	for (RptqQueryTable *table in payments.hasQueryTables) {
		for (RptqQueryField *field in table.hasQueryFields) {
			if ([field.databaseSchemaField.name isEqualToString:@"amount"]) { amount = field; break; }
		}
	}
	if (amount != nil) {
		[designer addDataField:amount inSection:detail atPoint:NSMakePoint(12.0, 32.0)];
	}
	if (![doc.headlessDocument writeToURL:madURL reproducible:NO error:&error]) {
		fprintf(stderr, "Could not save the node fixture: %s\n", error.localizedDescription.UTF8String);
		return nil;
	}
	return doc;
}

static int MADSmokeWriteNodeFixture(NSString *directory) {
	MADMacDocument *doc = MADSmokeNodeFixtureDocument(directory);
	if (doc == nil) return 1;
	printf("%s\n", doc.fileURL.path.UTF8String);
	return 0;
}

// Renders a window's frame view (title bar, toolbar, and content) to a PNG.  AppKit's
// own snapshot path; it needs no Screen Recording permission.  Also writes a PDF of the
// view tree, which preserves vector/PDFView content a bitmap cache may miss.
static BOOL MADSmokeWriteWindowSnapshots(NSWindow *window, NSString *directory, NSString *name) {
	if (window == nil) return NO;
	[window layoutIfNeeded];
	NSView *target = window.contentView.superview ?: window.contentView;
	[target layoutSubtreeIfNeeded];
	[target displayIfNeeded];
	NSRect bounds = target.bounds;

	NSData *pdf = [target dataWithPDFInsideRect:bounds];
	if (pdf.length > 0) {
		NSString *pdfPath = [directory stringByAppendingPathComponent:
							 [name stringByAppendingPathExtension:@"pdf"]];
		[pdf writeToFile:pdfPath atomically:YES];
	}

	NSBitmapImageRep *rep = [target bitmapImageRepForCachingDisplayInRect:bounds];
	if (rep == nil) return NO;
	[target cacheDisplayInRect:bounds toBitmapImageRep:rep];
	NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
	NSString *pngPath = [directory stringByAppendingPathComponent:
						 [name stringByAppendingPathExtension:@"png"]];
	return [png writeToFile:pngPath atomically:YES];
}

// Drives the app's own window through the per-node states and writes PNG/PDF snapshots,
// for environments where screen capture is unavailable.  Test-only.
static int MADSmokeWriteNodeScreenshots(NSString *directory) {
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	// Install the menu bar so the inventory covers the whole command surface.
	(void)[NSApplication sharedApplication];
	MADMacAppDelegate *appDelegate = [[MADMacAppDelegate alloc] init];
	[appDelegate applicationWillFinishLaunching:[NSNotification notificationWithName:@"ui-screenshot" object:NSApp]];

	MADMacDocument *doc = MADSmokeNodeFixtureDocument(directory);
	if (doc == nil) return 1;
	MADMacWindowController *wc = doc.windowControllers.firstObject;
	NSWindow *window = wc.window;
	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:nil];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];

	NSString *pngDir = [directory stringByAppendingPathComponent:@"png"];
	[fm createDirectoryAtPath:pngDir withIntermediateDirectories:YES attributes:nil error:NULL];

	RptqQuery *root = doc.rootQuery;
	RptqQuery *payments = nil, *invoices = nil;
	for (RptqQuery *query in [doc allQueries]) {
		if ([query.name isEqualToString:@"payments"]) payments = query;
		if ([query.name isEqualToString:@"invoices"]) invoices = query;
	}
	if (root == nil || payments == nil || invoices == nil) return 1;

	doc.selectedQuery = root;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	MADSmokeWriteWindowSnapshots(window, pngDir, @"01-result-designer");

	doc.selectedQuery = payments;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	MADSmokeWriteWindowSnapshots(window, pngDir, @"02-payments-designer");

	MADMacViewerViewController *viewer = wc.viewerViewController;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[viewer refreshReportAction:nil];
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:30.0];
	while ([doc.headlessDocument.dataTable numberOfRows] != 4 &&
		   viewer.lastRefreshError == nil && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
	[viewer reloadPreview];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	MADSmokeWriteWindowSnapshots(window, pngDir, @"03-payments-viewer");

	doc.selectedQuery = invoices;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	MADSmokeWriteWindowSnapshots(window, pngDir, @"04-invoices-grid");

	doc.selectedQuery = root;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	MADSmokeWriteWindowSnapshots(window, pngDir, @"05-result-viewer");

	printf("%s\n", pngDir.UTF8String);
	[window orderOut:nil];
	return 0;
}

// Captures the audited macOS UI states and writes a text inventory of the menus,
// controls, and tooltips.  Test-only; used for the UI evidence.
static int MADSmokeWriteUIScreenshots(NSString *directory) {
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSString *pngDir = [directory stringByAppendingPathComponent:@"png"];
	[fm createDirectoryAtPath:pngDir withIntermediateDirectories:YES attributes:nil error:NULL];

	// Install the menu bar so the inventory covers the whole command surface.
	(void)[NSApplication sharedApplication];
	MADMacAppDelegate *appDelegate = [[MADMacAppDelegate alloc] init];
	[appDelegate applicationWillFinishLaunching:[NSNotification notificationWithName:@"ui-screenshot" object:NSApp]];

	MADMacDocument *doc = MADSmokeNodeFixtureDocument(directory);
	if (doc == nil) return 1;
	MADMacWindowController *wc = doc.windowControllers.firstObject;
	NSWindow *window = wc.window;
	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:nil];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];

	doc.selectedQuery = doc.rootQuery;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabQuery];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.4]];
	MADSmokeWriteWindowSnapshots(window, pngDir, @"after-query");

	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.4]];
	MADSmokeWriteWindowSnapshots(window, pngDir, @"after-designer");

	MADMacViewerViewController *viewer = wc.viewerViewController;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[viewer refreshReportAction:nil];
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:30.0];
	while ([doc.headlessDocument.dataTable numberOfRows] != 4 &&
		   viewer.lastRefreshError == nil && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
	[viewer reloadPreview];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.6]];
	MADSmokeWriteWindowSnapshots(window, pngDir, @"after-viewer");

	// The layout-less source shows the row grid and hides the page/zoom controls.
	RptqQuery *invoices = nil;
	for (RptqQuery *query in [doc allQueries]) {
		if ([query.name isEqualToString:@"invoices"]) { invoices = query; break; }
	}
	if (invoices != nil) {
		doc.selectedQuery = invoices;
		[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		MADSmokeWriteWindowSnapshots(window, pngDir, @"after-viewer-grid");
		doc.selectedQuery = doc.rootQuery;
	}

	// The native rename sheet.
	[wc presentRenameSheet:nil];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.6]];
	NSWindow *sheet = window.attachedSheet;
	if (sheet != nil) {
		MADSmokeWriteWindowSnapshots(sheet, pngDir, @"after-rename-sheet");
		[window endSheet:sheet returnCode:NSModalResponseCancel];
	}

	// A human-readable inventory of the command surface.
	NSMutableString *inventory = [[NSMutableString alloc] init];
	[inventory appendFormat:@"MAD Designer (macOS) UI inventory\n\n"];
	[inventory appendFormat:@"Workspace switcher: %@ / %@ / %@\n\n",
		[wc.workspaceSegmentedControl labelForSegment:0],
		[wc.workspaceSegmentedControl labelForSegment:1],
		[wc.workspaceSegmentedControl labelForSegment:2]];
	for (NSMenuItem *top in [NSApp mainMenu].itemArray) {
		NSMenu *menu = top.submenu;
		if (menu == nil) continue;
		[inventory appendFormat:@"%@\n", menu.title];
		for (NSMenuItem *item in menu.itemArray) {
			if (item.isSeparatorItem) continue;
			NSString *key = item.keyEquivalent.length > 0 ? item.keyEquivalent : @"";
			[inventory appendFormat:@"    %@%@", item.title, key.length > 0 ? [NSString stringWithFormat:@"  [%@]", key] : @""];
			if (item.submenu != nil) {
				NSMutableArray<NSString *> *children = [[NSMutableArray alloc] init];
				for (NSMenuItem *child in item.submenu.itemArray) {
					if (!child.isSeparatorItem) [children addObject:child.title];
				}
				[inventory appendFormat:@"  > %@", [children componentsJoinedByString:@", "]];
			}
			if (item.toolTip.length > 0) [inventory appendFormat:@"  — %@", item.toolTip];
			[inventory appendString:@"\n"];
		}
		[inventory appendString:@"\n"];
	}
	MADMacDesignerViewController *designer = wc.designerViewController;
	MADMacQueryViewController *queryVC = wc.queryViewController;
	[inventory appendFormat:@"Insert menu: %@\n", designer.insertPopUpButton.toolTip];
	for (NSMenuItem *item in designer.insertPopUpButton.menu.itemArray) {
		if (item.isSeparatorItem || item.tag == 0) continue;
		[inventory appendFormat:@"    %@ (tag %ld)\n", item.title, (long)item.tag];
	}
	[inventory appendFormat:@"\nQuery top bar: selector (%@), add menu (%@), actions menu (%@), connection (%@)\n",
		queryVC.selectedQuery.name ?: @"",
		[queryVC valueForKey:@"addMenuButton"] ? @"Add" : @"",
		[queryVC valueForKey:@"queryMenuButton"] ? @"Query" : @"",
		[queryVC valueForKey:@"connectionButton"] ? @"Database Connection" : @""];
	[inventory appendFormat:@"Viewer top bar: Refresh, Print…, Export…, More (%@)\n", viewer.overflowButton.toolTip];
	[inventory appendFormat:@"Viewer bottom bar: status line, zoom out/percentage/in, previous/page/next, paper size, rendered paper size\n"];
	[inventory appendFormat:@"Viewer controls hide in row-grid mode: %@\n", viewer.isShowingRowGrid ? @"yes (grid is visible)" : @"n/a in this state"];
	NSString *inventoryPath = [directory stringByAppendingPathComponent:@"ui-inventory.txt"];
	[inventory writeToFile:inventoryPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];

	printf("%s\n", pngDir.UTF8String);
	printf("%s\n", inventoryPath.UTF8String);
	[window orderOut:nil];
	return 0;
}

static NSString *MADSmokeStringForValue(id value) {
	if (value == nil || value == [NSNull null]) return @"";
	return [value isKindOfClass:[NSString class]] ? value : [value description];
}

// Builds one Standard Report through the app's own document/controller path against a
// live server: create the document (schema import), add a table, author a label + a
// bound data field, refresh, export PDF/HTML, and save.  Prints the Designer evidence
// (field count, caption, filter, table/alias case) and whether the bound value rendered.
static BOOL MADSmokeWriteLiveReport(NSString *name,
									NSString *tableName,
									NSString *boundFieldName,
									MADDatabaseConnection *connection,
									MADCredential *credential,
									NSString *directory,
									NSString **outError) {
	NSString *madPath = [directory stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"mad"]];
	NSURL *madURL = [NSURL fileURLWithPath:madPath];
	NSError *error = nil;
	MADHeadlessDocument *headless = [MADHeadlessDocument createDocumentAtURL:madURL
													   withDatabaseConnection:connection
																  credentials:credential
																		error:&error];
	if (headless == nil) {
		if (outError != NULL) {
			*outError = [NSString stringWithFormat:@"connect/create failed: %@ [%@ %ld]",
						 error.localizedDescription ?: @"?", error.domain ?: @"?", (long)error.code];
		}
		return NO;
	}

	MADMacDocument *doc = [[MADMacDocument alloc] init];
	doc.fileURL = madURL;
	[doc adoptHeadlessDocument:headless];
	doc.sessionCredentials = credential;
	[doc makeWindowControllers];
	MADMacWindowController *wc = doc.windowControllers.firstObject;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabQuery];
	MADMacQueryViewController *qvc = wc.queryViewController;

	RptqQuery *query = doc.reportQuery;
	if (query == nil) {
		if (outError != NULL) *outError = @"the created document has no query";
		return NO;
	}
	[doc renameQuery:query to:name];
	doc.selectedQuery = query;
	[qvc reloadFromDocument];

	RptqDatabaseSchemaTable *schemaTable = nil;
	for (RptqDatabaseSchemaTable *candidate in query.inDatabase.hasTables) {
		if (candidate.name.length == 0) continue;
		if ([candidate.name caseInsensitiveCompare:tableName] == NSOrderedSame ||
			[[candidate.name lowercaseString] hasSuffix:[tableName lowercaseString]]) {
			schemaTable = candidate;
			break;
		}
	}
	if (schemaTable == nil) {
		NSMutableString *names = [[NSMutableString alloc] init];
		for (RptqDatabaseSchemaTable *candidate in query.inDatabase.hasTables) {
			[names appendFormat:@" %@", candidate.name];
		}
		if (outError != NULL) {
			*outError = [NSString stringWithFormat:@"table '%@' not found; schema tables:%@", tableName, names];
		}
		return NO;
	}
	if ([qvc addSchemaTableToQuery:schemaTable] == nil) {
		if (outError != NULL) *outError = [NSString stringWithFormat:@"could not add table '%@'", schemaTable.name];
		return NO;
	}
	[doc notifyDocumentMutated];

	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	MADMacDesignerViewController *designer = wc.designerViewController;
	[designer reloadFromDocument];

	RptqQueryTable *queryTable = query.hasQueryTables.anyObject;
	RptqQueryField *bound = nil;
	for (RptqQueryField *field in queryTable.hasQueryFields) {
		if ([field.databaseSchemaField.name caseInsensitiveCompare:boundFieldName] == NSOrderedSame) {
			bound = field;
			break;
		}
	}
	if (bound == nil) bound = queryTable.hasQueryFields.anyObject;

	RptqDocumentSection *detail = nil;
	for (RptqDocumentSection *section in [doc orderedSections]) {
		if ((MADDocumentSectionType)section.type == MADDocumentSectionTypeBody) {
			detail = section;
			break;
		}
	}
	if (detail == nil || bound == nil) {
		if (outError != NULL) *outError = @"no detail band or no bindable field";
		return NO;
	}
	RptqDocumentElementLabel *label = [designer addStaticLabelInSection:detail atPoint:NSMakePoint(12.0, 6.0)];
	label.text = [NSString stringWithFormat:@"%@ Test", name];
	[designer addDataField:bound inSection:detail atPoint:NSMakePoint(12.0, 32.0)];
	[doc notifyDocumentMutated];

	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	[NSApp activateIgnoringOtherApps:YES];
	[wc.window makeKeyAndOrderFront:nil];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	MADSmokeWriteWindowSnapshots(wc.window, directory, [name stringByAppendingString:@"-Designer"]);

	MADMacViewerViewController *viewer = wc.viewerViewController;
	(void)viewer.view;
	[viewer refreshReportAction:nil];
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:90.0];
	while (!headless.refreshed && viewer.lastRefreshError == nil && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
	}
	if (!headless.refreshed || viewer.lastRefreshError != nil) {
		if (outError != NULL) {
			*outError = [NSString stringWithFormat:@"refresh failed: %@",
						 viewer.lastRefreshError.localizedDescription ?: @"not refreshed"];
		}
		[headless writeToURL:madURL reproducible:NO error:NULL];
		return NO;
	}

	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[viewer reloadPreview];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	MADSmokeWriteWindowSnapshots(wc.window, directory, [name stringByAppendingString:@"-Viewer"]);

	NSUInteger rows = [headless.dataTable numberOfRows];
	NSString *expectedValue = nil;
	NSUInteger scan = MIN(rows, 5);
	for (NSUInteger r = 1; r <= scan && expectedValue.length == 0; r++) {
		NSDictionary *row = [headless.dataTable dataForRow:r error:NULL];
		for (NSString *key in row) {
			if ([key rangeOfString:bound.databaseSchemaField.name options:NSCaseInsensitiveSearch].location != NSNotFound) {
				expectedValue = MADSmokeStringForValue(row[key]);
				if (expectedValue.length > 0) break;
			}
		}
	}

	NSURL *pdfURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:
											[name stringByAppendingPathExtension:@"pdf"]]];
	Class<MADReportExporting> pdfClass = [MADReportExporterRegistry exporterClassForFormat:@"pdf"];
	id<MADReportExporting> pdfExporter = [[(Class)pdfClass alloc] init];
	NSError *exportError = nil;
	BOOL pdfOK = [pdfExporter exportDocument:headless toURL:pdfURL options:MADReportExportOptionsNone error:&exportError];

	NSURL *htmlURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:
											 [name stringByAppendingPathExtension:@"html"]]];
	Class<MADReportExporting> htmlClass = [MADReportExporterRegistry exporterClassForFormat:@"html"];
	id<MADReportExporting> htmlExporter = [[(Class)htmlClass alloc] init];
	BOOL htmlOK = [htmlExporter exportDocument:headless toURL:htmlURL options:MADReportExportOptionsNone error:&exportError];
	NSString *html = htmlOK ? [NSString stringWithContentsOfURL:htmlURL encoding:NSUTF8StringEncoding error:NULL] : nil;
	BOOL rendered = expectedValue.length > 0 && html != nil && [html containsString:expectedValue];

	NSMutableString *tableEvidence = [[NSMutableString alloc] init];
	NSUInteger totalFields = 0;
	for (RptqQueryTable *table in query.hasQueryTables) {
		totalFields += table.hasQueryFields.count;
		[tableEvidence appendFormat:@" %@(alias=%@,queryAlias=%@)",
			table.databaseSchemaTable.name, table.alias ?: @"nil", [table queryAlias]];
	}

	[headless writeToURL:madURL reproducible:NO error:NULL];
	printf("LIVE %s: mad=%s pdf=%s html=%s fields=%lu tableRows=%ld caption='%s' search='%s' "
		   "isComposed=%d showsColumns=%d queryTables=%lu totalQueryFields=%lu tables:%s "
		   "bound=%s rows=%lu valueRendered=%d expected='%s' documentType='%s'\n",
		   name.UTF8String,
		   madPath.UTF8String,
		   pdfOK ? pdfURL.path.UTF8String : "<failed>",
		   htmlOK ? htmlURL.path.UTF8String : "<failed>",
		   (unsigned long)designer.displayedQueryFields.count,
		   (long)designer.queryFieldsTableView.numberOfRows,
		   designer.fieldsHeaderLabel.stringValue.UTF8String ?: "",
		   designer.queryFieldsSearchField.stringValue.UTF8String ?: "",
		   doc.isComposed,
		   [doc queryShowsReportColumns:query],
		   (unsigned long)query.hasQueryTables.count,
		   (unsigned long)totalFields,
		   tableEvidence.UTF8String ?: "",
		   ([NSString stringWithFormat:@"%@.%@", [bound.inQueryTable queryAlias], bound.databaseSchemaField.name]).UTF8String,
		   (unsigned long)rows,
		   rendered,
		   expectedValue.UTF8String ?: "",
		   wc.window.subtitle.UTF8String ?: "");
	if (!pdfOK || !htmlOK) {
		if (outError != NULL) {
			*outError = [NSString stringWithFormat:@"export failed: %@", exportError.localizedDescription ?: @"?"];
		}
		return NO;
	}
	return YES;
}

// Creates a live Standard Report whose query has a table but no authored layout, so it
// can be imported as the layout-less source of a composition.
static BOOL MADSmokeWriteLiveQueryOnlyReport(NSString *name,
											 NSString *tableName,
											 MADDatabaseConnection *connection,
											 MADCredential *credential,
											 NSString *directory,
											 NSString **outError) {
	NSString *madPath = [directory stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"mad"]];
	NSURL *madURL = [NSURL fileURLWithPath:madPath];
	NSError *error = nil;
	MADHeadlessDocument *headless = [MADHeadlessDocument createDocumentAtURL:madURL
													   withDatabaseConnection:connection
																  credentials:credential
																		error:&error];
	if (headless == nil) {
		if (outError != NULL) *outError = error.localizedDescription ?: @"create failed";
		return NO;
	}
	MADMacDocument *doc = [[MADMacDocument alloc] init];
	doc.fileURL = madURL;
	[doc adoptHeadlessDocument:headless];
	doc.sessionCredentials = credential;
	[doc makeWindowControllers];
	MADMacWindowController *wc = doc.windowControllers.firstObject;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabQuery];
	MADMacQueryViewController *qvc = wc.queryViewController;
	RptqQuery *query = doc.reportQuery;
	if (query == nil) {
		if (outError != NULL) *outError = @"no query";
		return NO;
	}
	[doc renameQuery:query to:name];
	doc.selectedQuery = query;
	[qvc reloadFromDocument];
	RptqDatabaseSchemaTable *schemaTable = nil;
	for (RptqDatabaseSchemaTable *candidate in query.inDatabase.hasTables) {
		if ([candidate.name caseInsensitiveCompare:tableName] == NSOrderedSame ||
			[[candidate.name lowercaseString] hasSuffix:[tableName lowercaseString]]) {
			schemaTable = candidate;
			break;
		}
	}
	if (schemaTable == nil || [qvc addSchemaTableToQuery:schemaTable] == nil) {
		if (outError != NULL) *outError = [NSString stringWithFormat:@"table '%@' not found or not addable", tableName];
		return NO;
	}
	[doc notifyDocumentMutated];
	if (![headless writeToURL:madURL reproducible:NO error:&error]) {
		if (outError != NULL) *outError = error.localizedDescription ?: @"save failed";
		return NO;
	}
	[wc.window orderOut:nil];
	printf("LIVE query-only source: mad=%s table=%s\n", madPath.UTF8String, tableName.UTF8String);
	return YES;
}

// Builds a two-source composition from live PostgreSQL reports (Album and a query-only
// Artist) joined on ArtistId, then exercises every node's Designer/Viewer.
static int MADSmokeWriteLiveComposition(NSString *directory) {
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];

	NSString *albumPath = [directory stringByAppendingPathComponent:@"PostgreSQL-chinook.mad"];
	NSString *artistPath = [directory stringByAppendingPathComponent:@"PostgreSQL-artist.mad"];
	NSString *compositionPath = [directory stringByAppendingPathComponent:@"Composition-Postgres-AlbumArtist.mad"];
	MADDatabaseConnectionPostgres *postgres = [[MADDatabaseConnectionPostgres alloc] initWithHost:@"127.0.0.1"
																						 database:@"chinook"
																						  andPort:5432];
	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"mad" andPassword:@"mad_test_pw"];
	NSString *errorText = nil;

	if (![fm fileExistsAtPath:albumPath]) {
		printf("LIVE composition FAILED: run --write-live-reports first (%s missing)\n", albumPath.UTF8String);
		return 1;
	}
	if (![fm fileExistsAtPath:artistPath] &&
		!MADSmokeWriteLiveQueryOnlyReport(@"PostgreSQL-artist", @"Artist", postgres, credential, directory, &errorText)) {
		printf("LIVE composition FAILED creating Artist source: %s\n", errorText.UTF8String ?: "?");
		return 1;
	}

	NSURL *compositionURL = [NSURL fileURLWithPath:compositionPath];
	[fm removeItemAtURL:compositionURL error:NULL];
	NSError *error = nil;
	MADHeadlessDocument *empty = [MADHeadlessDocument createEmptyDocumentAtURL:compositionURL error:&error];
	if (empty == nil) {
		printf("LIVE composition FAILED creating the document: %s\n", error.localizedDescription.UTF8String);
		return 1;
	}
	MADMacDocument *composition = [[MADMacDocument alloc] init];
	composition.fileURL = compositionURL;
	[composition adoptHeadlessDocument:empty];
	composition.sessionCredentials = credential;
	RptqQuery *root = [composition addRootQueryNamed:@"Result" error:&error];
	RptqQuery *albumChild = [composition importChildFromURL:[NSURL fileURLWithPath:albumPath] name:@"Album" error:&error];
	RptqQuery *artistChild = [composition importChildFromURL:[NSURL fileURLWithPath:artistPath] name:@"Artist" error:&error];
	if (root == nil || albumChild == nil || artistChild == nil ||
		[composition addChildQuery:albumChild error:&error] == nil ||
		[composition addChildQuery:artistChild error:&error] == nil) {
		printf("LIVE composition FAILED importing children: %s\n", error.localizedDescription.UTF8String);
		return 1;
	}

	composition.selectedQuery = root;
	[composition makeWindowControllers];
	MADMacWindowController *wc = composition.windowControllers.firstObject;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabQuery];
	MADMacQueryViewController *qvc = wc.queryViewController;
	[qvc reloadFromDocument];
	RptqQueryTable *rootAlbum = [qvc addUpstreamQueryToRoot:albumChild];
	RptqQueryTable *rootArtist = [qvc addUpstreamQueryToRoot:artistChild];
	if (rootAlbum == nil || rootArtist == nil) {
		printf("LIVE composition FAILED adding upstream tables\n");
		return 1;
	}
	RptqQueryField *(^fieldInTable)(RptqQueryTable *, NSString *) = ^RptqQueryField *(RptqQueryTable *table, NSString *name) {
		for (RptqQueryField *field in table.hasQueryFields) {
			if ([field.databaseSchemaField.name caseInsensitiveCompare:name] == NSOrderedSame) return field;
		}
		return (RptqQueryField *)nil;
	};
	// This PostgreSQL Chinook build names its columns in snake_case.
	RptqQueryField *albumKey = fieldInTable(rootAlbum, @"artist_id");
	RptqQueryField *artistKey = fieldInTable(rootArtist, @"artist_id");
	RptqQueryField *albumTitle = fieldInTable(rootAlbum, @"title");
	RptqQueryField *artistName = fieldInTable(rootArtist, @"name");
	if (albumKey == nil || artistKey == nil || albumTitle == nil || artistName == nil) {
		NSMutableString *diagnostics = [[NSMutableString alloc] init];
		[diagnostics appendFormat:@" albumChild tables=%lu fields:", (unsigned long)albumChild.hasQueryTables.count];
		for (RptqQueryTable *table in albumChild.hasQueryTables) {
			for (RptqQueryField *field in table.hasQueryFields) {
				[diagnostics appendFormat:@" %@", field.databaseSchemaField.name ?: @"(nil)"];
			}
		}
		[diagnostics appendFormat:@" | artistChild tables=%lu fields:", (unsigned long)artistChild.hasQueryTables.count];
		for (RptqQueryTable *table in artistChild.hasQueryTables) {
			for (RptqQueryField *field in table.hasQueryFields) {
				[diagnostics appendFormat:@" %@", field.databaseSchemaField.name ?: @"(nil)"];
			}
		}
		[diagnostics appendFormat:@" | rootAlbum fields:"];
		for (RptqQueryField *field in rootAlbum.hasQueryFields) {
			[diagnostics appendFormat:@" %@", field.databaseSchemaField.name ?: @"(nil)"];
		}
		[diagnostics appendFormat:@" | rootArtist fields:"];
		for (RptqQueryField *field in rootArtist.hasQueryFields) {
			[diagnostics appendFormat:@" %@", field.databaseSchemaField.name ?: @"(nil)"];
		}
		printf("LIVE composition FAILED: expected Album/Artist fields are missing:%s\n", diagnostics.UTF8String);
		return 1;
	}
	[qvc connectQueryField:albumKey toQueryField:artistKey];
	albumTitle.outputKey = @"album_title";
	albumTitle.outputIndex = 0;
	artistName.outputKey = @"artist_name";
	artistName.outputIndex = 1;
	[composition notifyDocumentMutated];

	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	MADMacDesignerViewController *designer = wc.designerViewController;
	[designer reloadFromDocument];
	RptqDocumentSection *detail = nil;
	for (RptqDocumentSection *section in [composition orderedSections]) {
		if ((MADDocumentSectionType)section.type == MADDocumentSectionTypeBody) { detail = section; break; }
	}
	if (detail != nil) {
		RptqDocumentElementLabel *label = [designer addStaticLabelInSection:detail atPoint:NSMakePoint(12.0, 6.0)];
		label.text = @"Album / Artist";
		[designer addDataField:albumTitle inSection:detail atPoint:NSMakePoint(12.0, 32.0)];
		[designer addDataField:artistName inSection:detail atPoint:NSMakePoint(12.0, 56.0)];
		[composition notifyDocumentMutated];
	}

	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	[NSApp activateIgnoringOtherApps:YES];
	[wc.window makeKeyAndOrderFront:nil];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	MADSmokeWriteWindowSnapshots(wc.window, directory, @"Composition-Result-Designer");

	MADMacViewerViewController *viewer = wc.viewerViewController;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[viewer refreshReportAction:nil];
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:90.0];
	while (!composition.headlessDocument.refreshed && viewer.lastRefreshError == nil && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
	}
	if (!composition.headlessDocument.refreshed || viewer.lastRefreshError != nil) {
		printf("LIVE composition FAILED refreshing: %s\n", viewer.lastRefreshError.description.UTF8String ?: "not refreshed");
		return 1;
	}
	NSUInteger resultRows = [composition.headlessDocument.dataTable numberOfRows];
	[viewer reloadPreview];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	MADSmokeWriteWindowSnapshots(wc.window, directory, @"Composition-Result-Viewer");

	// Album: a source with its own layout.
	composition.selectedQuery = albumChild;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	MADSmokeWriteWindowSnapshots(wc.window, directory, @"Composition-Album-Designer");
	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	MADSmokeWriteWindowSnapshots(wc.window, directory, @"Composition-Album-Viewer");
	BOOL albumGrid = viewer.isShowingRowGrid;
	NSInteger albumRows = viewer.rowGridView.numberOfRows;

	// Artist: the layout-less source -> Designer empty-state, Viewer row grid.
	composition.selectedQuery = artistChild;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	MADSmokeWriteWindowSnapshots(wc.window, directory, @"Composition-Artist-Designer");
	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	MADSmokeWriteWindowSnapshots(wc.window, directory, @"Composition-Artist-Viewer");
	BOOL artistGrid = viewer.isShowingRowGrid;
	NSInteger artistRows = viewer.rowGridView.numberOfRows;

	// Result again.
	composition.selectedQuery = root;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	MADSmokeWriteWindowSnapshots(wc.window, directory, @"Composition-Result-Again-Designer");
	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	MADSmokeWriteWindowSnapshots(wc.window, directory, @"Composition-Result-Again-Viewer");
	BOOL resultGrid = viewer.isShowingRowGrid;

	Class<MADReportExporting> pdfClass = [MADReportExporterRegistry exporterClassForFormat:@"pdf"];
	id<MADReportExporting> pdfExporter = [[(Class)pdfClass alloc] init];
	NSURL *pdfURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"Composition-Postgres-AlbumArtist.pdf"]];
	BOOL pdfOK = [pdfExporter exportDocument:composition.headlessDocument
									   toURL:pdfURL
									 options:MADReportExportOptionsNone
									   error:&error];
	[composition notifyDocumentMutated];
	BOOL saved = [composition.headlessDocument writeToURL:compositionURL reproducible:NO error:&error];
	[wc.window orderOut:nil];

	printf("LIVE composition: mad=%s pdf=%s saved=%d resultRows=%lu "
		   "albumGrid=%d albumRows=%ld artistGrid=%d artistRows=%ld resultGrid=%d sources=%lu\n",
		   compositionPath.UTF8String,
		   pdfOK ? pdfURL.path.UTF8String : "<failed>",
		   saved,
		   (unsigned long)resultRows,
		   albumGrid, (long)albumRows,
		   artistGrid, (long)artistRows,
		   resultGrid,
		   (unsigned long)[composition allQueries].count - 1);
	return (saved && pdfOK && artistGrid && !albumGrid && !resultGrid) ? 0 : 1;
}

static int MADSmokeWriteLiveReports(NSString *directory) {
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];

	MADDatabaseConnection *mysql = [[MADDatabaseConnectionMySql alloc] initWithHost:@"127.0.0.1"
																		   database:@"employees"
																			andPort:13306];
	MADDatabaseConnection *postgres = [[MADDatabaseConnectionPostgres alloc] initWithHost:@"127.0.0.1"
																				 database:@"chinook"
																				  andPort:5432];
	MADDatabaseConnection *sqlServer = [[MADDatabaseConnectionSQLServer alloc] initWithHost:@"127.0.0.1"
																					 server:@"127.0.0.1"
																				   database:@"AdventureWorksLT2022"
																					andPort:1433];
	MADCredential *mysqlCredential = [[MADCredential alloc] initWithUsername:@"root" andPassword:@"root"];
	MADCredential *postgresCredential = [[MADCredential alloc] initWithUsername:@"mad" andPassword:@"mad_test_pw"];
	MADCredential *sqlServerCredential = [[MADCredential alloc] initWithUsername:@"sa" andPassword:@"Root1@Root2"];

	NSString *mysqlError = nil, *postgresError = nil, *sqlServerError = nil;
	BOOL mysqlOK = MADSmokeWriteLiveReport(@"MySQL-employees", @"employees", @"first_name",
										   mysql, mysqlCredential, directory, &mysqlError);
	BOOL postgresOK = MADSmokeWriteLiveReport(@"PostgreSQL-chinook", @"Album", @"Title",
											  postgres, postgresCredential, directory, &postgresError);
	BOOL sqlServerOK = MADSmokeWriteLiveReport(@"SQLServer-AdventureWorksLT", @"Customer", @"CompanyName",
											   sqlServer, sqlServerCredential, directory, &sqlServerError);
	if (!mysqlOK) printf("LIVE MySQL FAILED: %s\n", mysqlError.UTF8String ?: "?");
	if (!postgresOK) printf("LIVE PostgreSQL FAILED: %s\n", postgresError.UTF8String ?: "?");
	if (!sqlServerOK) printf("LIVE SQL Server FAILED: %s\n", sqlServerError.UTF8String ?: "?");
	printf("LIVE SUMMARY: mysql=%d postgres=%d sqlserver=%d directory=%s\n",
		   mysqlOK, postgresOK, sqlServerOK, directory.UTF8String);
	return (mysqlOK && postgresOK && sqlServerOK) ? 0 : 1;
}

int main(int argc, const char * argv[]) {
	sRetainedPanels = [[NSMutableArray alloc] init];
	@autoreleasepool {
		if (argc >= 3 && strcmp(argv[1], "--write-node-fixture") == 0) {
			return MADSmokeWriteNodeFixture([NSString stringWithUTF8String:argv[2]]);
		}
		if (argc >= 3 && strcmp(argv[1], "--write-node-screenshots") == 0) {
			return MADSmokeWriteNodeScreenshots([NSString stringWithUTF8String:argv[2]]);
		}
		if (argc >= 3 && strcmp(argv[1], "--write-ui-screenshots") == 0) {
			return MADSmokeWriteUIScreenshots([NSString stringWithUTF8String:argv[2]]);
		}
		if (argc >= 2 && strcmp(argv[1], "--write-live-reports") == 0) {
			NSString *liveDirectory = argc >= 3
				? [NSString stringWithUTF8String:argv[2]]
				: [NSHomeDirectory() stringByAppendingPathComponent:@"MAD-TestReports"];
			return MADSmokeWriteLiveReports(liveDirectory);
		}
		if (argc >= 2 && strcmp(argv[1], "--write-live-composition") == 0) {
			NSString *compositionDirectory = argc >= 3
				? [NSString stringWithUTF8String:argv[2]]
				: [NSHomeDirectory() stringByAppendingPathComponent:@"MAD-TestReports"];
			return MADSmokeWriteLiveComposition(compositionDirectory);
		}
		// The app installs this controller in -applicationWillFinishLaunching; the smoke
		// path opens documents before that, so install it first (a document opened
		// earlier would otherwise create the base NSDocumentController).
		(void)[[MADMacDocumentController alloc] init];

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

		// 0. The app's bundled London.mad sample keeps a Standard Report's field list.
		// Its single query is the layout root but is a leaf: it carries no output keys,
		// so a root/leaf misclassification empties the Designer's field list.
		{
			// The bundled London sample is a legacy store: the converter finds MAD.momd in
			// this process's bundle, which for the bare smoke binary is its own directory.
			// Copy the app bundle's compiled model there so the real conversion path runs.
			NSString *modelSource = [appPath stringByAppendingPathComponent:@"Contents/Resources/MAD.momd"];
			NSString *modelDirectory = [[NSBundle mainBundle] resourcePath] ?: [appPath stringByDeletingLastPathComponent];
			NSString *modelDestination = [modelDirectory stringByAppendingPathComponent:@"MAD.momd"];
			if ([fm fileExistsAtPath:modelSource] && ![fm fileExistsAtPath:modelDestination]) {
				[fm copyItemAtPath:modelSource toPath:modelDestination error:NULL];
			}

			NSString *bundledLondonPath = [repoRoot stringByAppendingPathComponent:
				@"MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad"];
			NSError *bundledLondonError = nil;
			MADMacDocument *bundledLondon = [[MADMacDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:bundledLondonPath]
																				  ofType:@"com.thomason.mad"
																				   error:&bundledLondonError];
			if (bundledLondon == nil) {
				fprintf(stderr, "FAIL: Could not open bundled London.mad: %s\n", bundledLondonError.localizedDescription.UTF8String);
				return 290;
			}
			// A standalone Designer keeps NSDocumentController out of this early check: the
			// GUI launch section below asserts the app's own document controller is shared.
			MADMacDesignerViewController *bundledLondonDesigner =
				[[MADMacDesignerViewController alloc] initWithDocument:bundledLondon];
			(void)bundledLondonDesigner.view;
			[bundledLondonDesigner reloadFromDocument];

			RptqQuery *bundledQuery = bundledLondon.selectedQuery;
			NSUInteger bundledTotalFields = 0;
			NSMutableString *bundledTables = [[NSMutableString alloc] init];
			for (RptqQueryTable *table in bundledQuery.hasQueryTables) {
				bundledTotalFields += table.hasQueryFields.count;
				[bundledTables appendFormat:@" %@(alias=%@,queryAlias=%@)",
					table.databaseSchemaTable.name, table.alias ?: @"nil", [table queryAlias]];
			}
			NSUInteger bundledSchemaTables = bundledQuery.inDatabase.hasTables.count;
			NSUInteger bundledSchemaFields = 0;
			for (RptqDatabaseSchemaTable *schemaTable in bundledQuery.inDatabase.hasTables) {
				bundledSchemaFields += schemaTable.hasFields.count;
			}
			NSString *bundledDocumentType = bundledLondon.isComposed
				? @"Composition Report"
				: @"Standard Report";
			if (bundledLondon.isComposed ||
				bundledLondonDesigner.displayedQueryFields.count == 0 ||
				![bundledLondonDesigner.fieldsHeaderLabel.stringValue containsString:@"QUERY FIELDS"] ||
				bundledLondonDesigner.queryFieldsTableView.numberOfRows <= 0) {
				fprintf(stderr,
					"FAIL: Bundled London.mad field list: isComposed=%d selected='%s' showsColumns=%d "
					"schemaTables=%lu schemaFields=%lu queryTables=%lu totalQueryFields=%lu "
					"caption='%s' displayed=%lu tableRows=%ld search='%s' "
					"documentType='%s' tables:%s\n",
					bundledLondon.isComposed,
					bundledQuery.name.UTF8String ?: "",
					[bundledLondon queryShowsReportColumns:bundledQuery],
					(unsigned long)bundledSchemaTables,
					(unsigned long)bundledSchemaFields,
					(unsigned long)bundledQuery.hasQueryTables.count,
					(unsigned long)bundledTotalFields,
					bundledLondonDesigner.fieldsHeaderLabel.stringValue.UTF8String ?: "",
					(unsigned long)bundledLondonDesigner.displayedQueryFields.count,
					(long)bundledLondonDesigner.queryFieldsTableView.numberOfRows,
					bundledLondonDesigner.queryFieldsSearchField.stringValue.UTF8String ?: "",
					bundledDocumentType.UTF8String ?: "",
					bundledTables.UTF8String ?: "");
				return 290;
			}
			printf("PASS: Bundled London.mad Standard Report field list (%lu query fields across %lu query tables; %lu schema tables / %lu schema fields; caption '%s', table rows %ld)\n",
				   (unsigned long)bundledTotalFields,
				   (unsigned long)bundledQuery.hasQueryTables.count,
				   (unsigned long)bundledSchemaTables,
				   (unsigned long)bundledSchemaFields,
				   bundledLondonDesigner.fieldsHeaderLabel.stringValue.UTF8String ?: "",
				   (long)bundledLondonDesigner.queryFieldsTableView.numberOfRows);
		}

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

		NSString *identityPath = [packagedAppBundle pathForResource:@"MADBuildInfo" ofType:@"plist"];
		NSDictionary *identity = identityPath.length > 0 ? [NSDictionary dictionaryWithContentsOfFile:identityPath] : nil;
		NSString *revision = identity[@"MADEngineRevision"];
		NSString *build = identity[@"MADAppBuild"];
		if (![revision isKindOfClass:[NSString class]] || ![build isKindOfClass:[NSString class]] ||
			![revision isEqualToString:[@"r" stringByAppendingString:build]]) {
			fprintf(stderr, "FAIL: packaged build identity is inconsistent: revision='%s' build='%s'\n",
					revision.UTF8String, build.UTF8String);
			return 75;
		}

		if (![aboutWC.titleLabel.stringValue isEqualToString:@"MAD Designer"] ||
			![aboutWC.versionLabel.stringValue containsString:@"v9.1"] ||
			![aboutWC.versionLabel.stringValue containsString:revision] ||
			[aboutWC.versionLabel.stringValue containsString:@"unknown"] ||
			![aboutWC.applicationVersionLabel.stringValue containsString:@"v0.8"] ||
			![aboutWC.applicationVersionLabel.stringValue containsString:build] ||
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

		// 12. Composed authoring: build the invoices/payments report from scratch through
		// the document and query-workspace actions (no prebuilt .mad), save, reopen,
		// refresh, and verify the source-vs-root filter behaviour.
		NSString *authorDir = [NSTemporaryDirectory() stringByAppendingPathComponent:
								[NSString stringWithFormat:@"mad-composed-author-%@", NSUUID.UUID.UUIDString]];
		[fm createDirectoryAtPath:authorDir withIntermediateDirectories:YES attributes:nil error:NULL];
		NSURL *authorInvoicesURL = [NSURL fileURLWithPath:[authorDir stringByAppendingPathComponent:@"invoices.sqlite"]];
		NSURL *authorPaymentsURL = [NSURL fileURLWithPath:[authorDir stringByAppendingPathComponent:@"payments.sqlite"]];
		NSURL *authorMadURL = [NSURL fileURLWithPath:[authorDir stringByAppendingPathComponent:@"composed.mad"]];

		if (!MADSmokeRunSQLite(authorInvoicesURL, @[@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL, note TEXT);",
													 @"INSERT INTO invoices VALUES (1, 100.0, 'first');",
													 @"INSERT INTO invoices VALUES (2, 200.0, 'second');",
													 @"INSERT INTO invoices VALUES (3, 300.0, 'third');"]) ||
			!MADSmokeRunSQLite(authorPaymentsURL, @[@"CREATE TABLE payments (payment_id INTEGER, invoice_id INTEGER, amount REAL);",
													 @"INSERT INTO payments VALUES (101, 1, 40.0);",
													 @"INSERT INTO payments VALUES (102, 1, 60.0);"])) {
			fprintf(stderr, "FAIL: Could not write authoring source databases\n");
			return 200;
		}

		MADHeadlessDocument *authorHeadless = [MADHeadlessDocument createDocumentAtURL:authorMadURL
															   withDatabaseConnection:[[MADDatabaseConnectionSqlite3 alloc] initWithUrl:authorInvoicesURL]
																		  credentials:nil
																				error:&err];
		if (authorHeadless == nil) {
			fprintf(stderr, "FAIL: Could not create authoring document: %s\n", err.localizedDescription.UTF8String);
			return 201;
		}
		MADMacDocument *authorDoc = [[MADMacDocument alloc] init];
		authorDoc.fileURL = authorMadURL;
		[authorDoc adoptHeadlessDocument:authorHeadless];

		RptqQuery *invoicesQuery = authorDoc.allQueries.firstObject;
		[authorDoc renameQuery:invoicesQuery to:@"invoices"];

		[authorDoc makeWindowControllers];
		MADMacWindowController *authorWC = authorDoc.windowControllers.firstObject;
		[authorWC switchToWorkspaceTab:MADMacWorkspaceTabQuery];
		[authorWC.window layoutIfNeeded];
		if (![authorWC.window.subtitle isEqualToString:@"Standard Report"]) {
			fprintf(stderr, "FAIL: Standard document type subtitle is not 'Standard Report'\n");
			return 207;
		}
		MADMacQueryViewController *authorQVC = authorWC.queryViewController;

		// Add the invoices schema table to the invoices source query (the ordinary
		// "double-click a table" action).
		authorDoc.selectedQuery = invoicesQuery;
		[authorQVC reloadFromDocument];
		RptqDatabaseSchemaTable *invoicesSchemaTable = invoicesQuery.inDatabase.hasTables.anyObject;
		if ([authorQVC addSchemaTableToQuery:invoicesSchemaTable] == nil) {
			fprintf(stderr, "FAIL: Could not add invoices schema table to its source query\n");
			return 202;
		}

		// Add the payments source query (the "+ Source…" action, then name it).
		RptqQuery *paymentsQuery = [authorDoc addSourceQueryNamed:@"payments"
												   withConnection:[[MADDatabaseConnectionSqlite3 alloc] initWithUrl:authorPaymentsURL]
													  credentials:nil
															error:&err];
		if (paymentsQuery == nil) {
			fprintf(stderr, "FAIL: Could not add payments source query: %s\n", err.localizedDescription.UTF8String);
			return 203;
		}
		authorDoc.selectedQuery = paymentsQuery;
		[authorQVC reloadFromDocument];
		RptqDatabaseSchemaTable *paymentsSchemaTable = paymentsQuery.inDatabase.hasTables.anyObject;
		if ([authorQVC addSchemaTableToQuery:paymentsSchemaTable] == nil) {
			fprintf(stderr, "FAIL: Could not add payments schema table to its source query\n");
			return 204;
		}

		// Add the root and its two upstream tables (the "+ Root" action, then the
		// source-queries sidebar).
		RptqQuery *rootQuery = [authorDoc addRootQueryNamed:@"root" error:&err];
		if (rootQuery == nil) {
			fprintf(stderr, "FAIL: Could not add root query: %s\n", err.localizedDescription.UTF8String);
			return 205;
		}
		if (![authorWC.window.subtitle isEqualToString:@"Composition Report"]) {
			fprintf(stderr, "FAIL: Document type subtitle did not update to 'Composition Report' after adding the root\n");
			return 208;
		}
		authorDoc.selectedQuery = rootQuery;
		[authorQVC reloadFromDocument];
		RptqQueryTable *rootInvoicesTable = [authorQVC addUpstreamQueryToRoot:invoicesQuery];
		RptqQueryTable *rootPaymentsTable = [authorQVC addUpstreamQueryToRoot:paymentsQuery];
		if (rootInvoicesTable == nil || rootPaymentsTable == nil) {
			fprintf(stderr, "FAIL: Could not add upstream sources to the root\n");
			return 206;
		}

		// Join invoices.invoice_id -> payments.invoice_id (the drag-to-join action).
		RptqQueryField *(^fieldNamed)(RptqQueryTable *, NSString *) = ^(RptqQueryTable *table, NSString *name) {
			for (RptqQueryField *f in table.hasQueryFields) {
				if ([f.databaseSchemaField.name isEqualToString:name]) return f;
			}
			return (RptqQueryField *)nil;
		};
		RptqQueryField *leftJoinField = fieldNamed(rootInvoicesTable, @"invoice_id");
		RptqQueryField *rightJoinField = fieldNamed(rootPaymentsTable, @"invoice_id");
		if ([authorQVC connectQueryField:leftJoinField toQueryField:rightJoinField] == nil ||
			rootQuery.hasQueryLinks.count != 1) {
			fprintf(stderr, "FAIL: Could not create the root left join on invoice_id\n");
			return 207;
		}

		// Choose and name the three root outputs (the Outputs panel's effect).
		fieldNamed(rootInvoicesTable, @"invoice_id").outputKey = @"invoice_id";
		fieldNamed(rootInvoicesTable, @"invoice_id").outputIndex = 0;
		fieldNamed(rootInvoicesTable, @"amount").outputKey = @"invoice_amount";
		fieldNamed(rootInvoicesTable, @"amount").outputIndex = 1;
		fieldNamed(rootPaymentsTable, @"amount").outputKey = @"payment_amount";
		fieldNamed(rootPaymentsTable, @"amount").outputIndex = 2;
		[authorDoc notifyDocumentMutated];

		// Lay out three detail labels bound to the root outputs (the Report Designer's
		// "drag a query field onto a band" action).
		[authorWC switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
		[authorWC.window layoutIfNeeded];
		MADMacDesignerViewController *authorDVC = authorWC.designerViewController;
		RptqDocumentSection *authorDetail = authorDoc.rptqDocument.hasDetailSection;
		NSArray<RptqQueryField *> *outputs = [authorDoc.rptqDocument orderedCompositionOutputsWithError:&err];
		CGFloat authorLabelX = 12.0;
		for (RptqQueryField *output in outputs) {
			[authorDVC addDataField:output inSection:authorDetail atPoint:NSMakePoint(authorLabelX, 6.0)];
			authorLabelX += 100.0;
		}
		[authorDoc notifyDocumentMutated];

		// Save and reopen (the File > Save / reopen path: the document's writeToURL
		// forwards to the headless write, which promotes a composed graph to revision 3).
		if (![authorDoc.headlessDocument writeToURL:authorMadURL reproducible:NO error:&err]) {
			fprintf(stderr, "FAIL: Could not save the authored composed document: %s\n", err.localizedDescription.UTF8String);
			return 208;
		}
		MADMacDocument *reopenedDoc = [[MADMacDocument alloc] initWithContentsOfURL:authorMadURL ofType:@"com.thomason.mad" error:&err];
		if (reopenedDoc == nil || !reopenedDoc.isComposed || reopenedDoc.allQueries.count != 3) {
			fprintf(stderr, "FAIL: Reopened composed document is missing its root/sources: %s\n", err.localizedDescription.UTF8String);
			return 209;
		}
		MADMacViewerViewController *authorViewer = [[MADMacViewerViewController alloc] initWithDocument:reopenedDoc];
		(void)authorViewer.view;

		// Unfiltered: four detail rows, including both unpaid invoices.
		if (!MADSmokeRefreshComposed(reopenedDoc, authorViewer, 4)) {
			fprintf(stderr, "FAIL: Authored composed refresh did not produce 4 rows: %s\n",
					authorViewer.lastRefreshError.description.UTF8String);
			return 210;
		}
		MADDataTableFast *authorTable = reopenedDoc.headlessDocument.dataTable;
		if (fabs(MADSmokeComposedDouble(authorTable, 1, @"invoice_amount") - 100.0) > 0.001 ||
			fabs(MADSmokeComposedDouble(authorTable, 1, @"payment_amount") - 40.0) > 0.001 ||
			fabs(MADSmokeComposedDouble(authorTable, 4, @"invoice_amount") - 300.0) > 0.001 ||
			!isnan(MADSmokeComposedDouble(authorTable, 4, @"payment_amount"))) {
			fprintf(stderr, "FAIL: Authored composed detail values are wrong or swapped\n");
			return 211;
		}

		// Re-fetch the reopened document's queries and root fields (the author-time
		// objects belong to a different store context).
		RptqQuery *(^queryNamed)(NSString *) = ^(NSString *name) {
			for (RptqQuery *q in reopenedDoc.allQueries) {
				if ([q.name isEqualToString:name]) return q;
			}
			return (RptqQuery *)nil;
		};
		RptqQuery *reopenedPaymentsQuery = queryNamed(@"payments");
		RptqQuery *reopenedRootQuery = queryNamed(@"root");
		RptqQueryTable *reopenedRootPaymentsTable = nil;
		for (RptqQueryTable *t in reopenedRootQuery.hasQueryTables) {
			if (t.upstreamQuery == reopenedPaymentsQuery) { reopenedRootPaymentsTable = t; break; }
		}
		RptqQueryField *reopenedPaymentsAmount = fieldNamed(reopenedPaymentsQuery.hasQueryTables.anyObject, @"amount");
		RptqQueryField *reopenedPaymentAmountOutput = fieldNamed(reopenedRootPaymentsTable, @"amount");

		// Source filter: payments.amount > 50 leaves payment 60; the left join keeps
		// three rows (invoices 2 and 3 have no matching payment).
		RptqQueryPredicate *sourcePred = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:reopenedPaymentsAmount.identifier
																				 comparsonOperator:MADPredicateOperatorGreaterThan
																					 andRightValue:@"50"
																				   forManagedObjectContext:reopenedDoc.managedObjectContext error:&err];
		[reopenedPaymentsQuery addHasQueryPredicateObject:sourcePred];
		[reopenedDoc notifyDocumentMutated];
		if (!MADSmokeRefreshComposed(reopenedDoc, authorViewer, 3)) {
			fprintf(stderr, "FAIL: Source-filtered composed refresh did not produce 3 rows: %s\n",
					authorViewer.lastRefreshError.description.UTF8String);
			return 212;
		}

		// Move the predicate to the root: payment_amount > 50 keeps only (1,100,60).
		[reopenedPaymentsQuery removeHasQueryPredicateObject:sourcePred];
		[RptqQueryPredicate deletePredicate:sourcePred];
		RptqQueryPredicate *rootPred = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:reopenedPaymentAmountOutput.identifier
																				 comparsonOperator:MADPredicateOperatorGreaterThan
																					 andRightValue:@"50"
																				   forManagedObjectContext:reopenedDoc.managedObjectContext error:&err];
		[reopenedRootQuery addHasQueryPredicateObject:rootPred];
		[reopenedDoc notifyDocumentMutated];
		if (!MADSmokeRefreshComposed(reopenedDoc, authorViewer, 1)) {
			fprintf(stderr, "FAIL: Root-filtered composed refresh did not produce 1 row: %s\n",
					authorViewer.lastRefreshError.description.UTF8String);
			return 213;
		}
		MADDataTableFast *filteredTable = reopenedDoc.headlessDocument.dataTable;
		if (fabs(MADSmokeComposedDouble(filteredTable, 1, @"invoice_id") - 1.0) > 0.001 ||
			fabs(MADSmokeComposedDouble(filteredTable, 1, @"invoice_amount") - 100.0) > 0.001 ||
			fabs(MADSmokeComposedDouble(filteredTable, 1, @"payment_amount") - 60.0) > 0.001) {
			fprintf(stderr, "FAIL: Root filter did not keep only (1,100,60)\n");
			return 214;
		}

		[fm removeItemAtPath:authorDir error:NULL];
		printf("PASS: Authored composed report from scratch (create sources, name, switch, join, outputs, layout, save, reopen, refresh: 4 rows; source filter -> 3 rows; root filter -> (1,100,60))\n");
	}

	@autoreleasepool {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSError *err = nil;

		// 13. Convert a standard report into a one-child composition, then refresh.
		{
		NSString *convertDir = [NSTemporaryDirectory() stringByAppendingPathComponent:
								[NSString stringWithFormat:@"mad-convert-%@", NSUUID.UUID.UUIDString]];
		[fm createDirectoryAtPath:convertDir withIntermediateDirectories:YES attributes:nil error:NULL];
		NSURL *convertSourceURL = [NSURL fileURLWithPath:[convertDir stringByAppendingPathComponent:@"invoices.sqlite"]];
		NSURL *convertMadURL = [NSURL fileURLWithPath:[convertDir stringByAppendingPathComponent:@"invoices.mad"]];
		if (!MADSmokeRunSQLite(convertSourceURL, @[@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL);",
												   @"INSERT INTO invoices VALUES (1, 100.0);",
												   @"INSERT INTO invoices VALUES (2, 200.0);"])) {
			fprintf(stderr, "FAIL: Could not write convert source database\n");
			return 220;
		}
		NSString *convertError = nil;
		if (MADSmokeBuildStandardReport(convertSourceURL, convertMadURL, @"invoices", @[@"invoice_id", @"amount"], &convertError) == nil) {
			fprintf(stderr, "FAIL: Could not build convert source report: %s\n", convertError.UTF8String ?: "(none)");
			return 221;
		}
		MADMacDocument *convertDoc = [[MADMacDocument alloc] initWithContentsOfURL:convertMadURL ofType:@"com.thomason.mad" error:&err];
		if (convertDoc == nil || convertDoc.isComposed) {
			fprintf(stderr, "FAIL: Convert source did not open as a standard report\n");
			return 222;
		}
		RptqQuery *convertRoot = [convertDoc convertToCompositionWithChildName:nil error:&err];
		if (convertRoot == nil || !convertDoc.isComposed) {
			fprintf(stderr, "FAIL: Convert failed: %s\n", err.localizedDescription.UTF8String);
			return 223;
		}
		NSArray<RptqQueryField *> *convertOutputs = [convertDoc.rptqDocument orderedCompositionOutputsWithError:&err];
		if (convertOutputs.count != 2 ||
			![convertOutputs[0].outputKey isEqualToString:@"invoice_id"] ||
			![convertOutputs[1].outputKey isEqualToString:@"amount"]) {
			fprintf(stderr, "FAIL: Convert output keys are wrong\n");
			return 224;
		}
		MADMacViewerViewController *convertViewer = [[MADMacViewerViewController alloc] initWithDocument:convertDoc];
		(void)convertViewer.view;
		if (!MADSmokeRefreshComposed(convertDoc, convertViewer, 2)) {
			fprintf(stderr, "FAIL: Converted refresh failed: %s\n", convertViewer.lastRefreshError.description.UTF8String);
			return 225;
		}
		MADDataTableFast *convertTable = convertDoc.headlessDocument.dataTable;
		if ([convertTable numberOfRows] != 2 ||
			fabs(MADSmokeComposedDouble(convertTable, 1, @"invoice_id") - 1.0) > 0.001 ||
			fabs(MADSmokeComposedDouble(convertTable, 1, @"amount") - 100.0) > 0.001) {
			fprintf(stderr, "FAIL: Converted refresh produced wrong rows\n");
			return 226;
		}
		NSURL *convertSavedURL = [NSURL fileURLWithPath:[convertDir stringByAppendingPathComponent:@"converted.mad"]];
		if (![convertDoc.headlessDocument writeToURL:convertSavedURL reproducible:NO error:&err]) {
			fprintf(stderr, "FAIL: Converted save failed: %s\n", err.localizedDescription.UTF8String);
			return 227;
		}
		MADMacDocument *convertReopened = [[MADMacDocument alloc] initWithContentsOfURL:convertSavedURL ofType:@"com.thomason.mad" error:&err];
		if (convertReopened == nil || !convertReopened.isComposed) {
			fprintf(stderr, "FAIL: Converted document did not reopen as composed\n");
			return 228;
		}
		[fm removeItemAtPath:convertDir error:NULL];
		printf("PASS: Converted a standard report into a one-child composition (outputs, refresh, save, reopen)\n");
	}

	// 14. Create a composition by importing two standard reports, then reopen it
	// without the source `.mad` files present.
	{
		NSString *importDir = [NSTemporaryDirectory() stringByAppendingPathComponent:
							   [NSString stringWithFormat:@"mad-import-%@", NSUUID.UUID.UUIDString]];
		[fm createDirectoryAtPath:importDir withIntermediateDirectories:YES attributes:nil error:NULL];
		NSURL *importInvoicesURL = [NSURL fileURLWithPath:[importDir stringByAppendingPathComponent:@"invoices.sqlite"]];
		NSURL *importPaymentsURL = [NSURL fileURLWithPath:[importDir stringByAppendingPathComponent:@"payments.sqlite"]];
		NSURL *importInvoicesMad = [NSURL fileURLWithPath:[importDir stringByAppendingPathComponent:@"invoices.mad"]];
		NSURL *importPaymentsMad = [NSURL fileURLWithPath:[importDir stringByAppendingPathComponent:@"payments.mad"]];
		if (!MADSmokeRunSQLite(importInvoicesURL, @[@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL);", @"INSERT INTO invoices VALUES (1, 100.0);"]) ||
			!MADSmokeRunSQLite(importPaymentsURL, @[@"CREATE TABLE payments (invoice_id INTEGER, amount REAL);", @"INSERT INTO payments VALUES (1, 40.0);", @"INSERT INTO payments VALUES (1, 60.0);"])) {
			fprintf(stderr, "FAIL: Could not write import source databases\n");
			return 230;
		}
		NSString *importError = nil;
		if (MADSmokeBuildStandardReport(importInvoicesURL, importInvoicesMad, @"invoices", @[@"invoice_id", @"amount"], &importError) == nil ||
			MADSmokeBuildStandardReport(importPaymentsURL, importPaymentsMad, @"payments", @[@"invoice_id", @"amount"], &importError) == nil) {
			fprintf(stderr, "FAIL: Could not build import source reports: %s\n", importError.UTF8String ?: "(none)");
			return 231;
		}
		NSURL *importDestURL = [NSURL fileURLWithPath:[importDir stringByAppendingPathComponent:@"composition.mad"]];
		MADHeadlessDocument *empty = [MADHeadlessDocument createEmptyDocumentAtURL:importDestURL error:&err];
		if (empty == nil) {
			fprintf(stderr, "FAIL: Could not create empty composition: %s\n", err.localizedDescription.UTF8String);
			return 232;
		}
		MADMacDocument *importDoc = [[MADMacDocument alloc] init];
		importDoc.fileURL = importDestURL;
		[importDoc adoptHeadlessDocument:empty];
		if ([importDoc addRootQueryNamed:@"root" error:&err] == nil) {
			fprintf(stderr, "FAIL: Could not add the root: %s\n", err.localizedDescription.UTF8String);
			return 233;
		}
		RptqQuery *invoicesChild = [importDoc importChildFromURL:importInvoicesMad name:@"invoices" error:&err];
		RptqQuery *paymentsChild = [importDoc importChildFromURL:importPaymentsMad name:@"payments" error:&err];
		if (invoicesChild == nil || paymentsChild == nil ||
			[importDoc addChildQuery:invoicesChild error:&err] == nil ||
			[importDoc addChildQuery:paymentsChild error:&err] == nil) {
			fprintf(stderr, "FAIL: Could not import children: %s\n", err.localizedDescription.UTF8String);
			return 234;
		}
		NSArray<RptqQueryField *> *importOutputs = [importDoc.rptqDocument orderedCompositionOutputsWithError:&err];
		if (importDoc.allQueries.count != 3 || importOutputs.count != 4 ||
			![importOutputs[0].outputKey isEqualToString:@"invoice_id"] ||
			![importOutputs[1].outputKey isEqualToString:@"amount"] ||
			![importOutputs[2].outputKey isEqualToString:@"payments.invoice_id"] ||
			![importOutputs[3].outputKey isEqualToString:@"payments.amount"]) {
			fprintf(stderr, "FAIL: Import composition structure or outputs are wrong\n");
			return 235;
		}
		if (![importDoc.headlessDocument writeToURL:importDestURL reproducible:NO error:&err]) {
			fprintf(stderr, "FAIL: Imported composition save failed: %s\n", err.localizedDescription.UTF8String);
			return 236;
		}
		[fm removeItemAtPath:importInvoicesMad.path error:NULL];
		[fm removeItemAtPath:importPaymentsMad.path error:NULL];
		MADMacDocument *importReopened = [[MADMacDocument alloc] initWithContentsOfURL:importDestURL ofType:@"com.thomason.mad" error:&err];
		if (importReopened == nil || !importReopened.isComposed || importReopened.allQueries.count != 3) {
			fprintf(stderr, "FAIL: Imported composition did not reopen standalone\n");
			return 237;
		}
		[fm removeItemAtPath:importDir error:NULL];
			printf("PASS: Created a composition by importing two standard reports (structure, outputs, save, reopen without sources)\n");
		}

		// 15. Every node in a composition is a report: the toolbar picker switches Query,
		// Designer, and Viewer together; a source's layout renders its own values; a
		// layout-less source shows a row grid; json-report stays root-only; the Result and
		// a Standard Report keep today's document path.
		{
			NSString *nodeDir = [NSTemporaryDirectory() stringByAppendingPathComponent:
								 [NSString stringWithFormat:@"mad-node-reports-%@", NSUUID.UUID.UUIDString]];
			[fm createDirectoryAtPath:nodeDir withIntermediateDirectories:YES attributes:nil error:NULL];
			NSString *nodeError = nil;
			NSString *nodeMadPath = MADSmokeCreateComposedFixture(nodeDir, &nodeError);
			if (nodeMadPath.length == 0) {
				fprintf(stderr, "FAIL: Could not build the per-node fixture: %s\n", nodeError.UTF8String ?: "(none)");
				return 240;
			}
			NSURL *nodeMadURL = [NSURL fileURLWithPath:nodeMadPath];
			MADMacDocument *nodeDoc = [[MADMacDocument alloc] initWithContentsOfURL:nodeMadURL
																			ofType:@"com.thomason.mad"
																			 error:&err];
			if (nodeDoc == nil || !nodeDoc.isComposed) {
				fprintf(stderr, "FAIL: Could not open the per-node composition: %s\n", err.localizedDescription.UTF8String);
				return 241;
			}
			[nodeDoc makeWindowControllers];
			MADMacWindowController *nodeWC = nodeDoc.windowControllers.firstObject;
			if (nodeWC.activeWorkspaceTab != MADMacWorkspaceTabQuery) {
				fprintf(stderr, "FAIL: A newly opened composition did not start in the Query workspace\n");
				return 330;
			}
			[nodeWC switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
			[nodeWC.window layoutIfNeeded];
			MADMacDesignerViewController *nodeDVC = nodeWC.designerViewController;
			MADMacViewerViewController *nodeViewer = nodeWC.viewerViewController;

			NSTabView *nodeTabs = nil;
			for (NSView *view in nodeWC.window.contentView.subviews) {
				if ([view isKindOfClass:[NSTabView class]]) { nodeTabs = (NSTabView *)view; break; }
			}
			if (nodeTabs == nil || nodeWC.nodePickerPopup == nil) {
				fprintf(stderr, "FAIL: The composition window has no workspace tab view or node picker\n");
				return 242;
			}
			// The document type lives in the window subtitle, and the composition
			// picker is labeled Navigation.
			BOOL hasDocumentTypeItem = NO;
			BOOL hasNavigationLabel = NO;
			for (NSToolbarItem *item in nodeWC.window.toolbar.items) {
				if ([item.itemIdentifier isEqualToString:@"MADToolbarDocumentType"]) hasDocumentTypeItem = YES;
				if ([item.itemIdentifier isEqualToString:@"MADToolbarNodePicker"] &&
					[item.label isEqualToString:@"Navigation"]) hasNavigationLabel = YES;
			}
			if (hasDocumentTypeItem || !hasNavigationLabel ||
				![nodeWC.window.subtitle isEqualToString:@"Composition Report"] ||
				![nodeWC.nodePickerPopup.accessibilityLabel isEqualToString:@"Navigation"]) {
				fprintf(stderr, "FAIL: The composition toolbar still has a document type item or the picker is not labeled Navigation\n");
				return 331;
			}
			NSInteger startTab = [nodeTabs indexOfTabViewItem:nodeTabs.selectedTabViewItem];

			RptqQuery *(^nodeQueryNamed)(NSString *) = ^RptqQuery *(NSString *name) {
				for (RptqQuery *query in [nodeDoc allQueries]) {
					if ([query.name isEqualToString:name]) return query;
				}
				return (RptqQuery *)nil;
			};
			RptqQuery *nodeRoot = nodeDoc.rootQuery;
			RptqQuery *nodePayments = nodeQueryNamed(@"payments");
			RptqQuery *nodeInvoices = nodeQueryNamed(@"invoices");
			if (nodeRoot == nil || nodePayments == nil || nodeInvoices == nil) {
				fprintf(stderr, "FAIL: The per-node fixture is missing the root or a source query\n");
				return 243;
			}
			if (nodeWC.nodePickerPopup.numberOfItems != 3 ||
				![nodeWC.nodePickerPopup.itemArray.firstObject.title containsString:@"Result"]) {
				fprintf(stderr, "FAIL: The node picker does not list the Result first plus its two sources\n");
				return 244;
			}
			NSArray<RptqDocumentSection *> *rootNodeSections = [nodeDoc orderedSections];
			if (rootNodeSections.count == 0) {
				fprintf(stderr, "FAIL: The Result has no report bands\n");
				return 245;
			}
			NSInteger (^pickerIndexForQuery)(RptqQuery *) = ^NSInteger(RptqQuery *query) {
				for (NSInteger i = 0; i < nodeWC.nodePickerPopup.numberOfItems; i++) {
					if (nodeWC.nodePickerPopup.itemArray[i].representedObject == query) return i;
				}
				return -1;
			};

			// Select a source through the real toolbar picker: the workspace stays put,
			// the source's bands appear (created lazily), and the leaf caption stays.
			NSInteger paymentsIndex = pickerIndexForQuery(nodePayments);
			if (paymentsIndex < 0) {
				fprintf(stderr, "FAIL: The node picker does not contain the payments source\n");
				return 246;
			}
			[nodeWC.nodePickerPopup selectItemAtIndex:paymentsIndex];
			[nodeWC nodePickerChanged:nodeWC.nodePickerPopup];
			if (nodeDoc.selectedQuery != nodePayments) {
				fprintf(stderr, "FAIL: Selecting payments in the picker did not select its query\n");
				return 247;
			}
			if ([nodeTabs indexOfTabViewItem:nodeTabs.selectedTabViewItem] != startTab) {
				fprintf(stderr, "FAIL: Selecting a source changed the active workspace\n");
				return 248;
			}
			NSArray<RptqDocumentSection *> *paymentsSections =
				[nodePayments orderedLayoutSectionsForDocument:nodeDoc.rptqDocument];
			if (paymentsSections.count != 5 ||
				[nodeDoc orderedSections].firstObject != paymentsSections.firstObject ||
				[nodeDoc orderedSections].firstObject == rootNodeSections.firstObject) {
				fprintf(stderr, "FAIL: The selected source's bands are not its own five structural bands\n");
				return 249;
			}
			if ([nodeDVC.canvasView orderedSections].firstObject != paymentsSections.firstObject) {
				fprintf(stderr, "FAIL: The Designer canvas did not follow the selection\n");
				return 250;
			}
			if (![nodeDVC.fieldsHeaderLabel.stringValue containsString:@"QUERY FIELDS"]) {
				fprintf(stderr, "FAIL: A leaf source's field caption is not 'Query Fields'\n");
				return 251;
			}

			// Author a layout on the payments source: a label and a data field bound to
			// payments.amount (its own field, not the Result's).
			RptqDocumentSection *paymentsDetail = nil;
			for (RptqDocumentSection *section in paymentsSections) {
				if ((MADDocumentSectionType)section.type == MADDocumentSectionTypeBody) {
					paymentsDetail = section;
					break;
				}
			}
			if (paymentsDetail == nil) {
				fprintf(stderr, "FAIL: The payments source has no detail band\n");
				return 252;
			}
			NSString *paymentsLayoutText = NSLocalizedString(@"Payments Layout", @"Smoke fixture: static label text on the payments source's report.");
			RptqDocumentElementLabel *nodeLabel = [nodeDVC addStaticLabelInSection:paymentsDetail
																		  atPoint:NSMakePoint(12.0, 6.0)];
			nodeLabel.text = paymentsLayoutText;
			RptqQueryField *paymentsAmountField = nil;
			for (RptqQueryTable *table in nodePayments.hasQueryTables) {
				for (RptqQueryField *field in table.hasQueryFields) {
					if ([field.databaseSchemaField.name isEqualToString:@"amount"]) {
						paymentsAmountField = field;
						break;
					}
				}
			}
			if (paymentsAmountField == nil ||
				[nodeDVC addDataField:paymentsAmountField
							 inSection:paymentsDetail
							   atPoint:NSMakePoint(12.0, 32.0)] == nil) {
				fprintf(stderr, "FAIL: Could not author a data field on the payments source\n");
				return 253;
			}
			[nodeDoc notifyDocumentMutated];

			// Refresh the whole composition, then render the selected source from its own
			// retained result.
			if (!MADSmokeRefreshComposed(nodeDoc, nodeViewer, 4)) {
				fprintf(stderr, "FAIL: The per-node composed refresh failed: %s\n",
						nodeViewer.lastRefreshError.description.UTF8String);
				return 254;
			}
			MADDataResult *paymentsResult = nodeDoc.headlessDocument.nodeResults[@(nodePayments.identifier)];
			if (paymentsResult == nil || paymentsResult.numberOfRows != 2) {
				fprintf(stderr, "FAIL: The payments node result is missing or has the wrong row count\n");
				return 255;
			}
			if (nodeDoc.selectedQuery != nodePayments) {
				fprintf(stderr, "FAIL: The refresh changed the selected node\n");
				return 256;
			}
			if ([nodeViewer isShowingRowGrid] || nodeViewer.pdfView.document.pageCount == 0) {
				fprintf(stderr, "FAIL: The authored payments source did not render its own node PDF\n");
				return 257;
			}
			NSStackView *nodePageControls = [nodeViewer valueForKey:@"pageControlsStack"];
			if (nodePageControls == nil || nodePageControls.hidden ||
				![nodePageControls isDescendantOf:nodeViewer.statusBarView] ||
				!nodeViewer.printButton.enabled) {
				fprintf(stderr, "FAIL: The PDF viewer's page/zoom controls are missing or hidden in the status bar\n");
				return 257;
			}

			// The authored node renders values from its own rows, not the Result's.
			Class<MADReportExporting> nodeHTMLClass = [MADReportExporterRegistry exporterClassForFormat:@"html"];
			id<MADReportExporting> nodeHTMLExporter = [[(Class)nodeHTMLClass alloc] init];
			NSURL *nodeHTMLURL = [NSURL fileURLWithPath:[nodeDir stringByAppendingPathComponent:@"payments.html"]];
			if (![nodeHTMLExporter exportDocument:nodeDoc.headlessDocument
											query:nodePayments
											toURL:nodeHTMLURL
										  options:MADReportExportOptionsNone
											error:&err]) {
				fprintf(stderr, "FAIL: The payments node HTML export failed: %s\n", err.localizedDescription.UTF8String);
				return 258;
			}
			NSString *nodeHTML = [NSString stringWithContentsOfURL:nodeHTMLURL
														 encoding:NSUTF8StringEncoding
															error:NULL];
			if (![nodeHTML containsString:paymentsLayoutText] ||
				![nodeHTML containsString:@"40"] ||
				![nodeHTML containsString:@"60"]) {
				fprintf(stderr, "FAIL: The payments node report is missing its authored text or its own values\n");
				return 259;
			}

			// A filter typed for one node must not blank the next node's field list.
			nodeDVC.queryFieldsSearchField.stringValue = @"nomatch";

			// A source with no elements (invoices, untouched until now) is a row grid.
			NSInteger invoicesIndex = pickerIndexForQuery(nodeInvoices);
			if (invoicesIndex < 0) {
				fprintf(stderr, "FAIL: The node picker does not contain the invoices source\n");
				return 260;
			}
			[nodeWC.nodePickerPopup selectItemAtIndex:invoicesIndex];
			[nodeWC nodePickerChanged:nodeWC.nodePickerPopup];
			if (![nodeViewer isShowingRowGrid] || nodeViewer.rowGridView.numberOfRows != 3) {
				fprintf(stderr, "FAIL: A layout-less source did not show a three-row grid\n");
				return 261;
			}
			// The row grid has no pages or zoom; those controls hide rather than go dead.
			if (!nodePageControls.hidden || nodeViewer.printButton.enabled) {
				fprintf(stderr, "FAIL: Row-grid mode did not hide the page/zoom controls or disable print\n");
				return 261;
			}
			if (nodeViewer.pdfView.document != nil) {
				fprintf(stderr, "FAIL: The previous node's PDF was not cleared when a source was selected\n");
				return 262;
			}
			if (nodeDVC.queryFieldsSearchField.stringValue.length != 0 ||
				nodeDVC.displayedQueryFields.count == 0) {
				fprintf(stderr, "FAIL: Changing nodes did not clear the field-list filter (search='%s', fields=%lu)\n",
						nodeDVC.queryFieldsSearchField.stringValue.UTF8String ?: "",
						(unsigned long)nodeDVC.displayedQueryFields.count);
				return 291;
			}
			// The grid cells resolve against the node result's row ids, not blanks.
			NSString *gridFirstValue = [nodeViewer gridValueAtRow:0 columnIndex:0];
			if (gridFirstValue.length == 0) {
				fprintf(stderr, "FAIL: The row grid's first cell is blank\n");
				return 279;
			}

			// Selecting the Result returns every workspace to the Result's layout/report.
			NSInteger rootIndex = pickerIndexForQuery(nodeRoot);
			[nodeWC.nodePickerPopup selectItemAtIndex:rootIndex];
			[nodeWC nodePickerChanged:nodeWC.nodePickerPopup];
			if (nodeDoc.selectedQuery != nodeRoot ||
				[nodeDoc orderedSections].firstObject != rootNodeSections.firstObject) {
				fprintf(stderr, "FAIL: Selecting the Result did not return to the Result's layout\n");
				return 263;
			}
			if ([nodeViewer isShowingRowGrid] || nodeViewer.pdfView.document.pageCount == 0) {
				fprintf(stderr, "FAIL: The Result did not render its own report\n");
				return 264;
			}
			if (![nodeDVC.fieldsHeaderLabel.stringValue containsString:@"REPORT COLUMNS"]) {
				fprintf(stderr, "FAIL: The Result's field caption is not 'Report columns'\n");
				return 265;
			}

			// json-report is offered for the Result and refused for a source.
			NSSavePanel *rootExportPanel = [nodeViewer configureExportSavePanel:[NSSavePanel savePanel]];
			[sRetainedPanels addObject:rootExportPanel];
			BOOL rootOffersJSONReport = NO;
			for (NSMenuItem *item in nodeViewer.exportFormatPopup.itemArray) {
				if ([item.representedObject isEqualToString:@"json-report"]) {
					rootOffersJSONReport = YES;
					break;
				}
			}
			if (!rootOffersJSONReport) {
				fprintf(stderr, "FAIL: json-report is not offered for the Result\n");
				return 266;
			}
			[nodeWC.nodePickerPopup selectItemAtIndex:paymentsIndex];
			[nodeWC nodePickerChanged:nodeWC.nodePickerPopup];
			NSSavePanel *sourceExportPanel = [nodeViewer configureExportSavePanel:[NSSavePanel savePanel]];
			[sRetainedPanels addObject:sourceExportPanel];
			BOOL sourceOffersJSONReport = NO;
			for (NSMenuItem *item in nodeViewer.exportFormatPopup.itemArray) {
				if ([item.representedObject isEqualToString:@"json-report"]) {
					sourceOffersJSONReport = YES;
					break;
				}
			}
			if (sourceOffersJSONReport) {
				fprintf(stderr, "FAIL: json-report is offered for a source\n");
				return 267;
			}
			Class<MADReportExporting> nodeJSONReportClass = [MADReportExporterRegistry exporterClassForFormat:@"json-report"];
			id<MADReportExporting> nodeJSONReportExporter = [[(Class)nodeJSONReportClass alloc] init];
			NSError *nodeJSONError = nil;
			NSURL *nodeJSONURL = [NSURL fileURLWithPath:[nodeDir stringByAppendingPathComponent:@"payments.json"]];
			if ([nodeJSONReportExporter exportDocument:nodeDoc.headlessDocument
												 query:nodePayments
												 toURL:nodeJSONURL
											   options:MADReportExportOptionsNone
												 error:&nodeJSONError]) {
				fprintf(stderr, "FAIL: json-report exported a source instead of refusing it\n");
				return 268;
			}

			// The source layout persists across save/reopen; the Result's is untouched.
			NSUInteger paymentsElementCount = 0;
			for (RptqDocumentSection *section in paymentsSections) {
				for (RptqDocumentSectionRows *row in section.hasRows) paymentsElementCount += row.hasObjects.count;
			}
			NSUInteger rootElementCount = 0;
			for (RptqDocumentSection *section in rootNodeSections) {
				for (RptqDocumentSectionRows *row in section.hasRows) rootElementCount += row.hasObjects.count;
			}
			if (paymentsElementCount != 2) {
				fprintf(stderr, "FAIL: The authored payments layout has %lu elements, expected 2\n",
						(unsigned long)paymentsElementCount);
				return 269;
			}
			if (![nodeDoc.headlessDocument writeToURL:nodeMadURL reproducible:NO error:&err]) {
				fprintf(stderr, "FAIL: Could not save the per-node composition: %s\n", err.localizedDescription.UTF8String);
				return 270;
			}
			MADMacDocument *nodeReopened = [[MADMacDocument alloc] initWithContentsOfURL:nodeMadURL
																				  ofType:@"com.thomason.mad"
																				   error:&err];
			if (nodeReopened == nil) {
				fprintf(stderr, "FAIL: The per-node composition did not reopen: %s\n", err.localizedDescription.UTF8String);
				return 271;
			}
			RptqQuery *reopenedPayments = nil;
			for (RptqQuery *query in [nodeReopened allQueries]) {
				if ([query.name isEqualToString:@"payments"]) { reopenedPayments = query; break; }
			}
			if (reopenedPayments == nil) {
				fprintf(stderr, "FAIL: The reopened composition has no payments source\n");
				return 271;
			}
			nodeReopened.selectedQuery = reopenedPayments;
			NSUInteger reopenedPaymentsElements = 0;
			for (RptqDocumentSection *section in [reopenedPayments orderedLayoutSectionsForDocument:nodeReopened.rptqDocument]) {
				for (RptqDocumentSectionRows *row in section.hasRows) reopenedPaymentsElements += row.hasObjects.count;
			}
			NSUInteger reopenedRootElements = 0;
			for (RptqDocumentSection *section in [nodeReopened.rootQuery orderedLayoutSectionsForDocument:nodeReopened.rptqDocument]) {
				for (RptqDocumentSectionRows *row in section.hasRows) reopenedRootElements += row.hasObjects.count;
			}
			if (reopenedPaymentsElements != paymentsElementCount || reopenedRootElements != rootElementCount) {
				fprintf(stderr, "FAIL: Reopened layouts differ (payments %lu/%lu, Result %lu/%lu)\n",
						(unsigned long)reopenedPaymentsElements, (unsigned long)paymentsElementCount,
						(unsigned long)reopenedRootElements, (unsigned long)rootElementCount);
				return 272;
			}

			// A Standard Report keeps the document's own sections and its json-report.
			NSURL *standardSourceURL = [NSURL fileURLWithPath:[nodeDir stringByAppendingPathComponent:@"standard.sqlite"]];
			NSURL *standardMadURL = [NSURL fileURLWithPath:[nodeDir stringByAppendingPathComponent:@"standard.mad"]];
			if (!MADSmokeRunSQLite(standardSourceURL, @[@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL);",
													   @"INSERT INTO invoices VALUES (1, 100.0);"])) {
				fprintf(stderr, "FAIL: Could not write the Standard Report source\n");
				return 272;
			}
			NSString *standardError = nil;
			if (MADSmokeBuildStandardReport(standardSourceURL, standardMadURL, @"invoices",
											@[@"invoice_id", @"amount"], &standardError) == nil) {
				fprintf(stderr, "FAIL: Could not build the Standard Report: %s\n", standardError.UTF8String ?: "(none)");
				return 272;
			}
			MADMacDocument *standardDoc = [[MADMacDocument alloc] initWithContentsOfURL:standardMadURL
																				ofType:@"com.thomason.mad"
																				 error:&err];
			if (standardDoc == nil || standardDoc.isComposed ||
				standardDoc.selectedQuery != standardDoc.reportQuery ||
				![standardDoc queryIsReportRoot:standardDoc.selectedQuery]) {
				fprintf(stderr, "FAIL: The Standard Report does not read as its own report root\n");
				return 273;
			}
			for (RptqDocumentSection *section in [standardDoc orderedSections]) {
				if (section.ownerQuery != nil) {
					fprintf(stderr, "FAIL: The Standard Report's bands are not the document's own\n");
					return 274;
				}
			}
			// A Standard Report is a leaf: its Designer keeps the leaf caption and its own
			// query fields, and a bound field renders the report's own value.
			MADMacDesignerViewController *standardDesigner =
				[[MADMacDesignerViewController alloc] initWithDocument:standardDoc];
			(void)standardDesigner.view;
			[standardDesigner reloadFromDocument];
			if (![standardDesigner.fieldsHeaderLabel.stringValue containsString:@"QUERY FIELDS"] ||
				standardDesigner.displayedQueryFields.count == 0) {
				fprintf(stderr, "FAIL: A Standard Report's Designer lost its leaf field list\n");
				return 280;
			}
			RptqQueryField *standardAmountField = nil;
			for (RptqQueryTable *table in standardDoc.rptqQuery.hasQueryTables) {
				for (RptqQueryField *field in table.hasQueryFields) {
					if ([field.databaseSchemaField.name isEqualToString:@"amount"]) {
						standardAmountField = field;
						break;
					}
				}
			}
			if (standardAmountField == nil ||
				[standardDesigner addDataField:standardAmountField
									 inSection:standardDoc.rptqDocument.hasDetailSection
									   atPoint:NSMakePoint(12.0, 6.0)] == nil) {
				fprintf(stderr, "FAIL: Could not bind a data field on the Standard Report\n");
				return 281;
			}
			[standardDoc notifyDocumentMutated];

			MADMacViewerViewController *standardViewer = [[MADMacViewerViewController alloc] initWithDocument:standardDoc];
			(void)standardViewer.view;
			[standardViewer refreshReportAction:nil];
			NSDate *standardDeadline = [NSDate dateWithTimeIntervalSinceNow:20.0];
			while ([standardDoc.headlessDocument.dataTable numberOfRows] != 1 &&
				   standardViewer.lastRefreshError == nil && standardDeadline.timeIntervalSinceNow > 0) {
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
										 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
			}
			// Rows publish before the Viewer's refresh-completion render; wait for it.
			while (standardViewer.pdfView.document.pageCount == 0 &&
				   standardViewer.lastRefreshError == nil && standardDeadline.timeIntervalSinceNow > 0) {
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
										 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
			}
			if ([standardDoc.headlessDocument.dataTable numberOfRows] != 1 ||
				standardViewer.lastRefreshError != nil) {
				fprintf(stderr, "FAIL: The Standard Report refresh failed: %s\n",
						standardViewer.lastRefreshError.description.UTF8String);
				return 282;
			}
			if ([standardViewer isShowingRowGrid] || standardViewer.pdfView.document.pageCount == 0) {
				fprintf(stderr, "FAIL: The Standard Report did not render its own PDF\n");
				return 283;
			}
			Class<MADReportExporting> standardHTMLClass = [MADReportExporterRegistry exporterClassForFormat:@"html"];
			id<MADReportExporting> standardHTMLExporter = [[(Class)standardHTMLClass alloc] init];
			NSURL *standardHTMLURL = [NSURL fileURLWithPath:[nodeDir stringByAppendingPathComponent:@"standard.html"]];
			if (![standardHTMLExporter exportDocument:standardDoc.headlessDocument
												query:standardDoc.selectedQuery
												toURL:standardHTMLURL
											  options:MADReportExportOptionsNone
												error:&err]) {
				fprintf(stderr, "FAIL: The Standard Report HTML export failed: %s\n", err.localizedDescription.UTF8String);
				return 284;
			}
			NSString *standardHTML = [NSString stringWithContentsOfURL:standardHTMLURL
															  encoding:NSUTF8StringEncoding
																 error:NULL];
			if (![standardHTML containsString:@"100"]) {
				fprintf(stderr, "FAIL: The Standard Report did not render its bound value\n");
				return 285;
			}

			NSSavePanel *standardExportPanel = [standardViewer configureExportSavePanel:[NSSavePanel savePanel]];
			[sRetainedPanels addObject:standardExportPanel];
			BOOL standardOffersJSONReport = NO;
			for (NSMenuItem *item in standardViewer.exportFormatPopup.itemArray) {
				if ([item.representedObject isEqualToString:@"json-report"]) {
					standardOffersJSONReport = YES;
					break;
				}
			}
			if (!standardOffersJSONReport) {
				fprintf(stderr, "FAIL: A Standard Report no longer offers json-report\n");
				return 275;
			}

			// An empty composition (a root with no sources) reads as the Result: no crash,
			// the Result selected, its bands present, and the not-yet-refreshed guidance.
			NSURL *emptyCompositionURL = [NSURL fileURLWithPath:[nodeDir stringByAppendingPathComponent:@"empty-composition.mad"]];
			MADHeadlessDocument *emptyComposition = [MADHeadlessDocument createEmptyDocumentAtURL:emptyCompositionURL error:&err];
			if (emptyComposition == nil) {
				fprintf(stderr, "FAIL: Could not create an empty composition: %s\n", err.localizedDescription.UTF8String);
				return 276;
			}
			MADMacDocument *emptyDoc = [[MADMacDocument alloc] init];
			emptyDoc.fileURL = emptyCompositionURL;
			[emptyDoc adoptHeadlessDocument:emptyComposition];
			RptqQuery *emptyRoot = [emptyDoc addRootQueryNamed:@"root" error:&err];
			if (emptyRoot == nil || !emptyDoc.isComposed || emptyDoc.selectedQuery != emptyRoot ||
				[emptyDoc orderedSections].count == 0) {
				fprintf(stderr, "FAIL: An empty composition did not read as its Result\n");
				return 277;
			}
			MADMacViewerViewController *emptyViewer = [[MADMacViewerViewController alloc] initWithDocument:emptyDoc];
			(void)emptyViewer.view;
			[emptyViewer reloadPreview];
			if ([emptyViewer isShowingRowGrid] || emptyViewer.pdfView.document != nil ||
				emptyViewer.statusLabel.stringValue.length == 0) {
				fprintf(stderr, "FAIL: An unrefreshed empty composition did not show its guidance state\n");
				return 278;
			}

			[fm removeItemAtPath:nodeDir error:NULL];
			printf("PASS: Per-node reports: the picker switches all three workspaces, a source layout renders its own values, a layout-less source grids, json-report stays root-only, and the Result/Standard Report paths are unchanged\n");
		}
	}
		// 20. UI audit: workspace labels, Insert and context menus, tooltips, the Viewer
		// bottom bar, first-run tips, the menu bar, rename, and Open Recent.
		{
			NSFileManager *fm = [NSFileManager defaultManager];
			NSError *err = nil;
			NSString *uiDir = [NSTemporaryDirectory() stringByAppendingPathComponent:
							   [NSString stringWithFormat:@"mad-ui-smoke-%@", NSUUID.UUID.UUIDString]];
			[fm createDirectoryAtPath:uiDir withIntermediateDirectories:YES attributes:nil error:NULL];
			NSURL *uiSourceURL = [NSURL fileURLWithPath:[uiDir stringByAppendingPathComponent:@"ui.sqlite"]];
			NSURL *uiMadURL = [NSURL fileURLWithPath:[uiDir stringByAppendingPathComponent:@"UI.mad"]];
			if (!MADSmokeRunSQLite(uiSourceURL, @[@"CREATE TABLE t (a INTEGER, b TEXT);",
												   @"INSERT INTO t VALUES (1, 'x');"])) {
				fprintf(stderr, "FAIL: Could not write the UI smoke source\n");
				return 300;
			}
			NSString *uiError = nil;
			if (MADSmokeBuildStandardReport(uiSourceURL, uiMadURL, @"t", @[@"a", @"b"], &uiError) == nil) {
				fprintf(stderr, "FAIL: Could not build the UI smoke report: %s\n", uiError.UTF8String ?: "(none)");
				return 300;
			}
			MADMacDocument *uiDoc = [[MADMacDocument alloc] initWithContentsOfURL:uiMadURL
																			ofType:@"com.thomason.mad"
																			 error:&err];
			if (uiDoc == nil) {
				fprintf(stderr, "FAIL: Could not open the UI smoke report: %s\n", err.localizedDescription.UTF8String);
				return 300;
			}
			[uiDoc makeWindowControllers];
			MADMacWindowController *uiWC = uiDoc.windowControllers.firstObject;
			[uiWC.window layoutIfNeeded];

			// 20a. The workspace switcher names the workspaces, not the product.
			NSSegmentedControl *switcher = uiWC.workspaceSegmentedControl;
			if (switcher == nil || switcher.segmentCount != 3 ||
				![[switcher labelForSegment:0] isEqualToString:@"Query"] ||
				![[switcher labelForSegment:1] isEqualToString:@"Designer"] ||
				![[switcher labelForSegment:2] isEqualToString:@"Viewer"] ||
				switcher.toolTip.length == 0) {
				fprintf(stderr, "FAIL: Workspace switcher is not labeled Query / Designer / Viewer\n");
				return 301;
			}
			// A newly opened report starts in Query, not Designer.
			if (uiWC.activeWorkspaceTab != MADMacWorkspaceTabQuery ||
				switcher.selectedSegment != MADMacWorkspaceTabQuery) {
				fprintf(stderr, "FAIL: A newly opened report did not start in the Query workspace\n");
				return 332;
			}
			[uiWC switchToWorkspaceTab:MADMacWorkspaceTabQuery];
			if (uiWC.activeWorkspaceTab != MADMacWorkspaceTabQuery) {
				fprintf(stderr, "FAIL: The active workspace did not follow the switcher\n");
				return 301;
			}
			// Reopening the same report returns to the workspace it was last shown in.
			[uiWC switchToWorkspaceTab:MADMacWorkspaceTabViewer];
			MADMacWindowController *reopenedWC = [[MADMacWindowController alloc] initWithDocument:uiDoc];
			if (reopenedWC.activeWorkspaceTab != MADMacWorkspaceTabViewer) {
				fprintf(stderr, "FAIL: Reopening the report did not restore the Viewer workspace\n");
				return 333;
			}
			[uiWC switchToWorkspaceTab:MADMacWorkspaceTabQuery];

			// 20b. The Designer has one Insert menu that covers every element kind.
			MADMacDesignerViewController *uiDesigner = uiWC.designerViewController;
			(void)uiDesigner.view;
			[uiDesigner reloadFromDocument];
			NSPopUpButton *insertButton = uiDesigner.insertPopUpButton;
			if (insertButton == nil || insertButton.toolTip.length == 0) {
				fprintf(stderr, "FAIL: The Designer has no Insert menu or no tooltip on it\n");
				return 302;
			}
			NSMutableSet<NSNumber *> *insertKinds = [[NSMutableSet alloc] init];
			BOOL insertSymbols = YES;
			for (NSMenuItem *item in insertButton.menu.itemArray) {
				if (item.isSeparatorItem) continue;
				// A pull-down button's first item is its title, not an insertion command.
				if (item.tag < 1 || item.tag > 6) continue;
				[insertKinds addObject:@(item.tag)];
				if (item.image == nil) insertSymbols = NO;
			}
			if (insertKinds.count != 6 || !insertSymbols) {
				fprintf(stderr, "FAIL: The Insert menu covers %lu kinds or is missing SF Symbols\n",
						(unsigned long)insertKinds.count);
				return 302;
			}

			// 20c. The context menu matches the Insert menu and carries the element commands.
			RptqDocumentSection *uiDetail = nil;
			for (RptqDocumentSection *section in [uiDoc orderedSections]) {
				if ((MADDocumentSectionType)section.type == MADDocumentSectionTypeBody) { uiDetail = section; break; }
			}
			if (uiDetail == nil) {
				fprintf(stderr, "FAIL: The UI smoke report has no detail band\n");
				return 303;
			}
			NSMenu *sectionMenu = [uiDesigner buildContextMenuForElement:nil inSection:uiDetail];
			NSMenuItem *insertParent = sectionMenu.itemArray.firstObject;
			NSMutableSet<NSNumber *> *contextKinds = [[NSMutableSet alloc] init];
			for (NSMenuItem *item in insertParent.submenu.itemArray) {
				if (!item.isSeparatorItem) [contextKinds addObject:@(item.tag)];
			}
			if (contextKinds.count != 6) {
				fprintf(stderr, "FAIL: The section context menu exposes %lu insertable kinds, expected 6\n",
						(unsigned long)contextKinds.count);
				return 303;
			}
			RptqDocumentElementLabel *uiLabel = [uiDesigner addStaticLabelInSection:uiDetail atPoint:NSMakePoint(8.0, 8.0)];
			[uiDoc notifyDocumentMutated];
			NSMenu *elementMenu = [uiDesigner buildContextMenuForElement:uiLabel inSection:uiDetail];
			NSArray<NSString *> *elementTitles = [elementMenu.itemArray valueForKey:@"title"];
			for (NSString *required in @[@"Cut", @"Copy", @"Duplicate", @"Delete",
										 @"Size to Fit Content", @"Move to Band",
										 @"Select All Elements", @"Fit Band Height to Elements"]) {
				if (![elementTitles containsObject:required]) {
					fprintf(stderr, "FAIL: The element context menu is missing '%s'\n", required.UTF8String);
					return 304;
				}
			}

			// 20d. Tooltips and first-run tips.
			if (uiWC.window.subtitle.length == 0 ||
				insertButton.accessibilityLabel.length == 0) {
				fprintf(stderr, "FAIL: A key Designer control is missing its tooltip or accessibility label\n");
				return 305;
			}
			MADMacTipBar *designerTip = [uiDesigner valueForKey:@"tipBar"];
			MADMacQueryViewController *uiQuery = uiWC.queryViewController;
			(void)uiQuery.view;
			MADMacTipBar *queryTip = [uiQuery valueForKey:@"tipBar"];
			MADMacViewerViewController *uiViewer = uiWC.viewerViewController;
			(void)uiViewer.view;
			MADMacTipBar *viewerTip = [uiViewer valueForKey:@"tipBar"];
			if (designerTip == nil || queryTip == nil || viewerTip == nil) {
				fprintf(stderr, "FAIL: A workspace has no first-run tip\n");
				return 305;
			}
			for (MADMacTipBar *tip in @[designerTip, queryTip, viewerTip]) {
				if (tip.textLabel.stringValue.length == 0 ||
					tip.dismissButton.toolTip.length == 0 || tip.dismissButton.accessibilityLabel.length == 0) {
					fprintf(stderr, "FAIL: A first-run tip is missing its text or dismiss control\n");
					return 305;
				}
			}
			[designerTip dismissTip:nil];
			NSString *tipKey = [NSString stringWithFormat:@"MADMacTip.%@", designerTip.tipIdentifier];
			if (![[NSUserDefaults standardUserDefaults] boolForKey:tipKey]) {
				fprintf(stderr, "FAIL: Dismissing a tip was not remembered\n");
				return 306;
			}
			MADMacAppDelegate *uiAppDelegate = [[MADMacAppDelegate alloc] init];
			[uiAppDelegate showTipsAgain:nil];
			if ([[NSUserDefaults standardUserDefaults] boolForKey:tipKey]) {
				fprintf(stderr, "FAIL: Show Tips Again did not clear the dismissed state\n");
				return 306;
			}

			// 20e. The Viewer keeps status and page controls in its bottom bar, with
			// tooltips, and the overflow button carries the secondary actions.
			NSStackView *uiPageControls = [uiViewer valueForKey:@"pageControlsStack"];
			if (uiPageControls == nil || ![uiPageControls isDescendantOf:uiViewer.statusBarView] ||
				![uiViewer.statusLabel isDescendantOf:uiViewer.statusBarView]) {
				fprintf(stderr, "FAIL: The Viewer bottom bar does not carry the status and page controls\n");
				return 307;
			}
			if (uiViewer.refreshButton.toolTip.length == 0 ||
				uiViewer.printButton.toolTip.length == 0 ||
				uiViewer.exportButton.toolTip.length == 0 ||
				uiViewer.overflowButton.toolTip.length == 0) {
				fprintf(stderr, "FAIL: A Viewer action is missing its tooltip\n");
				return 307;
			}

			// 20f. The menu bar is complete and agrees with the Insert menu.
			NSMenu *mainMenu = [NSApp mainMenu];
			NSMutableDictionary<NSString *, NSMenu *> *menusByTitle = [[NSMutableDictionary alloc] init];
			for (NSMenuItem *item in mainMenu.itemArray) {
				if (item.submenu.title.length > 0) menusByTitle[item.submenu.title] = item.submenu;
			}
			for (NSString *required in @[@"File", @"Edit", @"Insert", @"Format", @"Query",
										 @"Report", @"View", @"Window", @"Help"]) {
				if (menusByTitle[required] == nil) {
					fprintf(stderr, "FAIL: The menu bar is missing the %s menu\n", required.UTF8String);
					return 308;
				}
			}
			NSArray<NSString *> *(^titlesOf)(NSMenu *) = ^NSArray<NSString *> *(NSMenu *menu) {
				return [menu.itemArray valueForKey:@"title"];
			};
			NSArray<NSString *> *fileTitles = titlesOf(menusByTitle[@"File"]);
			if (![fileTitles containsObject:@"Open Recent"] || ![fileTitles containsObject:@"Rename…"] ||
				![fileTitles containsObject:@"Save"] || ![fileTitles containsObject:@"Save As…"] ||
				![fileTitles containsObject:@"Export Report…"] || ![fileTitles containsObject:@"Print…"]) {
				fprintf(stderr, "FAIL: The File menu is incomplete: %s\n", fileTitles.description.UTF8String);
				return 308;
			}
			NSMenuItem *openRecentParent = nil;
			for (NSMenuItem *item in menusByTitle[@"File"].itemArray) {
				if ([item.title isEqualToString:@"Open Recent"]) { openRecentParent = item; break; }
			}
			if (openRecentParent.submenu == nil) {
				fprintf(stderr, "FAIL: Open Recent has no submenu\n");
				return 309;
			}
			NSArray<NSString *> *insertTitles = titlesOf(menusByTitle[@"Insert"]);
			if (insertTitles.count < 6 || ![insertTitles containsObject:@"Static Label"] ||
				![insertTitles containsObject:@"Data Field"] || ![insertTitles containsObject:@"Barcode"]) {
				fprintf(stderr, "FAIL: The Insert menu is incomplete: %s\n", insertTitles.description.UTF8String);
				return 310;
			}
			NSArray<NSString *> *formatTitles = titlesOf(menusByTitle[@"Format"]);
			if (![formatTitles containsObject:@"Size to Fit"] || ![formatTitles containsObject:@"Align"] ||
				![formatTitles containsObject:@"Bold"] || ![formatTitles containsObject:@"Italic"] ||
				![formatTitles containsObject:@"Underline"]) {
				fprintf(stderr, "FAIL: The Format menu is incomplete: %s\n", formatTitles.description.UTF8String);
				return 311;
			}
			NSArray<NSString *> *queryTitles = titlesOf(menusByTitle[@"Query"]);
			if (![queryTitles containsObject:@"Add Table to Query"] || ![queryTitles containsObject:@"Outputs…"] ||
				![queryTitles containsObject:@"Filters…"] || ![queryTitles containsObject:@"Groupings…"] ||
				![queryTitles containsObject:@"Rename Query…"] || ![queryTitles containsObject:@"Arrange Tables"] ||
				![queryTitles containsObject:@"Database Connection…"]) {
				fprintf(stderr, "FAIL: The Query menu is incomplete: %s\n", queryTitles.description.UTF8String);
				return 312;
			}
			NSArray<NSString *> *reportTitles = titlesOf(menusByTitle[@"Report"]);
			BOOL hasPageSize = NO;
			for (NSMenuItem *item in menusByTitle[@"Report"].itemArray) {
				if ([item.title isEqualToString:@"Page Size"] && item.submenu != nil) hasPageSize = YES;
			}
			if (![reportTitles containsObject:@"Refresh Report Data"] || !hasPageSize ||
				![reportTitles containsObject:@"Export Report…"] || ![reportTitles containsObject:@"Print…"]) {
				fprintf(stderr, "FAIL: The Report menu is incomplete: %s\n", reportTitles.description.UTF8String);
				return 313;
			}
			NSArray<NSString *> *viewTitles = titlesOf(menusByTitle[@"View"]);
			for (NSString *required in @[@"Query Workspace", @"Designer Workspace", @"Viewer Workspace",
										 @"Zoom In", @"Zoom Out", @"Actual Size", @"Show Left Sidebar",
										 @"Show Inspector", @"Show Minimap", @"Show Database Tables",
										 @"Show Grid", @"Snap to Grid", @"Show Rulers", @"Enter Full Screen"]) {
				if (![viewTitles containsObject:required]) {
					fprintf(stderr, "FAIL: The View menu is missing '%s': %s\n",
							required.UTF8String, viewTitles.description.UTF8String);
					return 314;
				}
			}
			if (![titlesOf(menusByTitle[@"Help"]) containsObject:@"Show Tips Again"]) {
				fprintf(stderr, "FAIL: The Help menu is missing Show Tips Again\n");
				return 315;
			}
			// Insert is enabled only in the Designer.
			NSMenuItem *insertProbe = nil;
			for (NSMenuItem *item in menusByTitle[@"Insert"].itemArray) {
				if (item.tag == MADMacPaletteElementKindLabel) { insertProbe = item; break; }
			}
			[uiWC switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
			if (insertProbe == nil || ![uiWC validateMenuItem:insertProbe]) {
				fprintf(stderr, "FAIL: Insert is disabled in the Designer\n");
				return 316;
			}
			[uiWC switchToWorkspaceTab:MADMacWorkspaceTabViewer];
			if ([uiWC validateMenuItem:insertProbe]) {
				fprintf(stderr, "FAIL: Insert is enabled outside the Designer\n");
				return 316;
			}

			// AppKit's stock Open Recent must not appear beside the app's icon-bearing one.
			MADMacAppDelegate *dupDelegate = [[MADMacAppDelegate alloc] init];
			[dupDelegate performSelector:NSSelectorFromString(@"buildMainMenu")];
			NSMenu *dupFileMenu = nil;
			for (NSMenuItem *top in [NSApp mainMenu].itemArray) {
				if ([top.submenu.title isEqualToString:@"File"]) { dupFileMenu = top.submenu; break; }
			}
			NSMenuItem *ourRecent = [dupDelegate valueForKey:@"openRecentMenuItem"];
			if (dupFileMenu == nil || ourRecent == nil || ourRecent.image == nil) {
				fprintf(stderr, "FAIL: The app's Open Recent item is missing its icon\n");
				return 320;
			}
			NSMenuItem *stockRecent = [[NSMenuItem alloc] initWithTitle:@"Open Recent" action:nil keyEquivalent:@""];
			NSMenu *stockSubmenu = [[NSMenu alloc] initWithTitle:@"Open Recent"];
			[stockSubmenu addItem:[[NSMenuItem alloc] initWithTitle:@"Clear Menu"
															 action:@selector(clearRecentDocuments:)
													  keyEquivalent:@""]];
			stockRecent.submenu = stockSubmenu;
			[dupFileMenu addItem:stockRecent];
			[dupDelegate performSelector:NSSelectorFromString(@"removeStockOpenRecentMenu")];
			NSUInteger recentItemCount = 0;
			for (NSMenuItem *item in dupFileMenu.itemArray) {
				if ([item.title isEqualToString:@"Open Recent"]) recentItemCount++;
			}
			if (recentItemCount != 1 || ![dupFileMenu.itemArray containsObject:ourRecent]) {
				fprintf(stderr, "FAIL: The File menu has %lu Open Recent items, expected the app's one\n",
						(unsigned long)recentItemCount);
				return 321;
			}

			// 20g. Rename updates the file, the document, the window, and Open Recent.
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:tipKey];
			NSError *renameError = nil;
			if (![uiDoc renameToDisplayName:@"UI Renamed" error:&renameError]) {
				fprintf(stderr, "FAIL: Rename failed: %s\n", renameError.localizedDescription.UTF8String);
				return 317;
			}
			NSURL *renamedURL = uiDoc.fileURL;
			if (![renamedURL.lastPathComponent isEqualToString:@"UI Renamed.mad"] ||
				![uiDoc.displayName isEqualToString:@"UI Renamed.mad"] ||
				![[NSFileManager defaultManager] fileExistsAtPath:renamedURL.path] ||
				[[NSFileManager defaultManager] fileExistsAtPath:uiMadURL.path]) {
				fprintf(stderr, "FAIL: Rename did not move the file or update the document (url=%s name=%s)\n",
						renamedURL.path.UTF8String, uiDoc.displayName.UTF8String);
				return 317;
			}
			if (![uiWC.window.title isEqualToString:uiDoc.displayName] ||
				![uiWC.window.representedURL isEqual:renamedURL]) {
				fprintf(stderr, "FAIL: Rename did not update the window title or proxy icon\n");
				return 318;
			}
			// NSDocumentController standardizes file URLs (the temporary directory is a
			// symlink), so compare the canonical forms.
			NSArray<NSURL *> *(^recentURLs)(void) = ^NSArray<NSURL *> *(void) {
				return [[NSDocumentController sharedDocumentController] recentDocumentURLs];
			};
			BOOL (^recentContains)(NSURL *) = ^BOOL(NSURL *url) {
				NSURL *target = url.URLByResolvingSymlinksInPath;
				for (NSURL *candidate in recentURLs()) {
					if ([[candidate URLByResolvingSymlinksInPath] isEqual:target]) return YES;
				}
				return NO;
			};
			if (!recentContains(renamedURL)) {
				fprintf(stderr, "FAIL: Rename did not add the report to Open Recent (%s)\n",
						recentURLs().description.UTF8String);
				return 319;
			}
			// The standard recent list persists through NSUserDefaults, which is what a
			// relaunch reads; noting a URL must be visible immediately.
			NSURL *recentProbe = [NSURL fileURLWithPath:[uiDir stringByAppendingPathComponent:@"Recent Probe.mad"]];
			[[NSFileManager defaultManager] copyItemAtURL:renamedURL toURL:recentProbe error:NULL];
			[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:recentProbe];
			if (!recentContains(recentProbe)) {
				fprintf(stderr, "FAIL: noteNewRecentDocumentURL did not update Open Recent\n");
				return 319;
			}

			[fm removeItemAtPath:uiDir error:NULL];
			printf("PASS: UI audit: Query/Designer/Viewer switcher, one complete Insert menu, a complete element context menu, tooltips and first-run tips, the Viewer bottom bar, the complete menu bar, rename, and Open Recent\n");
		}


	return 0;
}
