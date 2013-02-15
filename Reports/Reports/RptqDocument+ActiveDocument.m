//
//  RptqDocument+ActiveDocument.m
//  Reports
//
//  Created by Michael Thomason on 1/22/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocument+ActiveDocument.h"

@implementation RptqDocument (ActiveDocument)

+ (RptqDocument *)activeDocument {
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    return document;
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

+ (NSArray *)tablesForActiveDocument {
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    return [[[RptqTable tablesForManagedObjectContext:managedObjectContext] retain] autorelease];
}

@end
