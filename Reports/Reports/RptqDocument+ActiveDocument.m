//
//  RptqDocument+ActiveDocument.m
//  Reports
//
//  Created by Michael Thomason on 1/22/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocument+ActiveDocument.h"
#import "MTActiveDocument.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"


@implementation RptqDocument (ActiveDocument)

+ (RptqDocument *)activeDocument {
    id ad = [[MTActiveDocument sharedDocument] activeDocument];
    return [ad activeDocument];
}

+ (void)saveCurrentContext {
    NSError *error;
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            [error presentErrorToUserWithContinue:^(BOOL success) {
                MAReportDocument *activeDocument = [[MTActiveDocument sharedDocument] activeDocument];
                NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
                NSError *error = nil;
                [managedObjectContext save:&error];
            }];
        }
    }
}

+ (RptqQuery *)queryForActiveDocument {
    RptqDocument *document = [RptqDocument activeDocument];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    return query;
}

+ (RptqQuery *)queryForDocument:(RptqDocument *)document {
    NSSet *hasDatabaseSchemas = [document hasDatabaseSchemas];
    RptqDatabase *database = [hasDatabaseSchemas anyObject];
    NSSet *hasQueries = [database hasQueries];
    RptqQuery *query = [hasQueries anyObject];
    return query;
}

+ (NSArray *)tablesForActiveDocument {
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    NSArray *results = [[RptqDatabaseSchemaTable tablesForManagedObjectContext:managedObjectContext] retain];
    return [results autorelease];
}

+ (NSArray *)queryTablesForActiveDocument {
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    NSArray *results = [[RptqQueryTable queryTablesForManagedObjectContext:managedObjectContext] retain];
    return [results autorelease];
}

+ (NSArray *)queryLinksForActiveDocument {
    MAReportDocument *activeDocument = [[MTActiveDocument sharedDocument] activeDocument];
    RptqDocument *document = [activeDocument activeDocument];
    NSArray *results = [[RptqQueryLinks queriesForDocument:document] retain];
    return [results autorelease];
}

@end
