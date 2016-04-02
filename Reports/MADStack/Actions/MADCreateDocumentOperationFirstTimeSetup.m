//
//  MADCreateDocumentOperationFirstTimeSetup.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/31/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCreateDocumentOperationFirstTimeSetup.h"
#import <Foundation/Foundation.h>
#import <CoreData/NSManagedObjectContext.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTDataTableFast.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabase+extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSectionEnumerator.h>
#import <MAD/MADSectionLayoutManager.h>
#import "MADCreateDocumentOperationCreateDocument.h"

@interface MADCreateDocumentOperationFirstTimeSetup ()

    @property (nonatomic, assign) bool success;
    @property (nonatomic, strong) MTDatabaseConnection *databaseConnection;

@end

@implementation MADCreateDocumentOperationFirstTimeSetup

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (instancetype)init {
    return [self initWithDatabaseConnection:nil];
}

- (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)databaseConnection {
    if (self = [super init]) {
        self.databaseConnection = databaseConnection;
        self.success = false;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    MADocument * document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADCreateDocumentOperationCreateDocumentProtocol)]) {
            document = ((id <MADCreateDocumentOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
    }
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    private.parentContext = document.managedObjectContext;
    MADocument * __weak wdoc = document;
    [private performBlockAndWait:^{
        MADocument *doc = wdoc;
        RptqDocument *rptqDocument = [RptqDocument newDocumentForManagedObjectContext: private];
        doc.documentObjectID = rptqDocument.objectID;

        NSError *error = nil;
        if (![private save:&error]) NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);

        /*
        MTPaper *paper = [[MTPaper alloc] initWithType: rptqDocument.paperType];
        document.paper = paper;
        */
        
        /* Not needed for creating the report...
        //Initalize main database
        RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
        RptqQuery *query = rptqDatabase.hasQueries.anyObject;
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForObject:query.inDatabase.ownedByUser];
        MTDatabase *db = [MTDatabase newDatabaseWithConnection:databaseConnection];
        document.mainDatabase = db;
        */
        
        /* Not needed for creating the report...
        MTQueryFull *madQuery = [[MTQueryFull alloc] initWithQueryObjectId:query.objectID andQueryLimit:NSNotFound];
        madQuery.dataDelegate = document;
        document.mainQuery = madQuery;
        */
        
        /* Not needed for creating the report...
        NSArray *sortDescriptors = [query sortDescriptorsForDatabase:document.mainDatabase];
        [document.mainDataTable sortUsingDescriptors:sortDescriptors];
        */
        
        //Initalize the section layout manager... Not neede for creating the report.
        /*
        NSMutableDictionary *sectionLayoutManagers = [NSMutableDictionary new];
        RptqDocumentSectionEnumerator *sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:rptqDocument];
        for (RptqDocumentSection *reportSection in sectionEnumerator) {
            
            MADSectionLayoutManager *layoutManager = [[MADSectionLayoutManager alloc] initWithDocumentSection:reportSection];
            layoutManager.delegate = document;
            [sectionLayoutManagers setObject:layoutManager forKey:reportSection.objectID];
            
        }
        document.sectionLayoutManagers = sectionLayoutManagers;
        */
        
        //Initalize the report formatter... Not needed for creating the report.
        /*
        MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterWithQuery: document.mainQuery
                                                                                  layout: document
                                                                                 options: MTReportFormatterOptionsNone];
        reportFormatter.dataDelegate = document;
        reportFormatter.cachedDelegate = document;
        reportFormatter.datasource = document;
        
        document.reportFormatter = reportFormatter;
        */
    }];

    //[document activeDocumentModel];
    [self finish];
}


@end
