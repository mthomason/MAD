//
//  MADOperationRefresh.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADOperationRefresh.h"
#import "MADOperationRefreshInitialize.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADQuery.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADDataColumn.h>

#import <MADSqlite3/MADDataTableFast.h>

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADConstants.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADQueryFull.h>

#import "MADComposer.h"
#import "MADDatabase+Constructor.h"
#import "MADDatabaseConnection+Constructor.h"
#import "RptqDocument+Extras.h"
#import "RptqDocument.h"
#import "RptqQuery.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryLinks.h"
#import "RptqQueryField.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseCredentals+Extras.h"

#import <Foundation/NSFileManager.h>
#import <Foundation/NSUUID.h>


// The operation's own domain.  It used to borrow @"MADCache" for a missing
// credential, which reads as a fault in the result cache rather than in the
// credentials the caller never supplied.
static NSString * const MADOperationRefreshErrorDomain = @"com.everydayapps.operation.refresh";

static const short errCache = 2;
static const short errMissingCredentials = 3;
static const short errExecute = 4;
static const short errNoPendingResult = 5;
static const short errNoDocument = 3842;

// The portable store context is main-queue-owned.  Marshal store reads onto
// the main queue (inline when already there) rather than taking a lock in
// every accessor.  See docs/project/registers/BUGS.md "The refresh path reads the shared store
// context from operation-queue threads".
static void MADOperationRefreshRunOnMain(dispatch_block_t block) {
	if ([NSThread isMainThread]) block();
	else dispatch_sync(dispatch_get_main_queue(), block);
}

@interface MADDataResult ()
@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) MADDataTableFast *dataTable;
@property (nonatomic, copy, readwrite) NSURL *rowDatabaseURL;
@property (nonatomic, copy, readwrite) NSURL *columnMapURL;
@end

@implementation MADDataResult

- (instancetype)initWithIdentifier:(NSString *)identifier
                         dataTable:(MADDataTableFast *)dataTable
                    rowDatabaseURL:(NSURL *)rowDatabaseURL
                      columnMapURL:(NSURL *)columnMapURL {
	if (self = [super init]) {
		_identifier = [identifier copy];
		_dataTable = dataTable;
		_rowDatabaseURL = [rowDatabaseURL copy];
		_columnMapURL = [columnMapURL copy];
	}
	return self;
}

+ (instancetype)resultWithDataTable:(MADDataTableFast *)dataTable
					   columnMapURL:(NSURL *)columnMapURL {
	if (dataTable == nil) return nil;
	NSURL *rowDatabaseURL = dataTable.rowDatabaseURL;
	NSString *identifier = rowDatabaseURL.lastPathComponent.stringByDeletingPathExtension ?: @"";
	return [[self alloc] initWithIdentifier:identifier
								  dataTable:dataTable
							 rowDatabaseURL:rowDatabaseURL
							   columnMapURL:columnMapURL];
}

- (NSArray<NSString *> *)columnKeys {
	NSMutableArray<NSString *> *keys = [NSMutableArray arrayWithCapacity:self.dataTable.columnKeys.count];
	for (NSString *physicalKey in self.dataTable.columnKeys) {
		MADDataColumn *column = self.dataTable.columns[physicalKey];
		[keys addObject:column.identifier ?: physicalKey];
	}
	return keys;
}

- (NSDictionary<NSString *, MADDataColumn *> *)columns {
	NSMutableDictionary<NSString *, MADDataColumn *> *columns =
		[NSMutableDictionary dictionaryWithCapacity:self.dataTable.columns.count];
	for (MADDataColumn *column in self.dataTable.columns.allValues) {
		NSString *key = column.identifier ?: column.fieldName;
		if (key != nil) columns[key] = column;
	}
	return columns;
}

- (NSUInteger)numberOfRows {
	return self.dataTable.numberOfRows;
}

@end

@interface MADOperationRefresh ()
@property (nonatomic, weak) id <MADDocumentDataProtocol> document;
@end

@implementation MADOperationRefresh

- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document {
	if (self = [super init]) {
		_document = document;
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	id <MADDocumentDataProtocol> document = self.document;
	if (self.cancelled) {
		[document discardPendingResult];
		return [self finish];
	}

	if (!document) {
		NSError *docNullError = [[NSError alloc] initWithDomain: MADOperationRefreshErrorDomain
														   code: errNoDocument
													   userInfo: nil];
		[self finishWithError:docNullError];
		return;
	}

	// Never write into the live result: the initializer must have staged one.
	if (document.pendingResult == nil) {
		NSError *error = [NSError errorWithDomain: MADOperationRefreshErrorDomain
											code: errNoPendingResult
										userInfo: @{
			NSLocalizedDescriptionKey : NSLocalizedString(@"The refresh result was not staged.", @"No staged result to fill."),
			NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"The refresh's initializer did not create a pending result.", @"The refresh's initializer did not create a pending result.")
		}];
		[self finishWithError:error];
		return;
	}

	MADCredential *credientals = nil;
	if (document.database.delegate == nil) {
		document.database.delegate = (id <MADDatabaseResultsProtocol>)document;
	}
	
	if ([document.database.databaseConnection requiresCredentials]) {
		
		for (NSOperation *dependency in self.dependencies) {
			if ([dependency conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)] &&
				((id <MADOperationHoldsCredentialsProtocol>)dependency).gotCredentials) {
				credientals = ((id <MADOperationHoldsCredentialsProtocol>)dependency).credentials;
			}
		}
		
		if (credientals == nil) {
			// This is a missing credential, not a cache fault: the database wants
			// credentials and no dependency supplied any.  It used to report domain
			// @"MADCache" with code errCache + 1, which points the reader at the
			// result cache.  See docs/project/registers/BUGS.md.
			NSError *error = [NSError errorWithDomain: MADOperationRefreshErrorDomain
												 code: errMissingCredentials
											 userInfo: @{
				NSLocalizedDescriptionKey : NSLocalizedString(@"Credentials required", @"Credentials required"),
				NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"The database requires credentials and none were supplied.", @"The database requires credentials and none were supplied.")
			}];
			[document discardPendingResult];
			[self finishWithError:error];
			return;
		}
	}

	NSError * __autoreleasing eerror = NULL;
	MADDatabaseConnection *connectionSettings = (document.database).databaseConnection;
	id dbconn = [document.database connectWithConnection: connectionSettings
											  credentals: credientals
										 connectionError: &eerror];
	
	if (eerror != nil) {
		NSError *error = [eerror copy];
		[document discardPendingResult];
		[self finishWithError:error];
		return;
	}

	// The SQL build walks the whole query graph, so it runs on main with the
	// rest of the store reads; only the built string and the field keys cross
	// back to this operation thread.
	__block NSString *queryString = nil;
	__block NSArray *fieldKeys = nil;
	MADOperationRefreshRunOnMain(^{
		RptqStoreContext *private = document.storeContext;
		MADQueryFull *query = document.mainQuery;
		NSError *sqlError = nil;
		queryString = [query copySQLWithManagedObjectContext: private error: &sqlError];
		if (sqlError != nil) {
			os_log_error(OS_LOG_DEFAULT, "Error: %@", sqlError);
		}
		fieldKeys = query.fieldKeys;
	});
	[document dataTableSetDataDelegate:document];

	// Stage the rows in the refresh's own table; the current result stays the
	// one consumers read until -publishPendingResultWithError: succeeds.
	MADDataTableFast *resultTable = document.pendingResult.dataTable;
	NSError *executeError = nil;
	BOOL success = [document.database executeSQL: queryString
									   fieldKeys: fieldKeys
									onConnection: dbconn
								 intoResultTable: (MADDataTable *)resultTable
									   withError: &executeError];

	if (executeError != nil) {
		os_log_error(OS_LOG_DEFAULT, "Error: %@", executeError);
	}

	if (!success) {
		// eerror is the *connection* error, and it cannot be set here: the connection
		// succeeded, or -connectWithConnection:credentals:connectionError: would have
		// returned above.  Finishing with it completed the operation with an empty
		// error list, so a query that failed was indistinguishable from one that
		// succeeded -- and the cache still held the previous run's rows, which is
		// what the caller saw.  executeError is what the driver reported.  See docs/project/registers/BUGS.md.
		NSError *error = executeError;
		if (error == nil) {
			error = [NSError errorWithDomain: MADOperationRefreshErrorDomain
										code: errExecute
									userInfo: @{
				NSLocalizedDescriptionKey : NSLocalizedString(@"The query failed", @"The query failed"),
				NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"The database driver reported no error.", @"The database driver reported no error.")
			}];
		}
		[document discardPendingResult];
		[self finishWithError:error];
		return;
	}

	NSError *publishError = nil;
	if (![document publishPendingResultWithError: &publishError]) {
		[document discardPendingResult];
		NSError *error = publishError ?: [NSError errorWithDomain:@"MADCache" code:errCache userInfo:nil];
		[self finishWithError:error];
		return;
	}
	document.refreshed = YES;

	[self finish];
}

@end

#pragma mark - Composed refresh

// MADocument and MADHeadlessDocument both expose -fileURL; the data protocol does
// not, so the coordinator reaches it through this declaration (the same selector
// MADOperationRefreshInitialize uses to resolve a source's connection).
@interface NSObject (MADComposedRefreshDocumentURL)
- (NSURL *)fileURL;
@end

/// The plain-data snapshot of one source, captured on the store's owning queue so
/// the database I/O that follows runs without touching the store.
@interface MADComposedSourcePlan : NSObject
@property (nonatomic, copy) NSString *name;               // the source query's name (alias)
@property (nonatomic, strong) MADDatabase *database;      // the source's own connection and dialect
@property (nonatomic, copy) NSString *sql;                // the compiled SELECT
@property (nonatomic, copy) NSArray<NSString *> *fieldKeys; // the projection's logical keys, in order
@property (nonatomic, copy) NSString *joinKey;            // the full logical key this source joins on
@property (nonatomic, strong) MADDataResult *result;      // the published source result, after refresh
@end

/// One projected root column, in the caller's order, naming which source it reads.
@interface MADComposedOutputPlan : NSObject
@property (nonatomic, assign) NSInteger sourceIndex;      // 0 = left, 1 = right
@property (nonatomic, copy) NSString *sourceKey;
@property (nonatomic, copy) NSString *outputKey;
@end

@implementation MADComposedSourcePlan
@end

@implementation MADComposedOutputPlan
@end

/// The full logical key a root field reads from its source: the source query table's
/// alias plus the schema field name, the same spelling the source's SELECT writes
/// ("Invoices0.InvoiceId").  A root field owns its source through its query table's
/// upstream reference.
static NSString *MADComposedLogicalKeyForField(RptqQueryField *rootField, MADDatabase *database) {
	RptqQuery *sourceQuery = rootField.inQueryTable.upstreamQuery;
	RptqDatabaseSchemaField *schemaField = rootField.databaseSchemaField;
	if (sourceQuery == nil || schemaField == nil) return nil;
	int64_t tableIdentifier = schemaField.inTable.identifier;
	for (RptqQueryTable *table in sourceQuery.hasQueryTables) {
		if (table.databaseSchemaTable.identifier == tableIdentifier) {
			return [database queryKey: schemaField.name table: table.queryAlias];
		}
	}
	return nil;
}

@implementation MADOperationRefreshComposed {
	id <MADDocumentDataProtocol> _document;
}

- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document {
	if (self = [super init]) {
		_document = document;
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	id <MADDocumentDataProtocol> document = _document;
	if (self.cancelled) {
		[document discardPendingResult];
		return [self finish];
	}
	if (document == nil) {
		[self finishWithError:[NSError errorWithDomain: MADOperationRefreshErrorDomain
												 code: errNoDocument
											 userInfo: nil]];
		return;
	}

	NSURL *documentURL = [document respondsToSelector:@selector(fileURL)] ? [(id)document fileURL] : nil;
	NSURL *cacheDirectory = document.urlDataTableCache.URLByDeletingLastPathComponent;

	// Resolve the graph on the store's owning queue, and capture everything the
	// database I/O below needs as plain data.
	__block MADComposedSourcePlan *leftPlan = nil;
	__block MADComposedSourcePlan *rightPlan = nil;
	__block NSArray<MADComposedOutputPlan *> *outputPlans = nil;
	__block MADLinkType joinType = MADLinkTypeLeftOuterJoin;
	__block NSError *resolveError = nil;
	MADOperationRefreshRunOnMain(^{
		RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
		if (![model validateCompositionGraphWithError: &resolveError]) return;

		NSArray<RptqQueryField *> *outputs = [model orderedCompositionOutputsWithError: &resolveError];
		if (outputs == nil) return;

		RptqQueryLinks *join = model.rootQuery.hasQueryLinks.anyObject;
		if (join == nil || join.hasLeftField == nil || join.hasRightField == nil) {
			resolveError = [NSError errorWithDomain: MADOperationRefreshErrorDomain code: errExecute userInfo: @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"The composed document has no join between its sources.",
															  @"Missing composition join.") }];
			return;
		}
		joinType = (MADLinkType)join.type;

		RptqQuery *leftQuery = join.hasLeftField.inQueryTable.upstreamQuery;
		RptqQuery *rightQuery = join.hasRightField.inQueryTable.upstreamQuery;
		if (leftQuery == nil || rightQuery == nil) {
			resolveError = [NSError errorWithDomain: MADOperationRefreshErrorDomain code: errExecute userInfo: @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"A join side references a missing source.",
															  @"Missing composition source.") }];
			return;
		}

		// Every output field and every join key must be present in its source's
		// projection.  Collect them by source, then resolve each to the source's
		// own query fields so the downstream-only join key is projected too.
		NSMutableDictionary<NSNumber *, NSMutableSet<NSNumber *> *> *requiredSchemaIds = [NSMutableDictionary dictionary];
		void (^requireField)(RptqQueryField *) = ^(RptqQueryField *field) {
			NSNumber *sourceId = @(field.inQueryTable.upstreamQuery.identifier);
			NSMutableSet<NSNumber *> *ids = requiredSchemaIds[sourceId];
			if (ids == nil) { ids = [NSMutableSet set]; requiredSchemaIds[sourceId] = ids; }
			[ids addObject: @(field.databaseSchemaField.identifier)];
		};
		for (RptqQueryField *output in outputs) requireField(output);
		requireField(join.hasLeftField);
		requireField(join.hasRightField);

		NSArray<RptqQueryField *> *(^requiredForSource)(RptqQuery *) = ^(RptqQuery *source) {
			NSMutableArray<RptqQueryField *> *required = [NSMutableArray array];
			NSSet<NSNumber *> *ids = requiredSchemaIds[@(source.identifier)];
			for (RptqQueryTable *table in source.hasQueryTables) {
				for (RptqQueryField *field in table.hasQueryFields) {
					if ([ids containsObject: @(field.databaseSchemaField.identifier)]) {
						[required addObject: field];
					}
				}
			}
			return required;
		};

		MADComposedSourcePlan *(^planForSource)(RptqQuery *, RptqQueryField *) = ^(RptqQuery *source, RptqQueryField *joinField) {
			RptqDatabase *rptqDatabase = source.inDatabase;
			NSObject <MADConnectionsPropertiesProtocol> *user =
				(NSObject <MADConnectionsPropertiesProtocol> *)rptqDatabase.ownedByUser;
			MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnection: user documentURL: documentURL];
			MADDatabase *database = [MADDatabase newDatabaseWithConnection: connection];

			MADQueryFull *query = [[MADQueryFull alloc] initWithQuery: source andQueryLimit: NSUIntegerMax];
			query.database = database;
			query.requiredQueryFields = requiredForSource(source);

			NSError *sqlError = nil;
			NSString *sql = [query copySQLWithManagedObjectContext: document.storeContext error: &sqlError];
			if (sql.length == 0) { resolveError = sqlError; return (MADComposedSourcePlan *)nil; }

			MADComposedSourcePlan *plan = [[MADComposedSourcePlan alloc] init];
			plan.name = source.name;
			plan.database = database;
			plan.sql = sql;
			plan.fieldKeys = query.fieldKeys;
			plan.joinKey = MADComposedLogicalKeyForField(joinField, database);
			return plan;
		};

		leftPlan = planForSource(leftQuery, join.hasLeftField);
		if (leftPlan == nil) return;
		rightPlan = planForSource(rightQuery, join.hasRightField);
		if (rightPlan == nil) return;

		NSMutableArray<MADComposedOutputPlan *> *plans = [NSMutableArray arrayWithCapacity: outputs.count];
		for (RptqQueryField *output in outputs) {
			NSInteger sourceIndex = (output.inQueryTable.upstreamQuery.identifier == leftQuery.identifier) ? 0 : 1;
			MADComposedSourcePlan *owner = sourceIndex == 0 ? leftPlan : rightPlan;
			MADComposedOutputPlan *plan = [[MADComposedOutputPlan alloc] init];
			plan.sourceIndex = sourceIndex;
			plan.sourceKey = MADComposedLogicalKeyForField(output, owner.database);
			plan.outputKey = output.outputKey;
			[plans addObject: plan];
		}
		outputPlans = plans;
	});
	if (resolveError != nil) {
		[self finishWithError: resolveError];
		return;
	}
	if (leftPlan == nil || rightPlan == nil || outputPlans == nil) {
		[self finishWithError:[NSError errorWithDomain: MADOperationRefreshErrorDomain code: errExecute userInfo: @{
			NSLocalizedDescriptionKey: NSLocalizedString(@"The composed document could not be resolved.",
														  @"Composition resolution failure.") }]];
		return;
	}

	// Credentials come from a dependency, the way the ordinary refresh takes them.
	MADCredential *credentials = nil;
	for (NSOperation *dependency in self.dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)] &&
			((id <MADOperationHoldsCredentialsProtocol>)dependency).gotCredentials) {
			credentials = ((id <MADOperationHoldsCredentialsProtocol>)dependency).credentials;
		}
	}

	// Refresh each source once, serially, staging its rows in a fresh table.
	MADDataResult *(^refreshSource)(MADComposedSourcePlan *) = ^(MADComposedSourcePlan *plan) {
		MADDatabase *database = plan.database;
		if ([database.databaseConnection requiresCredentials] && credentials == nil) {
			NSError *missing = [NSError errorWithDomain: MADOperationRefreshErrorDomain code: errMissingCredentials userInfo: @{
				NSLocalizedDescriptionKey: [NSString stringWithFormat:
					NSLocalizedString(@"The source '%@' requires credentials and none were supplied.", @"Missing credentials for a source."), plan.name] }];
			[self finishWithError: missing];
			return (MADDataResult *)nil;
		}

		NSError *connectError = nil;
		id dbconn = [database connectWithConnection: database.databaseConnection
										  credentals: credentials
									 connectionError: &connectError];
		if (connectError != nil) {
			NSError *wrapped = [NSError errorWithDomain: MADOperationRefreshErrorDomain code: errExecute userInfo: @{
				NSLocalizedDescriptionKey: [NSString stringWithFormat:
					NSLocalizedString(@"The source '%@' could not connect: %@", @"Source connection failure."),
					plan.name, connectError.localizedDescription] }];
			[self finishWithError: wrapped];
			return (MADDataResult *)nil;
		}

		NSString *identifier = NSUUID.UUID.UUIDString;
		MADDataTableFast *table = [[MADDataTableFast alloc] initWithId: identifier.hash cacheDirectory: cacheDirectory];
		table.cacheFileIdentifier = identifier;

		NSError *executeError = nil;
		BOOL success = [database executeSQL: plan.sql
								  fieldKeys: plan.fieldKeys
							   onConnection: dbconn
							intoResultTable: (MADDataTable *)table
								  withError: &executeError];
		[database closeConnection: dbconn];
		if (!success || executeError != nil) {
			[table closeConnections];
			NSError *wrapped = [NSError errorWithDomain: MADOperationRefreshErrorDomain code: errExecute userInfo: @{
				NSLocalizedDescriptionKey: [NSString stringWithFormat:
					NSLocalizedString(@"The source '%@' failed: %@", @"Source query failure."),
					plan.name, (executeError.localizedDescription ?: NSLocalizedString(@"the query reported no error", @"No driver error."))] }];
			[self finishWithError: wrapped];
			return (MADDataResult *)nil;
		}

		NSURL *columnMap = [cacheDirectory URLByAppendingPathComponent: [identifier stringByAppendingPathExtension: @"mdcache"]];
		[table cacheWithUrl: columnMap error: NULL];
		return [[MADDataResult alloc] initWithIdentifier: identifier
											   dataTable: table
										  rowDatabaseURL: table.rowDatabaseURL
											columnMapURL: columnMap];
	};

	leftPlan.result = refreshSource(leftPlan);
	if (leftPlan.result == nil) return;
	rightPlan.result = refreshSource(rightPlan);
	if (rightPlan.result == nil) { [self discardSourceResult: leftPlan]; return; }

	// The inputs and the ordered projection, handed to the composer.
	MADComposerInput *leftInput = [[MADComposerInput alloc] init];
	leftInput.alias = leftPlan.name;
	leftInput.result = leftPlan.result;
	leftInput.joinKey = leftPlan.joinKey;
	MADComposerInput *rightInput = [[MADComposerInput alloc] init];
	rightInput.alias = rightPlan.name;
	rightInput.result = rightPlan.result;
	rightInput.joinKey = rightPlan.joinKey;

	NSMutableArray<MADComposerProjection *> *projections = [NSMutableArray arrayWithCapacity: outputPlans.count];
	for (MADComposedOutputPlan *output in outputPlans) {
		MADComposerInput *input = output.sourceIndex == 0 ? leftInput : rightInput;
		[projections addObject: [MADComposerProjection projectionWithInput: input
																sourceKey: output.sourceKey
																outputKey: output.outputKey]];
	}

	// Stage the root the ordinary way, compose into it, then publish.
	MADDataResult *pending = [document beginRefreshResultWithError: nil];
	if (pending == nil) {
		[self discardSourceResult: leftPlan];
		[self discardSourceResult: rightPlan];
		[self finishWithError:[NSError errorWithDomain: MADOperationRefreshErrorDomain code: errNoPendingResult userInfo: @{
			NSLocalizedDescriptionKey: NSLocalizedString(@"The refresh result was not staged.", @"No staged result to fill.") }]];
		return;
	}

	NSError *composeError = nil;
	BOOL composed = [MADComposer composeLeft: leftInput
									  right: rightInput
								   joinType: joinType
							   projections: projections
								orderByKeys: nil
							 cacheDirectory: cacheDirectory
								 intoTable: pending.dataTable
									 error: &composeError];

	[self discardSourceResult: leftPlan];
	[self discardSourceResult: rightPlan];

	if (!composed) {
		[document discardPendingResult];
		[self finishWithError: composeError ?: [NSError errorWithDomain: MADOperationRefreshErrorDomain code: errExecute userInfo: @{
			NSLocalizedDescriptionKey: NSLocalizedString(@"The composition join failed.", @"Composition join failure.") }]];
		return;
	}

	NSError *publishError = nil;
	if (![document publishPendingResultWithError: &publishError]) {
		[document discardPendingResult];
		[self finishWithError: publishError ?: [NSError errorWithDomain:@"MADCache" code:errCache userInfo:nil]];
		return;
	}
	document.refreshed = YES;
	[self finish];
}

- (void)discardSourceResult:(MADComposedSourcePlan *)plan {
	MADDataTableFast *table = plan.result.dataTable;
	NSURL *rowURL = plan.result.rowDatabaseURL;
	NSURL *columnMapURL = plan.result.columnMapURL;
	NSUInteger tag = table.tag;
	plan.result = nil;
	[table closeConnections];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtURL: rowURL error: NULL];
	[fileManager removeItemAtURL: columnMapURL error: NULL];
	// The table opened its writer on a tag-named file before the generation
	// identifier was set; that empty file is removed too, so a source stage leaves
	// nothing behind once its handles close.
	NSURL *tagURL = [[rowURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:
		[[NSString stringWithFormat: @"%lu", (unsigned long)tag] stringByAppendingPathExtension: @"maddb"]];
	[fileManager removeItemAtURL: tagURL error: NULL];
}

@end
