//
//  MADOperationRefreshInitialize.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationRefreshInitialize.h"

#import <os/log.h>

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

#import <MAD/MADDataTable.h>
#import <MAD/MADDataTableFast.h>
#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MADReportFormatter.h>
#import <MAD/MADSectionLayoutManager.h>
#import <MAD/MADDatabaseConnection.h>
#import <MAD/MTQueryFull.h>
#import <MAD/MTDatabase+Constructor.h>

#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabase+extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSectionEnumerator.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>

#import "MADOperationRefreshInitalizeMainDataTable.h"

@interface MADOperationRefreshInitialize ()

    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, assign) BOOL success;

@end

@implementation MADOperationRefreshInitialize

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithDocument:(MADocument *)document {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    if (self = [super init]) {
        _document = document;
        _success = NO;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    
    if (self.cancelled) {
        return [self finish];
    }

    MADocument *doc = _document;
    /*
        for (NSOperation *dependency in self.dependencies) {
            if ([dependency conformsToProtocol:@protocol(MADOperationRefreshInitializeMainDataTableProtocol)]) {
                doc = ((id <MADOperationRefreshInitializeMainDataTableProtocol>)dependency).document;
                break;
            }
        }
    */
   
    //NSManagedObjectContext *private;
    //private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    //private.parentContext = doc.managedObjectContext;

    //MADocument * __weak wdocument = doc;
    //[private performBlockAndWait:^{
        //MADocument *document = wdocument;

        RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: doc.managedObjectContext];
        if (rptqDocument == nil) {
            rptqDocument = [RptqDocument newDocumentForManagedObjectContext: doc.managedObjectContext];
        }
        
        RptqDatabase *rptqDatabase;;
        RptqQuery *rptqQuery;
        
        //Initialize main database
        if (doc.database == nil) {
            RptqDatabaseCredentals *rptqUser;
            MADDatabaseConnection *databaseConnection;
            MTDatabase *database;
            rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
            rptqQuery = rptqDatabase.hasQueries.anyObject;
            rptqUser = rptqQuery.inDatabase.ownedByUser;
            databaseConnection = [MADDatabaseConnection newDatabaseConnectionWithCredentals:rptqUser];
            [doc updateDatabaseWithConnection:databaseConnection];
            database = [MTDatabase newDatabaseWithConnection:databaseConnection];
        }
        doc.database.delegate = (id <MADDatabaseResultsProtocol>)doc;
        
        if (rptqDatabase == nil || rptqQuery == nil) {
            rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
            rptqQuery = rptqDatabase.hasQueries.anyObject;
        }
        
        NSArray *sortDescriptors = [rptqQuery sortDescriptorsForDatabase:doc.database];
        [doc.dataTable sortUsingDescriptors:sortDescriptors];
        
        //Initialize the section layout manager... Not neede for creating the report.
        [doc resetSectionLayoutManagers];

        MADReportFormatter *formatter;
        formatter = [MADReportFormatter newReportFormatterWithLayout: doc
                                                             options: MADReportFormatterOptionsNone];

        doc.reportFormatter = formatter;
        
    //}];
    [self finish];
    
}

@end
