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

static const short errCache = 2;

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
			NSError *error = [NSError errorWithDomain: @"MADCache" code: errCache + 1 userInfo: nil];
			[self finishWithError:error];
			return;
		}
	}
	
	NSError * __autoreleasing eerror = NULL;
	MADDatabaseConnection *connectionSettings = (document.database).databaseConnection;
	id dbconn = [document.database connectWithConnection: connectionSettings
											  credentals: credientals
										 connectionError: &eerror];
	
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
		NSError *error = eerror;
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
