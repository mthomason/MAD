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

#import "MADQueryPredicate.h"
#import "MADDatabase+Constructor.h"
#import "MADDatabaseConnection+Constructor.h"
#import "RptqDocument+Extras.h"
#import "RptqDocument.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryLinks.h"
#import "RptqQueryField.h"
#import "RptqQueryPredicate.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseCredentals+Extras.h"

#import <MADDataStructures/MTGraph.h>
#import <MADDataStructures/MTVertex.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>

#import <sqlite3.h>

#import <Foundation/NSFileManager.h>
#import <Foundation/NSUUID.h>


// The operation's own domain.  It used to borrow @"MADCache" for a missing
// credential, which reads as a fault in the result cache rather than in the
// credentials the caller never supplied.
static NSString * const MADOperationRefreshErrorDomain = @"com.everydayapps.operation.refresh";

NSString * const MADOperationRefreshSourceNameKey = @"MADOperationRefreshSourceName";
NSString * const MADOperationRefreshSourceConnectionStringKey = @"MADOperationRefreshSourceConnectionString";

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

+ (BOOL)documentUsesComposedRefresh:(id <MADDocumentDataProtocol>)document {
	return document.activeDocumentModel.rootQuery != nil;
}

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

/// One node in the composition graph, captured as plain data on the store's owning
/// queue so the database I/O that follows runs without touching the store.
@interface MADComposedNodePlan : NSObject
@property (nonatomic) int64_t identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL composing;                    // YES when it joins children, NO for a leaf
@property (nonatomic, strong) RptqQuery *query;                  // held for a composing compile
@property (nonatomic, strong) MADDatabase *database;             // a leaf's own dialect; a composing node's scratch SQLite
@property (nonatomic, copy) NSString *sql;                       // a leaf's pre-compiled SELECT
@property (nonatomic, copy) NSArray<NSString *> *fieldKeys;      // a leaf's projection keys, in order
@property (nonatomic, copy) NSArray<NSNumber *> *childIdentifiers; // a composing node's children, in attach order
@property (nonatomic, strong) MADDataResult *result;             // the published node result, after it runs
@end

@implementation MADComposedNodePlan
@end

@implementation MADOperationRefreshComposed {
	id <MADDocumentDataProtocol> _document;
	NSMutableArray<NSString *> *_executedNodeNames;
}

- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document {
	if (self = [super init]) {
		_document = document;
		_executedNodeNames = [NSMutableArray array];
	}
	return self;
}

- (NSArray<NSString *> *)executedNodeNames {
	return [_executedNodeNames copy];
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

	// Resolve the graph on the store's owning queue, capturing everything the
	// database I/O below needs as plain data.
	__block NSArray<MADComposedNodePlan *> *orderedPlans = nil;
	__block NSDictionary<NSNumber *, MADComposedNodePlan *> *plansByIdentifier = nil;
	__block NSError *resolveError = nil;
	MADOperationRefreshRunOnMain(^{
		RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
		if (![model validateCompositionGraphWithError: &resolveError]) return;

		// Collect every reachable node by following upstream references.
		NSMutableDictionary<NSNumber *, RptqQuery *> *nodesByIdentifier = [NSMutableDictionary dictionary];
		NSMutableArray<RptqQuery *> *stack = [NSMutableArray arrayWithObject: model.rootQuery];
		while (stack.count > 0) {
			RptqQuery *node = [stack lastObject];
			[stack removeLastObject];
			NSNumber *key = @(node.identifier);
			if (nodesByIdentifier[key] != nil) continue;
			nodesByIdentifier[key] = node;
			for (RptqQueryTable *table in node.hasQueryTables) {
				if (table.upstreamQuery != nil) [stack addObject: table.upstreamQuery];
			}
		}

		NSArray<RptqQuery *> *orderedNodes = [self topologicalOrderOfNodes: nodesByIdentifier error: &resolveError];
		if (orderedNodes == nil) return;

		// The fields each leaf must project: every field a composing parent references
		// through its outputs, links, and predicates.
		NSMutableDictionary<NSNumber *, NSMutableSet<NSNumber *> *> *requiredSchemaIds = [NSMutableDictionary dictionary];
		void (^requireField)(RptqQueryField *) = ^(RptqQueryField *field) {
			if (field == nil) return;
			RptqQuery *upstream = field.inQueryTable.upstreamQuery;
			if (upstream == nil || field.databaseSchemaField == nil) return;
			NSNumber *childKey = @(upstream.identifier);
			NSMutableSet<NSNumber *> *ids = requiredSchemaIds[childKey];
			if (ids == nil) { ids = [NSMutableSet set]; requiredSchemaIds[childKey] = ids; }
			[ids addObject: @(field.databaseSchemaField.identifier)];
		};
		for (RptqQuery *node in orderedNodes) {
			if (node.hasQueryTables.anyObject.upstreamQuery == nil) continue;
			NSArray<RptqQueryField *> *outputs = [node orderedOutputFieldsWithError: NULL];
			for (RptqQueryField *output in outputs) requireField(output);
			for (RptqQueryLinks *link in node.hasQueryLinks) {
				requireField(link.hasLeftField);
				requireField(link.hasRightField);
			}
			for (RptqQueryPredicate *predicate in node.hasQueryPredicate) {
				requireField(predicate.hasLeftField);
				requireField(predicate.hasRightField);
			}
		}

		NSMutableArray<MADComposedNodePlan *> *plans = [NSMutableArray arrayWithCapacity: orderedNodes.count];
		NSMutableDictionary<NSNumber *, MADComposedNodePlan *> *byId = [NSMutableDictionary dictionaryWithCapacity: orderedNodes.count];
		for (RptqQuery *node in orderedNodes) {
			MADComposedNodePlan *plan = [[MADComposedNodePlan alloc] init];
			plan.identifier = node.identifier;
			plan.name = node.name;
			plan.query = node;
			plan.composing = node.hasQueryTables.anyObject.upstreamQuery != nil;

			if (plan.composing) {
				NSMutableArray<NSNumber *> *childIdentifiers = [NSMutableArray array];
				NSMutableSet<NSNumber *> *seen = [NSMutableSet set];
				for (RptqQueryTable *table in node.hasQueryTables) {
					if (table.upstreamQuery == nil) continue;
					NSNumber *childKey = @(table.upstreamQuery.identifier);
					if (![seen containsObject: childKey]) {
						[seen addObject: childKey];
						[childIdentifiers addObject: childKey];
					}
				}
				[childIdentifiers sortUsingComparator: ^NSComparisonResult(NSNumber *a, NSNumber *b) {
					return [a compare: b];
				}];
				plan.childIdentifiers = childIdentifiers;
			} else {
				RptqDatabase *rptqDatabase = node.inDatabase;
				NSObject <MADConnectionsPropertiesProtocol> *user = (NSObject <MADConnectionsPropertiesProtocol> *)rptqDatabase.ownedByUser;
				MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnection: user documentURL: documentURL];
				MADDatabase *database = [MADDatabase newDatabaseWithConnection: connection];
				plan.database = database;

				NSSet<NSNumber *> *ids = requiredSchemaIds[@(node.identifier)];
				NSMutableArray<RptqQueryField *> *requiredFields = [NSMutableArray array];
				for (RptqQueryTable *table in node.hasQueryTables) {
					for (RptqQueryField *field in table.hasQueryFields) {
						if (ids != nil && [ids containsObject: @(field.databaseSchemaField.identifier)]) {
							[requiredFields addObject: field];
						}
					}
				}

				MADQueryFull *query = [[MADQueryFull alloc] initWithQuery: node andQueryLimit: NSUIntegerMax];
				query.database = database;
				query.requiredQueryFields = requiredFields.count > 0 ? requiredFields : nil;
				NSError *sqlError = nil;
				NSString *sql = [query copySQLWithManagedObjectContext: document.storeContext error: &sqlError];
				if (sql.length == 0) { resolveError = sqlError; return; }
				plan.sql = sql;
				plan.fieldKeys = query.fieldKeys;
			}
			[plans addObject: plan];
			byId[@(node.identifier)] = plan;
		}
		orderedPlans = plans;
		plansByIdentifier = byId;
	});

	if (resolveError != nil) {
		[self finishWithError: resolveError];
		return;
	}
	if (orderedPlans == nil || orderedPlans.count == 0) {
		[self finishWithError:[NSError errorWithDomain: MADOperationRefreshErrorDomain code: errExecute userInfo: @{
			NSLocalizedDescriptionKey: NSLocalizedString(@"The composed document could not be resolved.", @"Composition resolution failure.") }]];
		return;
	}

	MADCredential *credentials = nil;
	for (NSOperation *dependency in self.dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)] &&
			((id <MADOperationHoldsCredentialsProtocol>)dependency).gotCredentials) {
			credentials = ((id <MADOperationHoldsCredentialsProtocol>)dependency).credentials;
		}
	}

	// Run every non-root node once, in order, keeping each result for its parents.
	NSMutableDictionary<NSNumber *, MADDataResult *> *resultsByIdentifier = [NSMutableDictionary dictionary];
	MADComposedNodePlan *rootPlan = orderedPlans.lastObject;
	for (MADComposedNodePlan *plan in orderedPlans) {
		if (plan == rootPlan) continue;
		[_executedNodeNames addObject: plan.name ?: NSLocalizedString(@"<unnamed>", @"Unnamed query in a composition error.")];
		MADDataResult *result = nil;
		if (plan.composing) {
			NSString *identifier = NSUUID.UUID.UUIDString;
			MADDataTableFast *table = [[MADDataTableFast alloc] initWithId: identifier.hash cacheDirectory: cacheDirectory];
			table.cacheFileIdentifier = identifier;
			if (![self refreshComposingNode: plan
					   resultsByIdentifier: resultsByIdentifier
						  plansByIdentifier: plansByIdentifier
								   document: document
								  intoTable: table
							 cacheDirectory: cacheDirectory]) {
				[table closeConnections];
				[self discardIntermediateResults: resultsByIdentifier];
				return;
			}
			NSURL *columnMap = [cacheDirectory URLByAppendingPathComponent: [identifier stringByAppendingPathExtension: @"mdcache"]];
			[table cacheWithUrl: columnMap error: NULL];
			result = [[MADDataResult alloc] initWithIdentifier: identifier
													 dataTable: table
												rowDatabaseURL: table.rowDatabaseURL
												  columnMapURL: columnMap];
		} else {
			result = [self refreshLeafNode: plan credentials: credentials cacheDirectory: cacheDirectory];
		}
		if (result == nil) {
			[self discardIntermediateResults: resultsByIdentifier];
			return;
		}
		plan.result = result;
		resultsByIdentifier[@(plan.identifier)] = result;
	}

	// The root stages through the document, composes into it, then publishes.
	[_executedNodeNames addObject: rootPlan.name ?: NSLocalizedString(@"<unnamed>", @"Unnamed query in a composition error.")];
	MADDataResult *pending = [document beginRefreshResultWithError: nil];
	if (pending == nil) {
		[self finishWithError:[NSError errorWithDomain: MADOperationRefreshErrorDomain code: errNoPendingResult userInfo: @{
			NSLocalizedDescriptionKey: NSLocalizedString(@"The refresh result was not staged.", @"No staged result to fill.") }]];
		[self discardIntermediateResults: resultsByIdentifier];
		return;
	}
	if (![self refreshComposingNode: rootPlan
				resultsByIdentifier: resultsByIdentifier
				   plansByIdentifier: plansByIdentifier
							document: document
						   intoTable: pending.dataTable
					  cacheDirectory: cacheDirectory]) {
		[document discardPendingResult];
		[self discardIntermediateResults: resultsByIdentifier];
		return;
	}

	NSError *publishError = nil;
	if (![document publishPendingResultWithError: &publishError]) {
		[document discardPendingResult];
		// A failed publish keeps the previous node results; only the newly staged
		// intermediates are discarded.
		[self discardIntermediateResults: resultsByIdentifier];
		[self finishWithError: publishError ?: [NSError errorWithDomain:@"MADCache" code:errCache userInfo:nil]];
		return;
	}
	document.refreshed = YES;
	// Retain every non-root node's materialized table so a query-scoped read
	// (node-result / export?query) can reach it after this refresh.  Superseded
	// node results are released here; their files follow the root's P4 discipline.
	[document setNodeResults: resultsByIdentifier];
	[self finish];
}

/// Topologically order the reachable nodes with edges child -> parent, so the sort
/// emits every child before its parents and the root last.
- (NSArray<RptqQuery *> *)topologicalOrderOfNodes:(NSDictionary<NSNumber *, RptqQuery *> *)nodes
											error:(NSError * __autoreleasing *)error {
	MTGraph *graph = [[MTGraph alloc] init];
	for (NSNumber *key in [nodes.allKeys sortedArrayUsingSelector: @selector(compare:)]) {
		[graph addVertexWithObject: key];
	}
	for (RptqQuery *node in nodes.allValues) {
		MTVertex *parent = [graph vertexForObject: @(node.identifier)];
		for (RptqQueryTable *table in node.hasQueryTables) {
			if (table.upstreamQuery == nil) continue;
			MTVertex *child = [graph vertexForObject: @(table.upstreamQuery.identifier)];
			[graph addEdgeWithOrigin: child destination: parent object: @(table.identifier) andWeight: @1];
		}
	}

	NSError *sortError = nil;
	NSArray<MTVertex *> *sorted = [graph standardTopologicalSortWithError: &sortError];
	if (sorted == nil) {
		if (error != NULL) {
			*error = sortError ?: [NSError errorWithDomain: MADOperationRefreshErrorDomain code: errExecute userInfo: @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"The composition graph could not be ordered.", @"Composition ordering failure.") }];
		}
		return nil;
	}

	NSMutableArray<RptqQuery *> *ordered = [NSMutableArray arrayWithCapacity: sorted.count];
	for (MTVertex *vertex in sorted) {
		RptqQuery *node = nodes[vertex.object];
		if (node != nil) [ordered addObject: node];
	}
	return ordered;
}

- (nullable MADDataResult *)refreshLeafNode:(MADComposedNodePlan *)plan
								credentials:(MADCredential *)credentials
							 cacheDirectory:(NSURL *)cacheDirectory {
	MADDatabase *database = plan.database;
	MADDatabaseConnection *leafConnection = database.databaseConnection;
	NSString *connectionString = leafConnection.connectionString;
	// Each source resolves its own credential first; a caller that supplied only one
	// credential (the pre-composition path) still refreshes every source with it.
	MADCredential *leafCredentials = connectionString.length > 0
		? self.credentialsByConnectionString[connectionString]
		: nil;
	if (leafCredentials == nil) leafCredentials = credentials;
	BOOL hasCredentials = (leafCredentials.username.length > 0 || leafCredentials.password.length > 0);
	if ([leafConnection requiresCredentials] && !hasCredentials) {
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
		userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:
			NSLocalizedString(@"The source '%@' requires credentials and none were supplied.", @"Missing credentials for a source."), plan.name];
		if (plan.name.length > 0) userInfo[MADOperationRefreshSourceNameKey] = plan.name;
		if (connectionString.length > 0) userInfo[MADOperationRefreshSourceConnectionStringKey] = connectionString;
		[self finishWithError:[NSError errorWithDomain: MADOperationRefreshErrorDomain
												 code: errMissingCredentials
											 userInfo: userInfo]];
		return nil;
	}

	NSError *connectError = nil;
	id dbconn = [database connectWithConnection: leafConnection credentals: leafCredentials connectionError: &connectError];
	if (connectError != nil) {
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
		userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:
			NSLocalizedString(@"The source '%@' could not connect: %@", @"Source connection failure."),
			plan.name, connectError.localizedDescription];
		if (plan.name.length > 0) userInfo[MADOperationRefreshSourceNameKey] = plan.name;
		if (connectionString.length > 0) userInfo[MADOperationRefreshSourceConnectionStringKey] = connectionString;
		NSError *sourceError = [NSError errorWithDomain: MADOperationRefreshErrorDomain
												   code: errExecute
											   userInfo: userInfo];
		[self finishWithError: sourceError];
		return nil;
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
	// SQL Server's -executeSQL: closes the process it was given (its -runSQL: owns
	// the DBPROCESS); the other drivers leave the connection to the caller.  A
	// second dbclose here frees the TDS process out from under tds_close_socket.
	if (leafConnection.databaseType != MADDatabaseTypeTDS) {
		[database closeConnection: dbconn];
	}
	if (!success || executeError != nil) {
		[table closeConnections];
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
		userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:
			NSLocalizedString(@"The source '%@' failed: %@", @"Source query failure."),
			plan.name, (executeError.localizedDescription ?: NSLocalizedString(@"the query reported no error", @"No driver error."))];
		if (plan.name.length > 0) userInfo[MADOperationRefreshSourceNameKey] = plan.name;
		if (connectionString.length > 0) userInfo[MADOperationRefreshSourceConnectionStringKey] = connectionString;
		[self finishWithError:[NSError errorWithDomain: MADOperationRefreshErrorDomain
												 code: errExecute
											 userInfo: userInfo]];
		return nil;
	}

	NSURL *columnMap = [cacheDirectory URLByAppendingPathComponent: [identifier stringByAppendingPathExtension: @"mdcache"]];
	[table cacheWithUrl: columnMap error: NULL];
	return [[MADDataResult alloc] initWithIdentifier: identifier
										   dataTable: table
									  rowDatabaseURL: table.rowDatabaseURL
										columnMapURL: columnMap];
}

/// Compile a composing node against a scratch SQLite connection with its children
/// attached read-only, and execute it into `intoTable`.  Returns NO with the
/// operation finished when compilation, an attach, or the join fails.
- (BOOL)refreshComposingNode:(MADComposedNodePlan *)plan
		 resultsByIdentifier:(NSDictionary<NSNumber *, MADDataResult *> *)results
			plansByIdentifier:(NSDictionary<NSNumber *, MADComposedNodePlan *> *)plans
					 document:(id <MADDocumentDataProtocol>)document
					intoTable:(MADDataTableFast *)intoTable
			   cacheDirectory:(NSURL *)cacheDirectory {
	NSMutableArray<MADComposingChild *> *children = [NSMutableArray arrayWithCapacity: plan.childIdentifiers.count];
	for (NSUInteger i = 0; i < plan.childIdentifiers.count; i++) {
		NSNumber *childKey = plan.childIdentifiers[i];
		MADComposedNodePlan *childPlan = plans[childKey];
		MADComposingChild *child = [[MADComposingChild alloc] init];
		child.queryIdentifier = childPlan.identifier;
		child.attachAlias = [NSString stringWithFormat: @"att%lu", (unsigned long)i];
		child.query = childPlan.query;
		child.database = childPlan.database;
		child.result = results[childKey];
		[children addObject: child];
	}
	MADComposingResolver *resolver = [[MADComposingResolver alloc] initWithChildren: children];

	NSString *scratchIdentifier = NSUUID.UUID.UUIDString;
	NSURL *scratchURL = [cacheDirectory URLByAppendingPathComponent: [scratchIdentifier stringByAppendingString: @"-composer.maddb"]];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: scratchURL];
	MADDatabaseSqlite3 *composer = [[MADDatabaseSqlite3 alloc] init];
	composer.databaseConnection = connection;
	[composer openDatabaseWithFlags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_URI];

	// The compile is a store read, so it runs on main; the scratch connection only
	// supplies the SQLite dialect here, never its handle.
	__block NSString *sql = nil;
	__block NSArray<NSString *> *fieldKeys = nil;
	__block NSError *compileError = nil;
	MADOperationRefreshRunOnMain(^{
		MADQueryFull *compiler = [[MADQueryFull alloc] initWithQuery: plan.query andQueryLimit: NSUIntegerMax];
		compiler.database = composer;
		compiler.composingResolver = resolver;
		sql = [compiler copySQLWithManagedObjectContext: document.storeContext error: &compileError];
		fieldKeys = compiler.fieldKeys;
	});

	NSError *error = compileError;
	if (sql.length == 0) {
		[composer closeDatabaseConnectionIfOpen];
		[[NSFileManager defaultManager] removeItemAtURL: scratchURL error: NULL];
		[self finishWithError: error ?: [NSError errorWithDomain: MADOperationRefreshErrorDomain code: errExecute userInfo: @{
			NSLocalizedDescriptionKey: NSLocalizedString(@"The composed query could not be compiled.", @"Composition compilation failure.") }]];
		return NO;
	}

	for (MADComposingChild *child in children) {
		if (![composer attachReadOnlyDatabaseAtURL: child.result.rowDatabaseURL asName: child.attachAlias error: &error]) {
			[composer closeDatabaseConnectionIfOpen];
			[[NSFileManager defaultManager] removeItemAtURL: scratchURL error: NULL];
			[self finishWithError: error];
			return NO;
		}
	}

	NSError *executeError = nil;
	BOOL success = [composer executeSQL: sql
							 fieldKeys: fieldKeys
						  onConnection: nil
					   intoResultTable: (MADDataTable *)intoTable
						transactionSet: NO
						returnsResults: YES
						binaryBindings: nil
							 withError: &executeError];

	[composer closeDatabaseConnectionIfOpen];
	[[NSFileManager defaultManager] removeItemAtURL: scratchURL error: NULL];

	if (!success) {
		[self finishWithError: executeError ?: [NSError errorWithDomain: MADOperationRefreshErrorDomain code: errExecute userInfo: @{
			NSLocalizedDescriptionKey: NSLocalizedString(@"The composition join failed.", @"Composition join failure.") }]];
		return NO;
	}
	return YES;
}

- (void)discardIntermediateResults:(NSDictionary<NSNumber *, MADDataResult *> *)results {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	for (MADDataResult *result in results.allValues) {
		MADDataTableFast *table = result.dataTable;
		NSUInteger tag = table.tag;
		NSURL *rowURL = result.rowDatabaseURL;
		NSURL *columnMapURL = result.columnMapURL;
		[table closeConnections];
		[fileManager removeItemAtURL: rowURL error: NULL];
		[fileManager removeItemAtURL: columnMapURL error: NULL];
		NSURL *tagURL = [[rowURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:
			[[NSString stringWithFormat: @"%lu", (unsigned long)tag] stringByAppendingPathExtension: @"maddb"]];
		[fileManager removeItemAtURL: tagURL error: NULL];
	}
}

@end
