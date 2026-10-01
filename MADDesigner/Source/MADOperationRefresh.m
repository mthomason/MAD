//
//  MADOperationRefresh.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationRefresh.h"
#import "MADOperationRefreshInitialize.h"
#import "madlog.h"

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADQuery.h>

#import <MADFoundation/MADCredential.h>

#import <MAD/MADocument.h>
#import <MAD/MADConstants.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADQueryFull.h>

#import <CoreData/NSManagedObjectContext.h>

// The operation's own domain.  It used to borrow @"MADCache" for a missing
// credential, which reads as a fault in the result cache rather than in the
// credentials the caller never supplied.
static NSString * const MADOperationRefreshErrorDomain = @"com.everydayapps.operation.refresh";

static const short errCache = 2;
static const short errMissingCredentials = 3;
static const short errExecute = 4;
static const short errNoDocument = 3842;

@interface MADOperationRefresh ()
@property (nonatomic, weak) MADocument *document;
@end

@implementation MADOperationRefresh

- (instancetype)initWithDocument:(MADocument *)document {
	if (self = [super init]) {
		_document = document;
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	if (self.cancelled) {
		return [self finish];
	}
	
	MADocument *document = self.document;
	if (!document) {
		NSError *docNullError = [[NSError alloc] initWithDomain: MADOperationRefreshErrorDomain
														   code: errNoDocument
													   userInfo: nil];
		[self finishWithError:docNullError];
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
			// result cache.  See BUGS.md.
			NSError *error = [NSError errorWithDomain: MADOperationRefreshErrorDomain
												 code: errMissingCredentials
											 userInfo: @{
				NSLocalizedDescriptionKey : NSLocalizedString(@"Credentials required", @"Credentials required"),
				NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"The database requires credentials and none were supplied.", @"The database requires credentials and none were supplied.")
			}];
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
		[self finishWithError:error];
		return;
	}

	NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
	private.parentContext = document.managedObjectContext;
	
	__block NSString *queryString = nil;
	MADQueryFull *query = document.mainQuery;
	[private performBlockAndWait:^{
		NSError *sqlError = nil;
		queryString = [query copySQLWithManagedObjectContext: private error: &sqlError];
		if (sqlError != nil) {
			os_log_error(OS_LOG_DEFAULT, "Error: %@", sqlError);
		}
	}];
	[document dataTableSetDataDelegate:document];

	NSError *executeError = nil;
	BOOL success = [document.database executeSQL: queryString
									   fieldKeys: query.fieldKeys
									onConnection: dbconn
								 intoResultTable: (MADDataTable *)document.dataTable
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
		// what the caller saw.  executeError is what the driver reported.  See BUGS.md.
		NSError *error = executeError;
		if (error == nil) {
			error = [NSError errorWithDomain: MADOperationRefreshErrorDomain
										code: errExecute
									userInfo: @{
				NSLocalizedDescriptionKey : NSLocalizedString(@"The query failed", @"The query failed"),
				NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"The database driver reported no error.", @"The database driver reported no error.")
			}];
		}
		[self finishWithError:error];
		return;
	}
	success = [document dataTableMakeCache];
	document.refreshed = YES;
	if (!success) {
		NSError *error = [NSError errorWithDomain:@"MADCache" code:errCache userInfo:nil];
		[self finishWithError:error];
		return;
	}

	[self finish];
}

@end
