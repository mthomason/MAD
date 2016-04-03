//
//  MADRefreshOperationInitalize.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADRefreshOperationInitalize.h"
#import <Foundation/Foundation.h>
#import <MADFoundation/MTDataTable.h>
#import <MAD/MTDataTableFast.h>
#import <CoreData/NSManagedObjectContext.h>
#import <MAD/MADocument.h>
#import <MAD/MTDatabaseConnection.h>
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
    @property (nonatomic, assign) bool success;

@end

@implementation MADRefreshOperationInitalize

- (instancetype)initWithDocument:(MADocument *)document {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _document = document;
        _success = false;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    MADocument *doc;

        for (NSOperation *dependency in self.dependencies) {
            if ([dependency conformsToProtocol:@protocol(MADRefreshOperationInitalizeMainDataTableProtocol)]) {
                doc = ((id <MADRefreshOperationInitalizeMainDataTableProtocol>)dependency).document;
                break;
            }
        }
   
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = doc.managedObjectContext;

    MADocument * __weak wdocument = doc;
    [private performBlockAndWait:^{
        MADocument *document = wdocument;

        RptqDocument *rptqDocument = [RptqDocument documentForManagedObjectContext: private];
        if (rptqDocument == nil) {
            rptqDocument = [RptqDocument newDocumentForManagedObjectContext: private];
        }
        document.documentObjectID = rptqDocument.objectID;
        
        MTPaper *paper = [[MTPaper alloc] initWithType: rptqDocument.paperType];
        document.paper = paper;
        
        //Initalize main database
        if (document.mainDatabase == nil) {
            RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
            RptqQuery *query = rptqDatabase.hasQueries.anyObject;
            MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForObject:query.inDatabase.ownedByUser];
            MTDatabase *db = [MTDatabase newDatabaseWithConnection:databaseConnection];
            document.mainDatabase = db;
        }
        
        if (document.reportFormatter == nil) {
            RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
            RptqQuery *rquery = rptqDatabase.hasQueries.anyObject;
            MTQueryFull *madQuery = [[MTQueryFull alloc] initWithQueryObjectId:rquery.objectID andQueryLimit:NSNotFound];
            madQuery.dataDelegate = document;
            document.mainQuery = madQuery;
            
            NSArray *sortDescriptors = [rquery sortDescriptorsForDatabase:document.mainDatabase];
            [document.mainDataTable sortUsingDescriptors:sortDescriptors];
            
            //Initalize the section layout manager... Not neede for creating the report.
            NSMutableDictionary *sectionLayoutManagers = [NSMutableDictionary new];
            RptqDocumentSectionEnumerator *sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:rptqDocument];
            for (RptqDocumentSection *reportSection in sectionEnumerator) {
                
                MADSectionLayoutManager *layoutManager = [[MADSectionLayoutManager alloc] initWithDocumentSection:reportSection];
                layoutManager.delegate = document;
                [sectionLayoutManagers setObject:layoutManager forKey:reportSection.objectID];
                
            }
            document.sectionLayoutManagers = sectionLayoutManagers;
            
            
            MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterWithQuery: document.mainQuery
                                                                                      layout: document
                                                                                     options: MTReportFormatterOptionsNone];
            reportFormatter.dataDelegate = document;
            reportFormatter.cachedDelegate = document;
            reportFormatter.datasource = document;
            
            document.reportFormatter = reportFormatter;
        }
        [self finish];
    }];
    
}

@end
