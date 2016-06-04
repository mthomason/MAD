//
//  MADRefreshOperationInitalize.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADRefreshOperationInitalize.h"
#import <MADFoundation/MTDataTable.h>
#import <MAD/MTDataTableFast.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>

#import <MAD/MTReportFormatter.h>
#import <MAD/MADSectionLayoutManager.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MTQueryFull.h>

#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabase+extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSectionEnumerator.h>

#import "MADRefreshOperationInitalizeMainDataTable.h"

@interface MADRefreshOperationInitalize ()

    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, assign) BOOL success;

@end

@implementation MADRefreshOperationInitalize

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithDocument:(MADocument *)document {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    if (self = [super init]) {
        _document = document;
        _success = NO;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    MADocument *doc = _document;
    /*
        for (NSOperation *dependency in self.dependencies) {
            if ([dependency conformsToProtocol:@protocol(MADRefreshOperationInitalizeMainDataTableProtocol)]) {
                doc = ((id <MADRefreshOperationInitalizeMainDataTableProtocol>)dependency).document;
                break;
            }
        }
    */
   
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = doc.managedObjectContext;

    MADocument * __weak wdocument = doc;
    [private performBlockAndWait:^{
        MADocument *document = wdocument;

        RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        if (rptqDocument == nil) {
            rptqDocument = [RptqDocument newDocumentForManagedObjectContext: private];
        }
        
        document.documentObjectID = rptqDocument.objectID.copy;
        
        MTPaper *paper = [[MTPaper alloc] initWithType: rptqDocument.paperType];
        document.paper = paper;
        
        RptqDatabase *rptqDatabase;;
        RptqQuery *rptqQuery;
        
        //Initalize main database
        if (document.database == nil) {
            RptqUserCredentals *rptqUser;
            MTDatabaseConnection *databaseConnection;
            MTDatabase *database;
            rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
            rptqQuery = rptqDatabase.hasQueries.anyObject;
            rptqUser = rptqQuery.inDatabase.ownedByUser;
            databaseConnection = [MTDatabaseConnection newDatabaseConnectionForObject:rptqUser];
            database = [MTDatabase newDatabaseWithConnection:databaseConnection];
            document.database = database;
            
        }
        
        if (rptqDatabase == nil || rptqQuery == nil) {
            rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
            rptqQuery = rptqDatabase.hasQueries.anyObject;
        }
        
        MTQueryFull *madQuery = [[MTQueryFull alloc] initWithQueryObjectId: rptqQuery.objectID
                                                             andQueryLimit: NSNotFound];
        madQuery.dataDelegate = document;
        document.mainQuery = madQuery;
        
        NSArray *sortDescriptors = [rptqQuery sortDescriptorsForDatabase:document.database];
        [document.mainDataTable sortUsingDescriptors:sortDescriptors];
        
        //Initalize the section layout manager... Not neede for creating the report.
        
        NSMutableDictionary *sectionLayoutManagers;
        RptqDocumentSectionEnumerator *sectionEnumerator;
        MADSectionLayoutManager *layoutManager;
        RptqDocumentSection *reportSection;
        
        sectionLayoutManagers = [[NSMutableDictionary alloc] init];
        sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:rptqDocument];
        for (reportSection in sectionEnumerator) {
            layoutManager = [[MADSectionLayoutManager alloc] initWithDocumentSection:reportSection];
            sectionLayoutManagers[reportSection.objectID] = layoutManager;
        }
        
        document.sectionLayoutManagers = sectionLayoutManagers;

        MTReportFormatter *formatter;
        formatter = [MTReportFormatter newReportFormatterWithLayout: document
                                                            options: MTReportFormatterOptionsNone];
        formatter.dataDelegate = document;
        formatter.datasource = document;
        formatter.cachedDelegate = document;
        [formatter initialize];

        document.reportFormatter = formatter;
        
    }];
    [self finish];
    
}

@end
