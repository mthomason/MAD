//
//  MADOperationRefresh.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationRefresh.h"

#import <CoreData/NSManagedObjectContext.h>

#import <Foundation/NSError.h>
#import <Foundation/NSURL.h>

#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MADDataTableFast.h>
#import <MAD/MTQuery.h>
#import <MAD/MADDatabaseConnection.h>
#import <MAD/MADConstants.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADCredential.h>
#import <MAD/MTQueryFull.h>

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
    MADocument *document = self.document;
    MADCredential *credientals = nil;
    if (document.database.delegate == nil) {
        document.database.delegate = (id <MADDatabaseProtocol>)document;
    }
    
    if ([document.database.databaseConnection requiresCredientals]) {

        for (NSOperation *dependency in self.dependencies) {
            if ([dependency conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)] &&
                ((id <MADOperationHoldsCredentialsProtocol>)dependency).gotCredentials) {
                credientals = ((id <MADOperationHoldsCredentialsProtocol>)dependency).credentials;
            }
        }
        
        if (credientals == nil) {
            NSError *error = [NSError errorWithDomain: @"MADCache"
                                                 code: errCache + 1
                                             userInfo: nil];
            [self finishWithError:error];
            return;
        }
    }
    
    NSError * __autoreleasing eerror = NULL;
    MADDatabaseConnection *connectionSettings = (document.database).databaseConnection;
    id dbconn = [document.database connectWithConnection: connectionSettings
                                              credentals: credientals];
    
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
    private.parentContext = document.managedObjectContext;

    __block NSString *queryString = nil;
    MTQueryFull *query = document.mainQuery;
    [private performBlockAndWait:^{
        NSError *sqlError = NULL;
        queryString = [query copySQLWithManagedObjectContext: private
                                                       error: &sqlError];
    }];
    
    document.dataTable.dataDelegate = document;
    NSError *executeError = NULL;
    BOOL success = [document.database executeSql: queryString
                                       fieldKeys: query.fieldKeys
                                    onConnection: dbconn
                                 intoResultTable: (MADDataTable *)document.dataTable
                                       withError: &executeError];

    if (!success) {
        NSError *error = eerror;
        [self finishWithError:error];
        return;
    }

    success = [document.dataTable cacheWithUrl:document.urlDataTableCache];
    
    if (!success) {
        NSError *error = [NSError errorWithDomain:@"MADCache" code:errCache userInfo:nil];
        [self finishWithError:error];
        return;
    }

    [self finish];
}

@end
