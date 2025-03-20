//
//  MADOperationRefresh.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationRefresh.h"

#import <os/log.h>
#import <CoreData/NSManagedObjectContext.h>
#import <Foundation/Foundation.h>
#import <MADFoundation/MADCredential.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADQuery.h>

#import <MAD/MADocument.h>
#import <MAD/MADConstants.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADQueryFull.h>

#import "MADOperationRefreshInitialize.h"

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
            NSError * __autoreleasing error = [NSError errorWithDomain: @"MADCache"
                                                                  code: errCache + 1
                                                              userInfo: nil];
            [self finishWithError:error];
            return;
        }
    }
    
    NSError * __autoreleasing eerror = NULL;
    MADDatabaseConnection *connectionSettings = (document.database).databaseConnection;
    id dbconn = [document.database connectWithConnection: connectionSettings
                                              credentals: credientals
                                         connectionError: &eerror];
    
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
    private.parentContext = document.managedObjectContext;

    __block NSString *queryString = nil;
    MADQueryFull *query = document.mainQuery;
    [private performBlockAndWait:^{
        NSError *sqlError = NULL;
        queryString = [query copySQLWithManagedObjectContext: private
                                                       error: &sqlError];
    }];
    [document dataTableSetDataDelegate:document];
    NSError *executeError = NULL;

	BOOL success = [document.database executeSQL: queryString
									   fieldKeys: query.fieldKeys
									onConnection: dbconn
								 intoResultTable: (MADDataTable *)document.dataTable
									   withError: &executeError];
	
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
