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
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    return document;
}

+ (void)saveCurrentContext {
    NSError *error;
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            [error presentErrorToUserWithContinue:^(BOOL success) {
                NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
                NSError *error = nil;
                [managedObjectContext save:&error];
            }];
        }
    }
}

+ (NSString *)sqlStatementForActiveDocument {
    RptqQuery *query = [RptqDocument queryForActiveDocument];
    return [[[RptqQuery getSqlForQuery:query] retain] autorelease];
}

+ (RptqQuery *)queryForActiveDocument {
    RptqDocument *document = [RptqDocument activeDocument];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    return query;
}

+ (RptqQuery *)queryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    return query;
}

+ (NSArray *)tablesForActiveDocument {
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    return [[[RptqDatabaseSchemaTable tablesForManagedObjectContext:managedObjectContext] retain] autorelease];
}

+ (NSArray *)queryTablesForActiveDocument {
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    return [[[RptqQueryTable queryTablesForManagedObjectContext:managedObjectContext] retain] autorelease];
}

+ (NSArray *)queryLinksForActiveDocument {
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    return [[[RptqQueryLinks queriesForManagedObjectContext:managedObjectContext] retain] autorelease];
}

@end
