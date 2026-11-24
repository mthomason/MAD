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

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADDataColumn.h>

#import <MADSqlite3/MADDataTableFast.h>

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADConstants.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADQueryFull.h>


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
