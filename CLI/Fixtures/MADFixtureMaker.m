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
//      nothing off Apple can convert one (Core Data, docs/project/MAD_LINUX.md §5.1).
//
//    MADFixtureMaker create <mysql|tds> <host> <port> <user> <password> <database> <out.mad>
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
#import <MAD/MADOperationCreateDocumentAddConnection.h>
#import <MAD/MADOperationCreateDocumentCreateDocument.h>
#import <MAD/MADOperationCreateDocumentFirstTimeSetup.h>
#import <MAD/MADOperationCreateDocumentImportSchema.h>
#import <MAD/MADOperationDocumentCloseDocument.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADOperationUniqueUrlForFilename.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqStoreContext.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseType.h>

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADOperationQueue.h>

#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADTdsClient/MADDatabaseConnectionSQLServer.h>

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
				fprintf(stderr, "usage: MADFixtureMaker create <mysql|tds> <host> <port> <user> <password> <database> <out.mad>\n");
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
			} else {
				fprintf(stderr, "unknown driver '%s' (mysql or tds)\n", driver.UTF8String);
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

		fprintf(stderr, "usage: MADFixtureMaker portable <document.mad> <fixture.mad>\n"
						"       MADFixtureMaker create <mysql|tds> <host> <port> <user> <password> <database> <out.mad>\n"
						"       MADFixtureMaker select <document.mad> <table> <field>[,<field>...]\n");
		return 1;
	}
}
