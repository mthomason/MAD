//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADFixtureMaker.m
//  CLI/Fixtures
//
//  Writes the documents the CLI's fixtures are made of, on the Mac, with the app's
//  own code paths.  Two modes:
//
//    MADFixtureMaker portable <document.mad> <fixture.mad>
//      Opens a document with MADocument -- which converts a legacy Core Data store
//      through MADStoreLegacyConverter on the way in -- and closes it, which is the
//      save path: the store written beside the metadata, the legacy files pruned,
//      and the guts directory archived back over the file.  This is how the
//      shipping samples, which are legacy documents, become portable fixtures:
//      nothing off Apple can convert one (Core Data, docs/developers/build/linux.md §5.1).
//
//    MADFixtureMaker create <mysql|tds|postgres> <host> <port> <user> <password> <database> <out.mad>
//      ...
//      Runs the app's create-document chain against a live server: create the
//      document, first-time setup, add the connection, import the schema, close
//      (which saves).  The result is a genuine document, schema and all, of the
//      kind the app writes when a user makes a new report.
//
//    MADFixtureMaker select <document.mad> <table> <field>[,<field>...]
//      What the designer does when the user ticks a table and its fields: adds the
//      query table, a query field per selected schema field, and one data label per
//      query field (the labels are what make the fields *active* -- the SELECT list
//      is the fields the report's elements reference, MADQueryActiveQueryFields).
//      Saves the document.  Without it a created document has no query at all.
//
//  Both modes read and write files the caller names; neither is a product tool.
//

#import <Foundation/Foundation.h>

#import <MAD/MADocument.h>
#import <MAD/MADArchiveManager.h>
#import <MAD/MADDocumentStore.h>
#import <MAD/MADOperationCreateDocumentAddConnection.h>
#import <MAD/MADOperationCreateDocumentCreateDocument.h>
#import <MAD/MADOperationCreateDocumentFirstTimeSetup.h>
#import <MAD/MADOperationCreateDocumentImportSchema.h>
#import <MAD/MADOperationDocumentCloseDocument.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADOperationUniqueUrlForFilename.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseCredentals.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqObject.h>
#import <MAD/MADQueryLinkType.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseType.h>

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADOperationQueue.h>

#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>

#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADTdsClient/MADDatabaseConnectionSQLServer.h>
#import <MADPostgres/MADDatabaseConnectionPostgres.h>

#import <UIKit/UIDocument.h>

#pragma mark - Chain pieces

/// The document URL, fixed: MADOperationUniqueUrlForFilename is the file explorer's
/// and wants a directory to search.  The chain only needs a URL to build on.
@interface MADFixtureURLOperation : NSOperation <MADOperationUniqueUrlForFilenameProtocol>
@property (nonatomic, copy, readonly) NSURL *uniqueUrl;
- (instancetype)initWithURL:(NSURL *)url;
@end

@implementation MADFixtureURLOperation
- (instancetype)initWithURL:(NSURL *)url {
	if (self = [super init]) { _uniqueUrl = url.copy; }
	return self;
}
@end

/// The initializer exists on the class but is not in its header; the app reaches it
/// through its group operation.  Declared so this program can build the chain the
/// same way MADDesignerUnitTests does.
@interface MADOperationCreateDocumentFirstTimeSetup (MADFixtureMaker)
- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection;
@end

/// Stands in for the credentials the app collects in its connection form: the
/// create chain looks for MADOperationHoldsCredentialsProtocol among its
/// dependencies (MADOperationCreateDocumentImportSchema).
@interface MADFixtureCredentialsOperation : MADOperation <MADOperationHoldsCredentialsProtocol>
@property (nonatomic, strong) MADCredential *credentials;
@end

@implementation MADFixtureCredentialsOperation
- (BOOL)isAsynchronous { return YES; }
- (void)execute { [self finish]; }
- (BOOL)gotCredentials { return self.credentials != nil; }
- (BOOL)manuallyInputtedCredentials { return NO; }
@end

#pragma mark - Helpers

static BOOL MADFixtureRunLoopUntil(BOOL *flag, NSTimeInterval timeout) {
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: timeout];
	while (!*flag && deadline.timeIntervalSinceNow > 0) {
		@autoreleasepool {
			[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
									 beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
		}
	}
	return *flag;
}

static BOOL MADFixtureDrainQueue(MADOperationQueue *queue, NSTimeInterval timeout) {
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: timeout];
	while (queue.operationCount > 0 && deadline.timeIntervalSinceNow > 0) {
		@autoreleasepool {
			[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
									 beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
		}
	}
	return queue.operationCount == 0;
}

#pragma mark - Modes

/// Opens a document and saves it again, which is what writing the portable store
/// over a legacy one takes.
static int MADFixtureWritePortableCopy(NSURL *inputURL, NSURL *outputURL) {

	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath: inputURL.path]) {
		fprintf(stderr, "%s: no such document\n", inputURL.path.UTF8String);
		return 1;
	}
	if (![fileManager removeItemAtURL: outputURL error: NULL] && [fileManager fileExistsAtPath: outputURL.path]) {
		fprintf(stderr, "%s: cannot replace\n", outputURL.path.UTF8String);
		return 1;
	}
	NSError *copyError = nil;
	if (![fileManager copyItemAtURL: inputURL toURL: outputURL error: &copyError]) {
		fprintf(stderr, "%s: %s\n", outputURL.path.UTF8String, copyError.localizedDescription.UTF8String);
		return 1;
	}

	MADocument *document = [[MADocument alloc] initWithFileURL: outputURL];
	__block BOOL finished = NO;
	__block BOOL opened = NO;
	[document openWithCompletionHandler: ^(BOOL success) {
		opened = success;
		finished = YES;
	}];
	MADFixtureRunLoopUntil(&finished, 120);

	if (!opened || document.storeContext == nil) {
		fprintf(stderr, "%s: could not open (a legacy document needs the Core Data converter)\n",
				outputURL.path.UTF8String);
		return 1;
	}

	// The save is the document's own; UIDocument only writes on close, and only when
	// something changed -- the conversion alone does not count as a change.
	[document updateChangeCount: UIDocumentChangeDone];
	finished = NO;
	__block BOOL closed = NO;
	[document closeWithCompletionHandler: ^(BOOL success) {
		closed = success;
		finished = YES;
	}];
	MADFixtureRunLoopUntil(&finished, 120);

	if (!closed) {
		fprintf(stderr, "%s: could not save\n", outputURL.path.UTF8String);
		return 1;
	}
	printf("wrote %s\n", outputURL.path.UTF8String);
	return 0;
}

/// The app's create-document chain, driven against a live server.
static int MADFixtureCreateDocument(MADDatabaseConnection *connection,
									MADCredential *credential,
									NSURL *outputURL) {

	MADFixtureCredentialsOperation *credentials = [[MADFixtureCredentialsOperation alloc] init];
	credentials.credentials = credential;

	MADFixtureURLOperation *urlOperation = [[MADFixtureURLOperation alloc] initWithURL: outputURL];

	MADOperationCreateDocumentCreateDocument *createDocument =
		[[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection: connection];
	MADOperationCreateDocumentFirstTimeSetup *firstTimeSetup =
		[[MADOperationCreateDocumentFirstTimeSetup alloc] initWithDatabaseConnection: connection];
	MADOperationCreateDocumentAddConnection *addConnection =
		[[MADOperationCreateDocumentAddConnection alloc] initWithDatabaseConnection: connection];
	MADOperationCreateDocumentImportSchema *importSchema =
		[[MADOperationCreateDocumentImportSchema alloc] initWithDatabaseConnection: connection];
	MADOperationDocumentCloseDocument *closeDocument = [[MADOperationDocumentCloseDocument alloc] init];

	[createDocument addDependency: urlOperation];
	[createDocument addDependency: credentials];
	[firstTimeSetup addDependency: createDocument];
	[addConnection addDependency: firstTimeSetup];
	[importSchema addDependency: createDocument];
	[importSchema addDependency: addConnection];
	[importSchema addDependency: credentials];
	[closeDocument addDependency: createDocument];
	[closeDocument addDependency: importSchema];

	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation: urlOperation];
	[queue addOperation: credentials];
	[queue addOperation: createDocument];
	[queue addOperation: firstTimeSetup];
	[queue addOperation: addConnection];
	[queue addOperation: importSchema];
	[queue addOperation: closeDocument];

	if (!MADFixtureDrainQueue(queue, 600)) {
		fprintf(stderr, "the create chain did not finish; %lu operations still queued\n",
				(unsigned long)queue.operationCount);
		return 1;
	}

	NSArray *errors = @[ createDocument.errors ?: @[], firstTimeSetup.errors ?: @[],
						 addConnection.errors ?: @[], importSchema.errors ?: @[], closeDocument.errors ?: @[] ];
	for (NSArray *stepErrors in errors) {
		for (NSError *error in stepErrors) {
			fprintf(stderr, "create failed: %s\n", error.description.UTF8String);
			return 1;
		}
	}
	if (!importSchema.success) {
		fprintf(stderr, "the schema import reported failure\n");
		return 1;
	}
	if (![[NSFileManager defaultManager] fileExistsAtPath: outputURL.path]) {
		fprintf(stderr, "%s: no document was written\n", outputURL.path.UTF8String);
		return 1;
	}
	printf("wrote %s\n", outputURL.path.UTF8String);
	return 0;
}

/// Adds a one-table query to a document, the way the designer does.
static int MADFixtureSelectFields(NSURL *documentURL, NSString *tableName, NSArray <NSString *> *fieldNames) {

	MADocument *document = [[MADocument alloc] initWithFileURL: documentURL];
	__block BOOL finished = NO;
	__block BOOL opened = NO;
	[document openWithCompletionHandler: ^(BOOL success) {
		opened = success;
		finished = YES;
	}];
	MADFixtureRunLoopUntil(&finished, 120);
	if (!opened || document.storeContext == nil) {
		fprintf(stderr, "%s: could not open\n", documentURL.path.UTF8String);
		return 1;
	}

	RptqStoreContext *context = document.storeContext;
	RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqDatabase *database = rptqDocument.hasDatabaseSchemas.anyObject;

	RptqDatabaseSchemaTable *schemaTable = nil;
	for (RptqDatabaseSchemaTable *candidate in database.hasTables) {
		if ([candidate.name isEqualToString: tableName]) { schemaTable = candidate; break; }
	}
	if (schemaTable == nil) {
		fprintf(stderr, "no table named %s in the document's schema\n", tableName.UTF8String);
		return 1;
	}

	RptqQueryTable *queryTable = [RptqQueryTable newQueryTableForSchemaTable: schemaTable
																   database: database
													forManagedObjectContext: context];
	NSMutableSet <RptqQueryField *> *queryFields = [[NSMutableSet alloc] init];
	for (RptqDatabaseSchemaField *schemaField in schemaTable.hasFields) {
		if (fieldNames.count > 0 && ![fieldNames containsObject: schemaField.name]) continue;

		RptqQueryField *queryField = [RptqQueryField newQueryField: context];
		queryField.inQueryTable = queryTable;
		queryField.databaseSchemaField = schemaField;
		[queryFields addObject: queryField];

		// The element is what makes the field active: the query's SELECT list is the
		// fields some element, link or group references.
		RptqDocumentElementLabelDataField *label =
			(RptqDocumentElementLabelDataField *)[context insertObjectForEntity:
												  NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier: 0];
		label.referencesQueryField = queryField;
	}
	if (queryFields.count == 0) {
		fprintf(stderr, "the selection matched no field of %s\n", tableName.UTF8String);
		return 1;
	}
	queryTable.hasQueryFields = queryFields;

	NSError *error = nil;
	if (![context save: &error]) {
		fprintf(stderr, "could not save the query: %s\n", error.description.UTF8String);
		return 1;
	}

	[document updateChangeCount: UIDocumentChangeDone];
	finished = NO;
	__block BOOL closed = NO;
	[document closeWithCompletionHandler: ^(BOOL success) {
		closed = success;
		finished = YES;
	}];
	MADFixtureRunLoopUntil(&finished, 120);
	if (!closed) {
		fprintf(stderr, "%s: could not save\n", documentURL.path.UTF8String);
		return 1;
	}
	printf("wrote %s with %lu field(s) of %s\n", documentURL.path.UTF8String,
		   (unsigned long)queryFields.count, tableName.UTF8String);
	return 0;
}

#pragma mark - Compose fixture

/// Writes the two sqlite sources a composed fixture reads: an invoices table and a
/// payments table, the exact rows the composition tests pin.
static BOOL MADFixtureWriteSource(NSURL *url, NSArray <NSString *> *statements) {
	[[NSFileManager defaultManager] removeItemAtURL: url error: NULL];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: url];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	database.databaseConnection = connection;
	[database openDatabase];
	NSError *error = nil;
	for (NSString *statement in statements) {
		if (![database executeSQL: statement
						fieldKeys: @[]
					 onConnection: nil
				  intoResultTable: nil
				   transactionSet: NO
				   returnsResults: NO
				   binaryBindings: nil
						withError: &error]) {
			[database closeDatabaseConnectionIfOpen];
			return NO;
		}
	}
	[database closeDatabaseConnectionIfOpen];
	return YES;
}

/// Builds one source: a database with a distinct connection reference (the source
/// file's path), a schema table with two fields, a named query over that table, and
/// the query fields the query projects.  `labelledFields` name the fields that carry
/// a report label (the active ones); the others are projected only when a downstream
/// consumer requires them (the composition root's join key).
static RptqObject *MADFixtureComposeSource(RptqStoreContext *context,
										   NSURL *sourceURL,
										   NSString *tableName,
										   NSString *queryName,
										   int64_t databaseId,
										   int64_t queryId,
										   int64_t tableId,
										   NSArray <NSString *> *labelledFields) {
	RptqObject *database = [context insertObjectForEntity: @"RptqDatabase" identifier: databaseId];
	[database setValue: @"Sqlite 3" forKey: @"databaseDriverType"];
	RptqObject *credential = [context insertObjectForEntity: @"RptqDatabaseCredentals" identifier: 0];
	[credential setValue: sourceURL.lastPathComponent forKey: @"dbname"];
	[credential setValue: sourceURL.path forKey: @"host"];
	[database setValue: credential forKey: @"ownedByUser"];

	RptqObject *schemaTable = [context insertObjectForEntity: @"RptqDatabaseSchemaTable" identifier: tableId + 1];
	[schemaTable setValue: tableName forKey: @"name"];
	RptqObject *idField = [context insertObjectForEntity: @"RptqDatabaseSchemaField" identifier: tableId + 2];
	[idField setValue: @"invoice_id" forKey: @"name"];
	RptqObject *amountField = [context insertObjectForEntity: @"RptqDatabaseSchemaField" identifier: tableId + 3];
	[amountField setValue: @"amount" forKey: @"name"];
	[database setValue: @[ schemaTable ] forKey: @"hasTables"];
	[schemaTable setValue: @[ idField, amountField ] forKey: @"hasFields"];

	RptqObject *query = [context insertObjectForEntity: @"RptqQuery" identifier: queryId];
	[query setValue: queryName forKey: @"name"];
	[database setValue: @[ query ] forKey: @"hasQueries"];
	RptqObject *queryTable = [context insertObjectForEntity: @"RptqQueryTable" identifier: tableId];
	[queryTable setValue: schemaTable forKey: @"databaseSchemaTable"];
	[queryTable setValue: query forKey: @"inQuery"];

	NSMutableArray *queryFields = [NSMutableArray arrayWithCapacity: 2];
	for (RptqObject *schemaField in @[ idField, amountField ]) {
		NSString *fieldName = [schemaField valueForKey: @"name"];
		RptqObject *queryField = [context insertObjectForEntity: @"RptqQueryField" identifier: 0];
		[queryField setValue: schemaField forKey: @"databaseSchemaField"];
		[queryField setValue: queryTable forKey: @"inQueryTable"];
		[queryFields addObject: queryField];

		// A label is what makes a field active (projected with a report element); the
		// payments source's invoice_id has none and is projected as a required field.
		if ([labelledFields containsObject: fieldName]) {
			RptqObject *label = [context insertObjectForEntity: @"RptqDocumentElementLabelDataField" identifier: 0];
			[label setValue: queryField forKey: @"referencesQueryField"];
		}
	}
	[queryTable setValue: queryFields forKey: @"hasQueryFields"];
	return query;
}

/// Writes a composed invoices/payments `.mad` and its two sqlite sources, using the
/// production store and archive writers (container 1.1, store revision 3).  When
/// `reordered`, the root projects `invoice_id, payment_amount, invoice_amount`
/// instead of the default `invoice_id, invoice_amount, payment_amount`.
static int MADFixtureCompose(NSURL *documentURL, BOOL reordered) {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *directory = documentURL.URLByDeletingLastPathComponent;
	NSURL *invoicesURL = [directory URLByAppendingPathComponent: @"invoices.sqlite"];
	NSURL *paymentsURL = [directory URLByAppendingPathComponent: @"payments.sqlite"];

	if (!MADFixtureWriteSource(invoicesURL, @[
		@"CREATE TABLE invoices (invoice_id INTEGER, amount REAL, note TEXT);",
		@"INSERT INTO invoices VALUES (1, 100.0, 'first');",
		@"INSERT INTO invoices VALUES (2, 200.0, 'second');",
		@"INSERT INTO invoices VALUES (3, 300.0, 'third');"])) {
		fprintf(stderr, "could not write %s\n", invoicesURL.path.UTF8String);
		return 1;
	}
	if (!MADFixtureWriteSource(paymentsURL, @[
		@"CREATE TABLE payments (payment_id INTEGER, invoice_id INTEGER, amount REAL);",
		@"INSERT INTO payments VALUES (101, 1, 40.0);",
		@"INSERT INTO payments VALUES (102, 1, 60.0);"])) {
		fprintf(stderr, "could not write %s\n", paymentsURL.path.UTF8String);
		return 1;
	}

	MADDocumentStore *store = [MADDocumentStore storeForDocumentURL: documentURL];
	[fileManager removeItemAtURL: store.gutsURL error: NULL];
	NSError *error = nil;
	if (![store openWithError: &error]) {
		fprintf(stderr, "could not open the document store: %s\n", error.localizedDescription.UTF8String);
		return 1;
	}
	RptqStoreContext *context = store.context;
	[context loadAllWithError: NULL];

	RptqObject *document = [context insertObjectForEntity: @"RptqDocument" identifier: 1];
	RptqObject *invoices = MADFixtureComposeSource(context, invoicesURL, @"invoices", @"invoices", 10, 101, 200, @[ @"invoice_id", @"amount" ]);
	RptqObject *payments = MADFixtureComposeSource(context, paymentsURL, @"payments", @"payments", 20, 102, 300, @[ @"amount" ]);
	RptqObject *invoicesDatabase = [invoices valueForKey: @"inDatabase"];
	RptqObject *paymentsDatabase = [payments valueForKey: @"inDatabase"];
	[document setValue: @[ invoicesDatabase, paymentsDatabase ] forKey: @"hasDatabaseSchemas"];

	RptqObject *root = [context insertObjectForEntity: @"RptqQuery" identifier: 100];
	[root setValue: @"root" forKey: @"name"];
	[root setValue: invoicesDatabase forKey: @"inDatabase"];
	RptqObject *rootInvoicesTable = [context insertObjectForEntity: @"RptqQueryTable" identifier: 400];
	[rootInvoicesTable setValue: root forKey: @"inQuery"];
	[rootInvoicesTable setValue: invoices forKey: @"upstreamQuery"];
	RptqObject *rootPaymentsTable = [context insertObjectForEntity: @"RptqQueryTable" identifier: 401];
	[rootPaymentsTable setValue: root forKey: @"inQuery"];
	[rootPaymentsTable setValue: payments forKey: @"upstreamQuery"];

	// The schema fields the root projects and joins on.  The invoices side carries
	// both invoice outputs; the payments side carries only its amount output, while
	// its invoice_id is the downstream-only join key.
	RptqObject *invoiceIdField = [context objectForEntity: @"RptqDatabaseSchemaField" identifier: 202];
	RptqObject *invoiceAmountField = [context objectForEntity: @"RptqDatabaseSchemaField" identifier: 203];
	RptqObject *paymentIdField = [context objectForEntity: @"RptqDatabaseSchemaField" identifier: 302];
	RptqObject *paymentAmountField = [context objectForEntity: @"RptqDatabaseSchemaField" identifier: 303];

	RptqObject *leftJoinField = [context insertObjectForEntity: @"RptqQueryField" identifier: 500];
	[leftJoinField setValue: invoiceIdField forKey: @"databaseSchemaField"];
	[leftJoinField setValue: rootInvoicesTable forKey: @"inQueryTable"];
	RptqObject *rightJoinField = [context insertObjectForEntity: @"RptqQueryField" identifier: 501];
	[rightJoinField setValue: paymentIdField forKey: @"databaseSchemaField"];
	[rightJoinField setValue: rootPaymentsTable forKey: @"inQueryTable"];
	RptqObject *join = [context insertObjectForEntity: @"RptqQueryLinks" identifier: 450];
	[join setValue: @(MADLinkTypeLeftOuterJoin) forKey: @"type"];
	[join setValue: leftJoinField forKey: @"hasLeftField"];
	[join setValue: rightJoinField forKey: @"hasRightField"];
	[join setValue: root forKey: @"inQuery"];

	RptqObject *out0 = [context insertObjectForEntity: @"RptqQueryField" identifier: 600];
	[out0 setValue: invoiceIdField forKey: @"databaseSchemaField"];
	[out0 setValue: rootInvoicesTable forKey: @"inQueryTable"];
	[out0 setValue: @"invoice_id" forKey: @"outputKey"];
	[out0 setValue: @0 forKey: @"outputIndex"];
	RptqObject *out1 = [context insertObjectForEntity: @"RptqQueryField" identifier: 601];
	[out1 setValue: @1 forKey: @"outputIndex"];
	RptqObject *out2 = [context insertObjectForEntity: @"RptqQueryField" identifier: 602];
	[out2 setValue: @2 forKey: @"outputIndex"];
	if (reordered) {
		[out1 setValue: rootPaymentsTable forKey: @"inQueryTable"];
		[out1 setValue: paymentAmountField forKey: @"databaseSchemaField"];
		[out1 setValue: @"payment_amount" forKey: @"outputKey"];
		[out2 setValue: rootInvoicesTable forKey: @"inQueryTable"];
		[out2 setValue: invoiceAmountField forKey: @"databaseSchemaField"];
		[out2 setValue: @"invoice_amount" forKey: @"outputKey"];
	} else {
		[out1 setValue: rootInvoicesTable forKey: @"inQueryTable"];
		[out1 setValue: invoiceAmountField forKey: @"databaseSchemaField"];
		[out1 setValue: @"invoice_amount" forKey: @"outputKey"];
		[out2 setValue: rootPaymentsTable forKey: @"inQueryTable"];
		[out2 setValue: paymentAmountField forKey: @"databaseSchemaField"];
		[out2 setValue: @"payment_amount" forKey: @"outputKey"];
	}

	[document setValue: root forKey: @"rootQuery"];

	if (![context saveComposed: &error]) {
		fprintf(stderr, "composed save failed: %s\n", error.localizedDescription.UTF8String);
		return 1;
	}
	[store close];

	MADArchiveManager *writer = [[MADArchiveManager alloc] initWithFileWrapperURL: store.gutsURL archiveURL: documentURL];
	writer.composed = YES;
	if (![writer archive: YES]) {
		fprintf(stderr, "composed archive failed\n");
		return 1;
	}
	printf("wrote %s (invoices and payments beside it)\n", documentURL.path.UTF8String);
	return 0;
}

#pragma mark - main

int main(int argc, const char *argv[]) {
	@autoreleasepool {

		if (argc >= 2 && strcmp(argv[1], "portable") == 0) {
			if (argc != 4) {
				fprintf(stderr, "usage: MADFixtureMaker portable <document.mad> <fixture.mad>\n");
				return 1;
			}
			return MADFixtureWritePortableCopy([NSURL fileURLWithPath: [NSString stringWithUTF8String: argv[2]]],
											   [NSURL fileURLWithPath: [NSString stringWithUTF8String: argv[3]]]);
		}

		if (argc >= 2 && strcmp(argv[1], "create") == 0) {
			if (argc != 9) {
				fprintf(stderr, "usage: MADFixtureMaker create <mysql|tds|postgres> <host> <port> <user> <password> <database> <out.mad>\n");
				return 1;
			}
			NSString *driver = [NSString stringWithUTF8String: argv[2]];
			NSString *host = [NSString stringWithUTF8String: argv[3]];
			NSInteger port = [[NSString stringWithUTF8String: argv[4]] integerValue];
			NSString *user = [NSString stringWithUTF8String: argv[5]];
			NSString *password = [NSString stringWithUTF8String: argv[6]];
			NSString *database = [NSString stringWithUTF8String: argv[7]];
			NSURL *outputURL = [NSURL fileURLWithPath: [NSString stringWithUTF8String: argv[8]]];

			MADDatabaseConnection *connection = nil;
			if ([driver isEqualToString: @"mysql"]) {
				connection = [[MADDatabaseConnectionMySql alloc] initWithHost: host database: database andPort: port];
			} else if ([driver isEqualToString: @"tds"]) {
				connection = [[MADDatabaseConnectionSQLServer alloc] initWithHost: host server: host
																		 database: database andPort: port];
			} else if ([driver isEqualToString: @"postgres"]) {
				connection = [[MADDatabaseConnectionPostgres alloc] initWithHost: host database: database andPort: port];
			} else {
				fprintf(stderr, "unknown driver '%s' (mysql, tds, or postgres)\n", driver.UTF8String);
				return 1;
			}

			MADCredential *credential = [[MADCredential alloc] initWithUsername: user andPassword: password];
			return MADFixtureCreateDocument(connection, credential, outputURL);
		}

		if (argc >= 2 && strcmp(argv[1], "select") == 0) {
			if (argc != 5) {
				fprintf(stderr, "usage: MADFixtureMaker select <document.mad> <table> <field>[,<field>...]\n");
				return 1;
			}
			NSString *tableName = [NSString stringWithUTF8String: argv[3]];
			NSArray <NSString *> *fieldNames = [[NSString stringWithUTF8String: argv[4]] componentsSeparatedByString: @","];
			if ([fieldNames isEqualToArray: @[ @"" ]]) fieldNames = @[];
			return MADFixtureSelectFields([NSURL fileURLWithPath: [NSString stringWithUTF8String: argv[2]]],
										  tableName, fieldNames);
		}

		if (argc >= 2 && strcmp(argv[1], "compose") == 0) {
			if (argc != 3 && argc != 4) {
				fprintf(stderr, "usage: MADFixtureMaker compose <document.mad> [reorder]\n");
				return 1;
			}
			BOOL reordered = (argc == 4 && strcmp(argv[3], "reorder") == 0);
			return MADFixtureCompose([NSURL fileURLWithPath: [NSString stringWithUTF8String: argv[2]]], reordered);
		}

		fprintf(stderr, "usage: MADFixtureMaker portable <document.mad> <fixture.mad>\n"
						"       MADFixtureMaker create <mysql|tds|postgres> <host> <port> <user> <password> <database> <out.mad>\n"
						"       MADFixtureMaker select <document.mad> <table> <field>[,<field>...]\n"
						"       MADFixtureMaker compose <document.mad> [reorder]\n");
		return 1;
	}
}
